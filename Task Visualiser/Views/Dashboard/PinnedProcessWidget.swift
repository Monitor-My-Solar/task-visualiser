import SwiftUI

struct PinnedProcessWidget: View {
    let pinned: PinnedProcess
    let data: PinnedProcessService.ProcessLiveData?
    let onUnpin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if let icon = data?.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: "app")
                        .font(.title3)
                        .frame(width: 24, height: 24)
                }

                Text(pinned.displayName)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Button {
                    onUnpin()
                } label: {
                    Image(systemName: "pin.slash")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("Unpin process")
            }

            if let data, data.isRunning {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CPU")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(data.cpuUsage.formattedPercentage)
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(.cpuColor)
                        if data.cpuHistory.count >= 2 {
                            MiniSparklineView(
                                values: data.cpuHistory,
                                color: .cpuColor
                            )
                            .frame(height: 25)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Memory")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(data.memoryBytes.formattedByteCount)
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(.memoryColor)
                        if data.memoryHistory.count >= 2 {
                            MiniSparklineView(
                                values: data.memoryHistory,
                                color: .memoryColor
                            )
                            .frame(height: 25)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                Text("Not running")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
