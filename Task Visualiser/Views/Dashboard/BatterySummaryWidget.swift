import SwiftUI

struct BatterySummaryWidget: View {
    let battery: BatteryUsage
    let sparkline: [Double]

    private var accentColor: Color {
        if !battery.hasBattery { return thermalColor }
        if battery.isCharging { return .batteryChargingColor }
        if battery.level < 20 { return .red }
        return .batteryColor
    }

    private var thermalColor: Color {
        switch battery.thermalState {
        case .nominal: .green
        case .fair: .yellow
        case .serious: .orange
        case .critical: .red
        }
    }

    var body: some View {
        if battery.hasBattery {
            batteryLayout
        } else {
            thermalOnlyLayout
        }
    }

    private var batteryLayout: some View {
        HStack {
            GaugeView(
                value: battery.level,
                total: 100,
                label: "Battery",
                color: accentColor,
                lineWidth: 8
            )
            .frame(width: 80, height: 100)

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Energy")
                    .font(.headline)

                Text(battery.level.formattedPercentage)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(accentColor)

                Text(battery.isCharging ? "Charging" : battery.isPluggedIn ? "Plugged In" : "On Battery")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !sparkline.isEmpty {
                    MiniSparklineView(values: sparkline, color: accentColor, maxValue: 100)
                        .frame(height: 30)
                }
            }
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var thermalOnlyLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.title2)
                    .foregroundStyle(thermalColor)
                Text("Energy")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(battery.thermalState.rawValue)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(thermalColor)
                    Text("Thermal State")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(battery.powerSource.rawValue)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                    Text("Power Source")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
