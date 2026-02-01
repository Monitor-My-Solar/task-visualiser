import Foundation

@Observable
final class GPUViewModel {
    private let monitorService: SystemMonitorService

    var currentUsage: GPUUsage { monitorService.currentStats.gpu }

    private(set) var history: [GPUUsage] = []

    init(monitorService: SystemMonitorService) {
        self.monitorService = monitorService
    }

    func refreshHistory() async {
        history = await monitorService.gpuHistory.values()
    }
}
