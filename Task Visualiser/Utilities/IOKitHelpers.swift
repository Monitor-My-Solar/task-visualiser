import Foundation
import IOKit

enum IOKitHelpers {

    struct RawGPUData {
        var name: String
        var utilization: Double
        var vramUsed: UInt64?
        var vramTotal: UInt64?
    }

    static func readGPUPerformanceStatistics() -> [RawGPUData] {
        guard let matching = IOServiceMatching("IOAccelerator") else {
            return []
        }

        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return []
        }
        defer { IOObjectRelease(iterator) }

        var results: [RawGPUData] = []

        var entry = IOIteratorNext(iterator)
        while entry != 0 {
            defer {
                IOObjectRelease(entry)
                entry = IOIteratorNext(iterator)
            }

            // Get device name
            var nameBuffer = [CChar](repeating: 0, count: 128)
            let nameResult = IORegistryEntryGetName(entry, &nameBuffer)
            let name = nameResult == KERN_SUCCESS ? String(cString: nameBuffer) : "GPU"

            guard let props = IORegistryEntryCreateCFProperty(
                entry,
                "PerformanceStatistics" as CFString,
                kCFAllocatorDefault,
                0
            )?.takeRetainedValue() as? [String: Any] else {
                continue
            }

            // Utilization: try Apple Silicon key, then AMD key
            let utilization: Double
            if let val = props["Device Utilization %"] as? NSNumber {
                utilization = val.doubleValue
            } else if let val = props["GPU Activity(%)"] as? NSNumber {
                utilization = val.doubleValue
            } else {
                utilization = 0
            }

            // VRAM: try multiple known keys
            let vramUsed: UInt64?
            if let val = props["vramUsedBytes"] as? NSNumber {
                vramUsed = val.uint64Value
            } else if let val = props["In use system memory"] as? NSNumber {
                vramUsed = val.uint64Value
            } else if let val = props["Alloc system memory"] as? NSNumber {
                vramUsed = val.uint64Value
            } else {
                vramUsed = nil
            }

            results.append(RawGPUData(
                name: name,
                utilization: min(max(utilization, 0), 100),
                vramUsed: vramUsed,
                vramTotal: nil
            ))
        }

        return results
    }

    static func readDiskStatistics() -> (bytesRead: UInt64, bytesWritten: UInt64) {
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
