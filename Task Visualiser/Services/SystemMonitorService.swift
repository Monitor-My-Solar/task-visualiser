import Foundation

@Observable
final class SystemMonitorService {

    private(set) var currentStats: SystemStats = .zero
    private(set) var isRunning = false

    let cpuHistory = HistoryManager<CPUUsage>()
    let memoryHistory = HistoryManager<MemoryUsage>()
    let gpuHistory = HistoryManager<GPUUsage>()
    let networkHistory = HistoryManager<NetworkUsage>()
    let diskHistory = HistoryManager<DiskUsage>()
    let batteryHistory = HistoryManager<BatteryUsage>()
    let thermalHistory = HistoryManager<ThermalUsage>()

    private let cpuMonitor = CPUMonitor()
    private let memoryMonitor = MemoryMonitor()
    private let gpuMonitor = GPUMonitor()
    private let networkMonitor = NetworkMonitor()
    private let diskMonitor = DiskMonitor()
    private let batteryMonitor = BatteryMonitor()
    private let thermalMonitor = SMCThermalMonitor()

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

    // MARK: - Fan control

    func setFanSpeed(fanIndex: Int, targetRPM: Double) {
        thermalMonitor.setFanSpeed(fanIndex: fanIndex, targetRPM: targetRPM)
    }

    func setFanAuto(fanIndex: Int) {
        thermalMonitor.setFanAuto(fanIndex: fanIndex)
    }

    func restoreAllFansToAuto() {
        thermalMonitor.restoreAllFansToAuto()
    }

    private var widgetUpdateCounter = 0

    private func poll() async {
        let cpu = cpuMonitor.snapshot()
        let memory = memoryMonitor.snapshot()
        let gpu = gpuMonitor.snapshot()
        let network = networkMonitor.snapshot()
        let disk = diskMonitor.snapshot()
        let battery = batteryMonitor.snapshot()
        let thermal = thermalMonitor.snapshot()

        let stats = SystemStats(
            cpu: cpu,
            memory: memory,
            gpu: gpu,
            network: network,
            disk: disk,
            battery: battery,
            thermal: thermal,
            timestamp: .now
        )

        await cpuHistory.append(cpu)
        await memoryHistory.append(memory)
        await gpuHistory.append(gpu)
        await networkHistory.append(network)
        await diskHistory.append(disk)
        await batteryHistory.append(battery)
        await thermalHistory.append(thermal)

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
