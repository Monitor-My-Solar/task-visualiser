import Foundation

struct MemoryUsage: Sendable {
    var free: UInt64
    var active: UInt64
    var inactive: UInt64
    var wired: UInt64
    var compressed: UInt64
    var totalPhysical: UInt64
    var timestamp: Date

    var used: UInt64 {
        active + wired + compressed
    }

    var usagePercentage: Double {
        guard totalPhysical > 0 else { return 0 }
        return Double(used) / Double(totalPhysical) * 100
    }

    static let zero = MemoryUsage(
        free: 0, active: 0, inactive: 0, wired: 0,
        compressed: 0, totalPhysical: 0, timestamp: .now
    )
}
