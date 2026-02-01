import Foundation

@Observable
final class SystemMonitorService {

    private(set) var currentStats: SystemStats = .zero
    private(set) var isRunning = false

    let cpuHistory = HistoryManager<CPUUsage>()
    let memoryHistory = HistoryManager<MemoryUsage>()
    let networkHistory = HistoryManager<NetworkUsage>()
    let diskHistory = HistoryManager<DiskUsage>()
    let batteryHistory = HistoryManager<BatteryUsage>()

    private let cpuMonitor = CPUMonitor()
    private let memoryMonitor = MemoryMonitor()
    private let networkMonitor = NetworkMonitor()
    private let diskMonitor = DiskMonitor()
    private let batteryMonitor = BatteryMonitor()

    private var pollingTask: Task<Void, Never>?
    var refreshInterval: TimeInterval = 1.0

    func start() {
        guard !isRunning else { return }
        isRunning = true

        pollingTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.poll()
                try? await Task.sleep(for: .seconds(self.refreshInterval))
            }
        }
    }

    func stop() {
        pollingTask?.cancel()
        pollingTask = nil
        isRunning = false
    }

    private var widgetUpdateCounter = 0

    private func poll() async {
        let cpu = cpuMonitor.snapshot()
        let memory = memoryMonitor.snapshot()
        let network = networkMonitor.snapshot()
        let disk = diskMonitor.snapshot()
        let battery = batteryMonitor.snapshot()

        let stats = SystemStats(
            cpu: cpu,
            memory: memory,
            network: network,
            disk: disk,
            battery: battery,
            timestamp: .now
        )

        await cpuHistory.append(cpu)
        await memoryHistory.append(memory)
        await networkHistory.append(network)
        await diskHistory.append(disk)
        await batteryHistory.append(battery)

        self.currentStats = stats

        // Publish to widget every 5 polls to avoid excessive writes
        widgetUpdateCounter += 1
        if widgetUpdateCounter >= 5 {
            widgetUpdateCounter = 0
            let cpuValues = await cpuHistory.values()
            let memValues = await memoryHistory.values()
            WidgetDataPublisher.publish(
                stats: stats,
                cpuHistory: cpuValues.suffix(60).map(\.totalUsage),
                memoryHistory: memValues.suffix(60).map(\.usagePercentage)
            )
        }
    }
}
