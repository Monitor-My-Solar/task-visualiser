import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(SystemMonitorService.self) private var monitorService
    @Environment(UpdaterService.self) private var updaterService

    private var updatesTab: some View {
        @Bindable var updater = updaterService

        return Form {
            Toggle("Check for updates automatically", isOn: $updater.autoCheckForUpdates)

            LabeledContent("Current Version") {
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                    .foregroundStyle(.secondary)
            }

            if let lastChecked = updaterService.lastChecked {
                LabeledContent("Last Checked") {
                    Text(lastChecked, style: .relative)
                        .foregroundStyle(.secondary)
                }
            }

            if let error = updaterService.lastError {
                LabeledContent("Error") {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            HStack {
                Button("Check Now") {
                    Task { await updaterService.checkForUpdates(userInitiated: true) }
                }
                .disabled(updaterService.isChecking)

                if updaterService.isChecking {
                    ProgressView()
                        .controlSize(.small)
                }

                if updaterService.updateAvailable {
                    Spacer()
                    Button("Install Update") {
                        updaterService.downloadAndInstall()
                    }
                }
            }

            if updaterService.updateAvailable, let release = updaterService.latestRelease {
                LabeledContent("Available") {
                    Text(release.tagName)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }

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

            updatesTab
                .tabItem {
                    Label("Updates", systemImage: "arrow.triangle.2.circlepath")
                }

            VStack(spacing: 12) {
                Image(systemName: "gauge.with.dots.needle.33percent")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)

                Text("Task Visualiser")
                    .font(.title2.bold())

                Text("by Monitor My Solar")
                    .foregroundStyle(.secondary)

                Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Divider()

                HStack(spacing: 16) {
                    Link(destination: URL(string: "https://github.com/MonitorMySolar/Task-Visualiser")!) {
                        Label("GitHub", systemImage: "link")
                    }
                    Link(destination: URL(string: "https://monitormysolar.com")!) {
                        Label("Website", systemImage: "globe")
                    }
                }
                .font(.caption)

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
        .frame(width: 400, height: 320)
    }
}
