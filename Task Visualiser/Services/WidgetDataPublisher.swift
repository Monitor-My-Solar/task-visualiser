import Foundation
import WidgetKit

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

enum WidgetDataPublisher {
    private static let suiteName = "group.task-visualiser"
    private static let snapshotKey = "widget_snapshot"

    static func publish(stats: SystemStats, cpuHistory: [Double], memoryHistory: [Double]) {
        let snapshot = WidgetSnapshot(
            cpuUsage: stats.cpu.totalUsage,
            memoryUsagePercent: stats.memory.usagePercentage,
            memoryUsed: stats.memory.used,
            memoryTotal: stats.memory.totalPhysical,
            networkInPerSec: stats.network.bytesInPerSecond,
            networkOutPerSec: stats.network.bytesOutPerSecond,
            diskReadPerSec: stats.disk.readPerSecond,
            diskWritePerSec: stats.disk.writePerSecond,
            cpuHistory: Array(cpuHistory.suffix(60)),
            memoryHistory: Array(memoryHistory.suffix(60)),
            timestamp: stats.timestamp
        )

        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: snapshotKey)
    }

    static func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
