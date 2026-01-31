import Foundation

@Observable
final class MemoryViewModel {
    private let monitorService: SystemMonitorService

    var currentUsage: MemoryUsage { monitorService.currentStats.memory }

    private(set) var history: [MemoryUsage] = []

    init(monitorService: SystemMonitorService) {
        self.monitorService = monitorService
    }

    func refreshHistory() async {
        history = await monitorService.memoryHistory.values()
    }
}
