import SwiftUI
import Charts

struct MemoryChartView: View {
    let viewModel: MemoryViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                currentSection
                breakdownSection
                historySection
            }
            .padding()
        }
        .navigationTitle("Memory")
        .task {
            await viewModel.refreshHistory()
        }
    }

    private var currentSection: some View {
        GroupBox("Current Usage") {
            HStack(spacing: 40) {
                GaugeView(
                    value: viewModel.currentUsage.usagePercentage,
                    total: 100,
                    label: "Memory",
                    color: .memoryColor,
                    lineWidth: 12
                )
                .frame(width: 120, height: 140)

                VStack(alignment: .leading, spacing: 10) {
                    MemoryStatRow(label: "Active", value: viewModel.currentUsage.active.formattedByteCount, color: .memoryActiveColor)
                    MemoryStatRow(label: "Wired", value: viewModel.currentUsage.wired.formattedByteCount, color: .memoryWiredColor)
                    MemoryStatRow(label: "Compressed", value: viewModel.currentUsage.compressed.formattedByteCount, color: .memoryCompressedColor)
                    MemoryStatRow(label: "Inactive", value: viewModel.currentUsage.inactive.formattedByteCount, color: .memoryInactiveColor)
                    MemoryStatRow(label: "Free", value: viewModel.currentUsage.free.formattedByteCount, color: .secondary)
                    Divider()
                    MemoryStatRow(label: "Total", value: viewModel.currentUsage.totalPhysical.formattedByteCount, color: .primary)
                }
            }
            .padding()
        }
    }

    private var breakdownSection: some View {
        GroupBox("Composition") {
            let mem = viewModel.currentUsage
            let total = Double(mem.totalPhysical)

            GeometryReader { geo in
                HStack(spacing: 2) {
                    segmentBar(value: mem.active, total: total, color: .memoryActiveColor, width: geo.size.width)
                    segmentBar(value: mem.wired, total: total, color: .memoryWiredColor, width: geo.size.width)
                    segmentBar(value: mem.compressed, total: total, color: .memoryCompressedColor, width: geo.size.width)
                    segmentBar(value: mem.inactive, total: total, color: .memoryInactiveColor, width: geo.size.width)
                    segmentBar(value: mem.free, total: total, color: .secondary.opacity(0.3), width: geo.size.width)
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .frame(height: 28)
            .padding()
        }
    }

    private func segmentBar(value: UInt64, total: Double, color: Color, width: CGFloat) -> some View {
        let fraction = total > 0 ? Double(value) / total : 0
        return Rectangle()
            .fill(color)
            .frame(width: max(fraction * width - 2, 0))
    }

    private var historySection: some View {
        GroupBox("History") {
            Chart(Array(viewModel.history.enumerated()), id: \.offset) { index, sample in
                AreaMark(
                    x: .value("Time", sample.timestamp),
                    yStart: .value("Start", 0),
                    yEnd: .value("Active", Double(sample.active + sample.wired + sample.compressed))
                )
                .foregroundStyle(.memoryActiveColor.opacity(0.5))
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Time", sample.timestamp),
                    yStart: .value("Start", 0),
                    yEnd: .value("Wired", Double(sample.wired + sample.compressed))
                )
                .foregroundStyle(.memoryWiredColor.opacity(0.5))
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Time", sample.timestamp),
                    yStart: .value("Start", 0),
                    yEnd: .value("Compressed", Double(sample.compressed))
                )
                .foregroundStyle(.memoryCompressedColor.opacity(0.5))
                .interpolationMethod(.catmullRom)
            }
            .chartYAxisLabel("Bytes")
            .frame(height: 250)
            .padding()
        }
    }
}

private struct MemoryStatRow: View {
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
