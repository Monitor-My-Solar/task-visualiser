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
                    updaterService.openDownloadPage()
                } label: {
                    Label("Update Available — \(updaterService.latestRelease?.tagName ?? "")", systemImage: "arrow.down.app")
                }
                .buttonStyle(.link)
                .foregroundStyle(.tint)
            }

            Button {
                openWindow(id: "main")
                NSApp.activate()
            } label: {
                Label("Open Main Window", systemImage: "macwindow")
            }
            .buttonStyle(.link)
        }
        .padding()
        .frame(width: 260)
    }
}
