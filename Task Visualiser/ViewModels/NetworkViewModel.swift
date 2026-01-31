import Foundation

@Observable
final class NetworkViewModel {
    private let monitorService: SystemMonitorService

    var currentUsage: NetworkUsage { monitorService.currentStats.network }

    private(set) var history: [NetworkUsage] = []

    init(monitorService: SystemMonitorService) {
        self.monitorService = monitorService
    }

    func refreshHistory() async {
        history = await monitorService.networkHistory.values()
    }
}
