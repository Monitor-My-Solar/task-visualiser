import Foundation

@Observable
final class DiskViewModel {
    private let monitorService: SystemMonitorService

    var currentUsage: DiskUsage { monitorService.currentStats.disk }

    private(set) var history: [DiskUsage] = []

    init(monitorService: SystemMonitorService) {
        self.monitorService = monitorService
    }

    func refreshHistory() async {
        history = await monitorService.diskHistory.values()
    }
}
