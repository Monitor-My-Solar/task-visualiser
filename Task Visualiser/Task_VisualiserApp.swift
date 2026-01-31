import SwiftUI

@main
struct Task_VisualiserApp: App {
    @State private var appState = AppState()
    @State private var monitorService = SystemMonitorService()
    @State private var pinnedProcessService = PinnedProcessService()

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environment(appState)
                .environment(monitorService)
                .environment(pinnedProcessService)
                .frame(minWidth: 800, minHeight: 500)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1100, height: 700)

        Settings {
            SettingsView()
                .environment(appState)
                .environment(monitorService)
        }

        MenuBarExtra(isInserted: $appState.showMenuBarExtra) {
            MenuBarView()
                .environment(monitorService)
                .environment(pinnedProcessService)
        } label: {
            let cpuText = String(format: "%.0f%%", monitorService.currentStats.cpu.totalUsage)
            Label(cpuText, systemImage: "cpu")
        }
        .menuBarExtraStyle(.window)
    }
}
