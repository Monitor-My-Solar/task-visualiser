import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(SystemMonitorService.self) private var monitorService

    var body: some View {
        @Bindable var appState = appState

        TabView {
            Form {
                Picker("Refresh Interval", selection: $appState.refreshInterval) {
                    Text("0.5 seconds").tag(0.5 as TimeInterval)
                    Text("1 second").tag(1.0 as TimeInterval)
                    Text("2 seconds").tag(2.0 as TimeInterval)
                    Text("5 seconds").tag(5.0 as TimeInterval)
                }
                .onChange(of: appState.refreshInterval) { _, newValue in
                    monitorService.refreshInterval = newValue
                }

                Picker("History Duration", selection: $appState.historyDuration) {
                    Text("5 minutes").tag(300.0 as TimeInterval)
                    Text("10 minutes").tag(600.0 as TimeInterval)
                    Text("30 minutes").tag(1800.0 as TimeInterval)
                }

                Toggle("Show Menu Bar Extra", isOn: $appState.showMenuBarExtra)
            }
            .padding()
            .tabItem {
                Label("General", systemImage: "gear")
            }

            VStack(spacing: 12) {
                Image(systemName: "gauge.with.dots.needle.33percent")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)

                Text("Task Visualiser")
                    .font(.title2.bold())

                Text("System Monitor")
                    .foregroundStyle(.secondary)

                Divider()

                if appState.isSandboxed {
                    Label("Running in sandbox (App Store mode)", systemImage: "lock.shield")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Label("Running with full access", systemImage: "lock.open")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
        }
        .frame(width: 400, height: 250)
    }
}
