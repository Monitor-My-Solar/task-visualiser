import Foundation

struct CPUUsage: Sendable {
    var totalUsage: Double
    var userUsage: Double
    var systemUsage: Double
    var idleUsage: Double
    var coreUsages: [CoreUsage]
    var timestamp: Date

    struct CoreUsage: Identifiable, Sendable {
        let id: Int
        var usage: Double
    }

    static let zero = CPUUsage(
        totalUsage: 0,
        userUsage: 0,
        systemUsage: 0,
        idleUsage: 0,
        coreUsages: [],
        timestamp: .now
    )
}
