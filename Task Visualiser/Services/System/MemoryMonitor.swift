import Foundation
import Darwin

final class MemoryMonitor: Sendable {

    nonisolated func snapshot() -> MemoryUsage {
        var stats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride
        )

        let hostPort = mach_host_self()
        let result = withUnsafeMutablePointer(to: &stats) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(hostPort, HOST_VM_INFO64, intPtr, &count)
            }
        }

        guard result == KERN_SUCCESS else { return .zero }

        let pageSize = UInt64(vm_page_size)
        let free = UInt64(stats.free_count) * pageSize
        let active = UInt64(stats.active_count) * pageSize
        let inactive = UInt64(stats.inactive_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize
        let totalPhysical = Self.physicalMemory()

        return MemoryUsage(
            free: free,
            active: active,
            inactive: inactive,
            wired: wired,
            compressed: compressed,
            totalPhysical: totalPhysical,
            timestamp: .now
        )
    }

    private static func physicalMemory() -> UInt64 {
        var size: size_t = MemoryLayout<UInt64>.size
        var result: UInt64 = 0
        sysctlbyname("hw.memsize", &result, &size, nil, 0)
        return result
    }
}
