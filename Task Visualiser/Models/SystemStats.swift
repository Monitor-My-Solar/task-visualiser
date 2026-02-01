import Foundation

struct SystemStats: Sendable {
    var cpu: CPUUsage
    var memory: MemoryUsage
    var network: NetworkUsage
    var disk: DiskUsage
    var battery: BatteryUsage
    var timestamp: Date

    static let zero = SystemStats(
        cpu: .zero,
        memory: .zero,
        network: .zero,
        disk: .zero,
        battery: .zero,
        timestamp: .now
    )
}
