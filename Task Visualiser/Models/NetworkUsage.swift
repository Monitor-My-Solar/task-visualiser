import Foundation

struct NetworkUsage: Sendable {
    var bytesIn: UInt64
    var bytesOut: UInt64
    var bytesInPerSecond: Double
    var bytesOutPerSecond: Double
    var timestamp: Date

    static let zero = NetworkUsage(
        bytesIn: 0, bytesOut: 0,
        bytesInPerSecond: 0, bytesOutPerSecond: 0,
        timestamp: .now
    )
}
