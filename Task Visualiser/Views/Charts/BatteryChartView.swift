import SwiftUI
import Charts

struct BatteryChartView: View {
    let viewModel: BatteryViewModel

    private var accentColor: Color {
        if viewModel.battery.isCharging { return .batteryChargingColor }
        if viewModel.battery.level < 20 { return .red }
        return .batteryColor
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                currentSection
                historySection
            }
            .padding()
        }
        .navigationTitle("Battery")
        .task {
            await viewModel.refreshHistory()
        }
    }

    private var currentSection: some View {
        GroupBox("Current Status") {
            HStack(spacing: 40) {
                GaugeView(
                    value: viewModel.battery.level,
                    total: 100,
                    label: "Battery",
                    color: accentColor,
                    lineWidth: 12
                )
                .frame(width: 120, height: 140)

                VStack(alignment: .leading, spacing: 12) {
                    BatteryStatRow(label: "Level", value: viewModel.battery.level.formattedPercentage, color: accentColor)
                    BatteryStatRow(label: "Power Source", value: viewModel.battery.powerSource.rawValue, color: .secondary)
                    BatteryStatRow(label: "Thermal State", value: viewModel.battery.thermalState.rawValue, color: thermalColor)

                    if let cycleCount = viewModel.battery.cycleCount {
                        BatteryStatRow(label: "Cycle Count", value: "\(cycleCount)", color: .secondary)
                    }

                    if let health = viewModel.battery.health {
                        BatteryStatRow(label: "Health", value: health.formattedPercentage, color: healthColor(health))
                    }

                    if let timeRemaining = viewModel.battery.timeRemaining {
                        BatteryStatRow(label: "Time Remaining", value: formatTimeRemaining(timeRemaining), color: .secondary)
                    }
                }
            }
            .padding()
        }
    }

    private var historySection: some View {
        GroupBox("History") {
            if viewModel.levelHistory.isEmpty {
                Text("Collecting data…")
                    .foregroundStyle(.secondary)
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(Array(viewModel.levelHistory.enumerated()), id: \.offset) { index, value in
                    AreaMark(
                        x: .value("Sample", index),
                        y: .value("Level", value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accentColor.opacity(0.3), accentColor.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Sample", index),
                        y: .value("Level", value)
                    )
                    .foregroundStyle(accentColor)
                    .interpolationMethod(.catmullRom)
                }
                .chartYScale(domain: 0...100)
                .chartYAxisLabel("Battery %")
                .frame(height: 250)
                .padding()
            }
        }
    }

    private var thermalColor: Color {
        switch viewModel.battery.thermalState {
        case .nominal: .green
        case .fair: .yellow
        case .serious: .orange
        case .critical: .red
        }
    }

    private func healthColor(_ health: Double) -> Color {
        if health >= 80 { return .green }
        if health >= 50 { return .yellow }
        return .red
    }

    private func formatTimeRemaining(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

private struct BatteryStatRow: View {
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
