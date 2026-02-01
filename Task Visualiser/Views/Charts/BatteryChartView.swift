import SwiftUI
import Charts

struct BatteryChartView: View {
    let viewModel: BatteryViewModel

    private var accentColor: Color {
        if !viewModel.battery.hasBattery { return thermalColor }
        if viewModel.battery.isCharging { return .batteryChargingColor }
        if viewModel.battery.level < 20 { return .red }
        return .batteryColor
    }

    private var thermalColor: Color {
        switch viewModel.battery.thermalState {
        case .nominal: .green
        case .fair: .yellow
        case .serious: .orange
        case .critical: .red
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.battery.hasBattery {
                    batteryStatusSection
                }
                thermalSection
                if viewModel.battery.hasBattery {
                    historySection
                }
            }
            .padding()
        }
        .navigationTitle("Energy")
        .task {
            await viewModel.refreshHistory()
        }
    }

    private var batteryStatusSection: some View {
        GroupBox("Battery") {
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
                    EnergyStatRow(label: "Level", value: viewModel.battery.level.formattedPercentage, color: accentColor)
                    EnergyStatRow(label: "Power Source", value: viewModel.battery.powerSource.rawValue, color: .secondary)
                    EnergyStatRow(label: "Status", value: viewModel.battery.isCharging ? "Charging" : viewModel.battery.isPluggedIn ? "Plugged In" : "On Battery", color: .secondary)

                    if let cycleCount = viewModel.battery.cycleCount {
                        EnergyStatRow(label: "Cycle Count", value: "\(cycleCount)", color: .secondary)
                    }

                    if let health = viewModel.battery.health {
                        EnergyStatRow(label: "Health", value: health.formattedPercentage, color: healthColor(health))
                    }

                    if let timeRemaining = viewModel.battery.timeRemaining {
                        EnergyStatRow(label: "Time Remaining", value: formatTimeRemaining(timeRemaining), color: .secondary)
                    }
                }
            }
            .padding()
        }
    }

    private var thermalSection: some View {
        GroupBox("System Thermal State") {
            HStack(spacing: 40) {
                VStack(spacing: 8) {
                    Image(systemName: "thermometer.medium")
                        .font(.system(size: 36))
                        .foregroundStyle(thermalColor)
                    Text(viewModel.battery.thermalState.rawValue)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(thermalColor)
                }

                VStack(alignment: .leading, spacing: 12) {
                    EnergyStatRow(label: "Thermal State", value: viewModel.battery.thermalState.rawValue, color: thermalColor)
                    EnergyStatRow(label: "Power Source", value: viewModel.battery.powerSource.rawValue, color: .secondary)
                }
            }
            .padding()
        }
    }

    private var historySection: some View {
        GroupBox("Battery History") {
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

private struct EnergyStatRow: View {
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
