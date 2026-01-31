import Foundation

@Observable
final class CPUViewModel {
    private let monitorService: SystemMonitorService

    var currentUsage: CPUUsage { monitorService.currentStats.cpu }

    private(set) var history: [CPUUsage] = []

    init(monitorService: SystemMonitorService) {
        self.monitorService = monitorService
    }

    func refreshHistory() async {
        history = await monitorService.cpuHistory.values()
    }
}
