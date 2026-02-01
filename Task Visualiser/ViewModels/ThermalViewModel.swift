import Foundation

@Observable
final class ThermalViewModel {
    private let monitorService: SystemMonitorService

    var thermal: ThermalUsage { monitorService.currentStats.thermal }

    private(set) var history: [ThermalUsage] = []

    // Sparkline helpers (last 60 samples)
    private(set) var cpuTempHistory: [Double] = []
    private(set) var gpuTempHistory: [Double] = []
    private(set) var powerHistory: [Double] = []
    private(set) var fanRPMHistory: [[Double]] = []

    init(monitorService: SystemMonitorService) {
        self.monitorService = monitorService
    }

    func refreshHistory() async {
        let values = await monitorService.thermalHistory.values()
        history = values

        let recent = values.suffix(60)
        cpuTempHistory = recent.compactMap(\.cpuTemperature)
        gpuTempHistory = recent.compactMap(\.gpuTemperature)
        powerHistory = recent.compactMap(\.systemPowerWatts)

        // Build per-fan RPM history
        if let fanCount = recent.last?.fanCount, fanCount > 0 {
            var perFan: [[Double]] = Array(repeating: [], count: fanCount)
            for sample in recent {
                for (i, fan) in sample.fans.enumerated() where i < fanCount {
                    perFan[i].append(fan.currentRPM)
                }
            }
            fanRPMHistory = perFan
        } else {
            fanRPMHistory = []
        }
    }

    // MARK: - Fan control

    var canControlFans: Bool { monitorService.canControlFans }

    func setFanSpeed(fanIndex: Int, targetRPM: Double) {
        monitorService.setFanSpeed(fanIndex: fanIndex, targetRPM: targetRPM)
    }

    func restoreFanAuto(fanIndex: Int) {
        monitorService.setFanAuto(fanIndex: fanIndex)
    }

    func restoreAllFansAuto() {
        monitorService.restoreAllFansToAuto()
    }
}
