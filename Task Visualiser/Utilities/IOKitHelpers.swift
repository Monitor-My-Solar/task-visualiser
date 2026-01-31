import Foundation
import IOKit

enum IOKitHelpers {

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
