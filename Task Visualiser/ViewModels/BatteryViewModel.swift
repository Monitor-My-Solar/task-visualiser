import Foundation

@Observable
final class BatteryViewModel {
    private let monitorService: SystemMonitorService

    var battery: BatteryUsage { monitorService.currentStats.battery }

    private(set) var levelHistory: [Double] = []

    init(monitorService: SystemMonitorService) {
        self.monitorService = monitorService
    }

    func refreshHistory() async {
        let values = await monitorService.batteryHistory.values()
        levelHistory = values.suffix(60).map(\.level)
    }
}
