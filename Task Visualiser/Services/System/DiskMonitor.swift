import Foundation
import IOKit

final class DiskMonitor: Sendable {

    private let lock = NSLock()
    private let prevRead = UnsafeMutablePointer<UInt64>.allocate(capacity: 1)
    private let prevWrite = UnsafeMutablePointer<UInt64>.allocate(capacity: 1)
    private let prevTimestamp = UnsafeMutablePointer<Date?>.allocate(capacity: 1)

    init() {
        prevRead.initialize(to: 0)
        prevWrite.initialize(to: 0)
        prevTimestamp.initialize(to: nil)
    }

    deinit {
        prevRead.deinitialize(count: 1)
        prevRead.deallocate()
        prevWrite.deinitialize(count: 1)
        prevWrite.deallocate()
        prevTimestamp.deinitialize(count: 1)
        prevTimestamp.deallocate()
    }

    nonisolated func snapshot() -> DiskUsage {
        let (totalRead, totalWritten) = readDiskCounters()

        lock.lock()
        let pRead = prevRead.pointee
        let pWrite = prevWrite.pointee
        let pTime = prevTimestamp.pointee
        prevRead.pointee = totalRead
        prevWrite.pointee = totalWritten
        let now = Date.now
        prevTimestamp.pointee = now
        lock.unlock()

        var readPerSec: Double = 0
        var writePerSec: Double = 0

        if let pTime {
            let elapsed = now.timeIntervalSince(pTime)
            if elapsed > 0 && pRead > 0 {
                readPerSec = Double(totalRead &- pRead) / elapsed
                writePerSec = Double(totalWritten &- pWrite) / elapsed
            }
        }

        return DiskUsage(
            bytesRead: totalRead,
            bytesWritten: totalWritten,
            readPerSecond: max(readPerSec, 0),
            writePerSecond: max(writePerSec, 0),
            timestamp: now
        )
    }

    private func readDiskCounters() -> (bytesRead: UInt64, bytesWritten: UInt64) {
        guard let matching = IOServiceMatching("IOBlockStorageDriver") else {
            return (0, 0)
        }

        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return (0, 0)
        }
        defer { IOObjectRelease(iterator) }

        var totalRead: UInt64 = 0
        var totalWritten: UInt64 = 0

        var entry = IOIteratorNext(iterator)
        while entry != 0 {
            defer {
                IOObjectRelease(entry)
                entry = IOIteratorNext(iterator)
            }

            guard let props = IORegistryEntryCreateCFProperty(
                entry,
                "Statistics" as CFString,
                kCFAllocatorDefault,
                0
            )?.takeRetainedValue() as? [String: Any] else {
                continue
            }

            if let read = props["Bytes (Read)"] as? UInt64 {
                totalRead += read
            }
            if let written = props["Bytes (Write)"] as? UInt64 {
                totalWritten += written
            }
        }

        return (totalRead, totalWritten)
    }
}
