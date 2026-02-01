import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(SystemMonitorService.self) private var monitorService
    @Environment(PinnedProcessService.self) private var pinnedProcessService
    @Environment(UpdaterService.self) private var updaterService

    var body: some View {
        @Bindable var appState = appState

        NavigationSplitView {
            SidebarView(selection: $appState.selectedTab)
        } detail: {
            switch appState.selectedTab {
            case .dashboard:
                DashboardView(viewModel: DashboardViewModel(monitorService: monitorService))
            case .cpu:
                CPUChartView(viewModel: CPUViewModel(monitorService: monitorService))
            case .memory:
                MemoryChartView(viewModel: MemoryViewModel(monitorService: monitorService))
            case .gpu:
                GPUChartView(viewModel: GPUViewModel(monitorService: monitorService))
            case .network:
                NetworkChartView(viewModel: NetworkViewModel(monitorService: monitorService))
            case .disk:
                DiskChartView(viewModel: DiskViewModel(monitorService: monitorService))
            case .battery:
                BatteryChartView(viewModel: BatteryViewModel(monitorService: monitorService))
            case .thermal:
                ThermalChartView(viewModel: ThermalViewModel(monitorService: monitorService))
            case .processes:
                ProcessListView(viewModel: ProcessListViewModel(isSandboxed: appState.isSandboxed))
            case nil:
                Text("Select a category")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .task {
            monitorService.refreshInterval = appState.refreshInterval
            monitorService.start()
            pinnedProcessService.start()
            updaterService.startPeriodicChecks()
        }
        .sheet(isPresented: Bindable(updaterService).showUpdateAlert) {
            UpdateAlertView()
                .environment(updaterService)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
            monitorService.restoreAllFansToAuto()
        }
    }
}
