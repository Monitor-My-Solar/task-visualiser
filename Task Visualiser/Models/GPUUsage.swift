import Foundation

struct GPUUsage: Sendable {
    var utilization: Double
    var devices: [DeviceUsage]
    var timestamp: Date

    struct DeviceUsage: Identifiable, Sendable {
        let id: Int
        var name: String
        var utilization: Double
        var vramUsed: UInt64?
        var vramTotal: UInt64?
    }

    static let zero = GPUUsage(
        utilization: 0,
        devices: [],
        timestamp: .now
    )
}
