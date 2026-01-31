import Foundation

struct WidgetSnapshot: Codable {
    var cpuUsage: Double
    var memoryUsagePercent: Double
    var memoryUsed: UInt64
    var memoryTotal: UInt64
    var networkInPerSec: Double
    var networkOutPerSec: Double
    var diskReadPerSec: Double
    var diskWritePerSec: Double
    var cpuHistory: [Double]
    var memoryHistory: [Double]
    var timestamp: Date

    static let empty = WidgetSnapshot(
        cpuUsage: 0, memoryUsagePercent: 0,
        memoryUsed: 0, memoryTotal: 0,
        networkInPerSec: 0, networkOutPerSec: 0,
        diskReadPerSec: 0, diskWritePerSec: 0,
        cpuHistory: [], memoryHistory: [],
        timestamp: .now
    )
}

enum SharedDataStore {
    static let suiteName = "group.task-visualiser"
    private static let snapshotKey = "widget_snapshot"

    static func save(_ snapshot: WidgetSnapshot) {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: snapshotKey)
    }

    static func load() -> WidgetSnapshot {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            return .empty
        }
        return snapshot
    }
}
