import SwiftUI
import Charts

struct GPUChartView: View {
    let viewModel: GPUViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                overallSection
                if viewModel.currentUsage.devices.count > 1 {
                    perDeviceSection
                }
                vramSection
                historySection
                aneNote
            }
            .padding()
        }
        .navigationTitle("GPU")
        .task {
            await viewModel.refreshHistory()
        }
    }

    private var overallSection: some View {
        GroupBox("Current Usage") {
            HStack(spacing: 40) {
                GaugeView(
                    value: viewModel.currentUsage.utilization,
                    total: 100,
                    label: "GPU",
                    color: .gpuColor,
                    lineWidth: 12
                )
                .frame(width: 120, height: 140)

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.currentUsage.devices) { device in
                        StatRow(
                            label: device.name,
                            value: device.utilization.formattedPercentage,
                            color: .gpuColor
                        )
                    }
                    if viewModel.currentUsage.devices.isEmpty {
                        Text("No GPU data available")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
    }

    private var perDeviceSection: some View {
        GroupBox("Per Device") {
            Chart(viewModel.currentUsage.devices) { device in
                BarMark(
                    x: .value("Device", device.name),
                    y: .value("Usage", device.utilization)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.gpuColor, .gpuColor.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(4)
            }
            .chartYScale(domain: 0...100)
            .chartYAxisLabel("Usage %")
            .frame(height: 200)
            .padding()
        }
    }

    @ViewBuilder
    private var vramSection: some View {
        let devicesWithVRAM = viewModel.currentUsage.devices.filter { $0.vramUsed != nil }
        if !devicesWithVRAM.isEmpty {
            GroupBox("VRAM") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(devicesWithVRAM) { device in
                        HStack {
                            Text(device.name)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if let used = device.vramUsed {
                                Text(used.formattedByteCount)
                                    .monospacedDigit()
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }

    private var historySection: some View {
        GroupBox("History") {
            Chart(Array(viewModel.history.enumerated()), id: \.offset) { index, sample in
                LineMark(
                    x: .value("Time", sample.timestamp),
                    y: .value("Usage", sample.utilization)
                )
                .foregroundStyle(.gpuColor)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Time", sample.timestamp),
                    y: .value("Usage", sample.utilization)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.gpuColor.opacity(0.3), Color.gpuColor.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            .chartYScale(domain: 0...100)
            .chartYAxisLabel("GPU %")
            .frame(height: 250)
            .padding()
        }
    }

    private var aneNote: some View {
        GroupBox {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                Text("Apple Neural Engine (ANE) utilization is not available — no public macOS API exists.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}

private struct StatRow: View {
    let label: String
    let value: String
    var color: Color = .primary

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .monospacedDigit()
                .fontWeight(.medium)
        }
    }
}
