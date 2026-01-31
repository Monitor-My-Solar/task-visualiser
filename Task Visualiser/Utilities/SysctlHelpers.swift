import Foundation
import Darwin

enum SysctlHelpers {

    static func string(for key: String) -> String? {
        var size: size_t = 0
        guard sysctlbyname(key, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(key, &buffer, &size, nil, 0) == 0 else { return nil }
        return String(cString: buffer)
    }

    static func int64(for key: String) -> Int64? {
        var value: Int64 = 0
        var size = MemoryLayout<Int64>.size
        guard sysctlbyname(key, &value, &size, nil, 0) == 0 else { return nil }
        return value
    }

    static func int32(for key: String) -> Int32? {
        var value: Int32 = 0
        var size = MemoryLayout<Int32>.size
        guard sysctlbyname(key, &value, &size, nil, 0) == 0 else { return nil }
        return value
    }

    static func hostname() -> String {
        string(for: "kern.hostname") ?? "Unknown"
    }

    static func osVersion() -> String {
        let version = string(for: "kern.osproductversion") ?? "Unknown"
        return "macOS \(version)"
    }

    static func cpuBrand() -> String {
        string(for: "machdep.cpu.brand_string") ?? "Unknown CPU"
    }

    static func physicalCores() -> Int {
        Int(int32(for: "hw.physicalcpu") ?? 0)
    }

    static func logicalCores() -> Int {
        Int(int32(for: "hw.logicalcpu") ?? 0)
    }

    static func uptime() -> TimeInterval {
        var bootTime = timeval()
        var size = MemoryLayout<timeval>.size
        var mib: [Int32] = [CTL_KERN, KERN_BOOTTIME]
        guard sysctl(&mib, 2, &bootTime, &size, nil, 0) == 0 else { return 0 }
        return Date().timeIntervalSince1970 - Double(bootTime.tv_sec)
    }

    static func formattedUptime() -> String {
        let total = Int(uptime())
        let days = total / 86400
        let hours = (total % 86400) / 3600
        let minutes = (total % 3600) / 60

        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
