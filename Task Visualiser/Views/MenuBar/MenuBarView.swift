import SwiftUI

struct MenuBarView: View {
    @Environment(SystemMonitorService.self) private var monitorService
    @Environment(PinnedProcessService.self) private var pinnedService
    @Environment(UpdaterService.self) private var updaterService
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // CPU
            HStack {
                Image(systemName: "cpu")
                    .foregroundStyle(.cpuColor)
                    .frame(width: 20)
                Text("CPU")
                    .font(.headline)
                Spacer()
                Text(monitorService.currentStats.cpu.totalUsage.formattedPercentage)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: monitorService.currentStats.cpu.totalUsage, total: 100)
                .tint(.cpuColor)

            Divider()

            // Memory
            HStack {
                Image(systemName: "memorychip")
                    .foregroundStyle(.memoryColor)
                    .frame(width: 20)
                Text("Memory")
                    .font(.headline)
                Spacer()
                Text(monitorService.currentStats.memory.usagePercentage.formattedPercentage)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: monitorService.currentStats.memory.usagePercentage, total: 100)
                .tint(.memoryColor)

            Divider()

            // GPU
            HStack {
                Image(systemName: "display")
                    .foregroundStyle(.gpuColor)
                    .frame(width: 20)
                Text("GPU")
                    .font(.headline)
                Spacer()
                Text(monitorService.currentStats.gpu.utilization.formattedPercentage)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: monitorService.currentStats.gpu.utilization, total: 100)
                .tint(.gpuColor)

            Divider()

            // Network
            HStack {
                Image(systemName: "network")
                    .foregroundStyle(.networkColor)
                    .frame(width: 20)
                Text("Network")
                    .font(.headline)
                Spacer()
            }
            HStack {
                Label {
                    Text(ByteRateFormatter.string(bytesPerSecond: monitorService.currentStats.network.bytesInPerSecond))
                        .monospacedDigit()
                } icon: {
                    Image(systemName: "arrow.down")
                        .foregroundStyle(.networkInColor)
                }
                Spacer()
                Label {
                    Text(ByteRateFormatter.string(bytesPerSecond: monitorService.currentStats.network.bytesOutPerSecond))
                        .monospacedDigit()
                } icon: {
                    Image(systemName: "arrow.up")
                        .foregroundStyle(.networkOutColor)
                }
            }
            .font(.caption)

            Divider()

            // Disk
            HStack {
                Image(systemName: "internaldrive")
                    .foregroundStyle(.diskColor)
                    .frame(width: 20)
                Text("Disk")
                    .font(.headline)
                Spacer()
            }
            HStack {
                Label {
                    Text(ByteRateFormatter.string(bytesPerSecond: monitorService.currentStats.disk.readPerSecond))
                        .monospacedDigit()
                } icon: {
                    Image(systemName: "arrow.down")
                        .foregroundStyle(.diskReadColor)
                }
                Spacer()
                Label {
                    Text(ByteRateFormatter.string(bytesPerSecond: monitorService.currentStats.disk.writePerSecond))
                        .monospacedDigit()
                } icon: {
                    Image(systemName: "arrow.up")
                        .foregroundStyle(.diskWriteColor)
                }
            }
            .font(.caption)

            Divider()

            // Energy
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(energyMenuColor)
                    .frame(width: 20)
                Text("Energy")
                    .font(.headline)
                Spacer()
                if monitorService.currentStats.battery.hasBattery {
                    Text(monitorService.currentStats.battery.level.formattedPercentage)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            if monitorService.currentStats.battery.hasBattery {
                ProgressView(value: monitorService.currentStats.battery.level, total: 100)
                    .tint(energyMenuColor)
                HStack {
                    Text(monitorService.currentStats.battery.isCharging ? "Charging" : monitorService.currentStats.battery.isPluggedIn ? "Plugged In" : "On Battery")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let timeRemaining = monitorService.currentStats.battery.timeRemaining {
                        Text(formatMenuTimeRemaining(timeRemaining))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            HStack {
                Text("Thermal: \(monitorService.currentStats.battery.thermalState.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            if !pinnedService.pinnedProcesses.isEmpty {
                Divider()

                ForEach(pinnedService.pinnedProcesses) { pinned in
                    if let data = pinnedService.liveData[pinned.identifier] {
                        HStack {
                            if let icon = data.icon {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 16, height: 16)
                            }
                            Text(data.name)
                                .font(.headline)
                            Spacer()
                            Text(data.isRunning ? "" : "Not running")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if data.isRunning {
                            HStack {
                                Label {
                                    Text(data.cpuUsage.formattedPercentage)
                                        .monospacedDigit()
                                } icon: {
                                    Image(systemName: "cpu")
                                        .foregroundStyle(.cpuColor)
                                }
                                Spacer()
                                Label {
                                    Text(data.memoryBytes.formattedByteCount)
                                        .monospacedDigit()
                                } icon: {
                                    Image(systemName: "memorychip")
                                        .foregroundStyle(.memoryColor)
                                }
                            }
                            .font(.caption)
                        }
                    }
                }
            }

            Divider()

            if updaterService.updateAvailable {
                Button {
                    updaterService.downloadAndInstall()
                } label: {
                    Label("Install Update — \(updaterService.latestRelease?.tagName ?? "")", systemImage: "arrow.down.app")
                }
                .buttonStyle(.link)
                .foregroundStyle(.tint)

                if updaterService.isDownloading {
                    ProgressView(value: updaterService.downloadProgress)
                        .progressViewStyle(.linear)
                }
            }

            Button {
                openWindow(id: "main")
                NSApp.activate()
            } label: {
                Label("Open Main Window", systemImage: "macwindow")
            }
            .buttonStyle(.link)

            Divider()

            BrandingFooterView(compact: true)
        }
        .padding()
        .frame(width: 260)
    }

    private var energyMenuColor: Color {
        let battery = monitorService.currentStats.battery
        if battery.isCharging { return .batteryChargingColor }
        if battery.level < 20 { return .red }
        return .batteryColor
    }

    private func formatMenuTimeRemaining(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m remaining"
        }
        return "\(minutes)m remaining"
    }
}
