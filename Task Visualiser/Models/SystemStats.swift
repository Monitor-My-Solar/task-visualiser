import Foundation

struct SystemStats: Sendable {
    var cpu: CPUUsage
    var memory: MemoryUsage
    var gpu: GPUUsage
    var network: NetworkUsage
    var disk: DiskUsage
    var battery: BatteryUsage
    var thermal: ThermalUsage
    var timestamp: Date

    static let zero = SystemStats(
        cpu: .zero,
        memory: .zero,
        gpu: .zero,
        network: .zero,
        disk: .zero,
        battery: .zero,
        thermal: .zero,
        timestamp: .now
    )
}
