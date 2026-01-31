import SwiftUI
import Charts

struct CPUChartView: View {
    let viewModel: CPUViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                overallSection
                perCoreSection
                historySection
            }
            .padding()
        }
        .navigationTitle("CPU")
        .task {
            await viewModel.refreshHistory()
        }
    }

    private var overallSection: some View {
        GroupBox("Current Usage") {
            HStack(spacing: 40) {
                GaugeView(
                    value: viewModel.currentUsage.totalUsage,
                    total: 100,
                    label: "Total",
                    color: .cpuColor,
                    lineWidth: 12
                )
                .frame(width: 120, height: 140)

                VStack(alignment: .leading, spacing: 12) {
                    StatRow(label: "User", value: viewModel.currentUsage.userUsage.formattedPercentage, color: .cpuUserColor)
                    StatRow(label: "System", value: viewModel.currentUsage.systemUsage.formattedPercentage, color: .cpuSystemColor)
                    StatRow(label: "Idle", value: viewModel.currentUsage.idleUsage.formattedPercentage, color: .secondary)
                }
            }
            .padding()
        }
    }

    private var perCoreSection: some View {
        GroupBox("Per Core") {
            Chart(viewModel.currentUsage.coreUsages) { core in
                BarMark(
                    x: .value("Core", "Core \(core.id)"),
                    y: .value("Usage", core.usage)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cpuColor, .cpuColor.opacity(0.6)],
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

    private var historySection: some View {
        GroupBox("History") {
            Chart(Array(viewModel.history.enumerated()), id: \.offset) { index, sample in
                LineMark(
                    x: .value("Time", sample.timestamp),
                    y: .value("Usage", sample.totalUsage)
                )
                .foregroundStyle(.cpuColor)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Time", sample.timestamp),
                    y: .value("Usage", sample.totalUsage)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.cpuColor.opacity(0.3), Color.cpuColor.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            .chartYScale(domain: 0...100)
            .chartYAxisLabel("CPU %")
            .frame(height: 250)
            .padding()
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
