import Foundation

@Observable
final class DashboardViewModel {
    private let monitorService: SystemMonitorService

    var stats: SystemStats { monitorService.currentStats }

    private(set) var cpuHistory: [Double] = []
    private(set) var memoryHistory: [Double] = []
    private(set) var networkInHistory: [Double] = []
    private(set) var networkOutHistory: [Double] = []
    private(set) var diskReadHistory: [Double] = []
    private(set) var diskWriteHistory: [Double] = []

    init(monitorService: SystemMonitorService) {
        self.monitorService = monitorService
    }

    func refreshHistory() async {
        let cpuValues = await monitorService.cpuHistory.values()
        cpuHistory = cpuValues.suffix(60).map(\.totalUsage)

        let memValues = await monitorService.memoryHistory.values()
        memoryHistory = memValues.suffix(60).map(\.usagePercentage)

        let netValues = await monitorService.networkHistory.values()
        networkInHistory = netValues.suffix(60).map(\.bytesInPerSecond)
        networkOutHistory = netValues.suffix(60).map(\.bytesOutPerSecond)

        let diskValues = await monitorService.diskHistory.values()
        diskReadHistory = diskValues.suffix(60).map(\.readPerSecond)
        diskWriteHistory = diskValues.suffix(60).map(\.writePerSecond)
    }
}
