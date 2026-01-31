import Foundation

struct DiskUsage: Sendable {
    var bytesRead: UInt64
    var bytesWritten: UInt64
    var readPerSecond: Double
    var writePerSecond: Double
    var timestamp: Date

    static let zero = DiskUsage(
        bytesRead: 0, bytesWritten: 0,
        readPerSecond: 0, writePerSecond: 0,
        timestamp: .now
    )
}
