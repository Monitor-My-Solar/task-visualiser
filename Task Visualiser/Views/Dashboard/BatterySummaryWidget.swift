import SwiftUI

struct BatterySummaryWidget: View {
    let battery: BatteryUsage
    let sparkline: [Double]

    private var accentColor: Color {
        if battery.isCharging { return .batteryChargingColor }
        if battery.level < 20 { return .red }
        return .batteryColor
    }

    private var statusText: String {
        if battery.isCharging { return "Charging" }
        if battery.isPluggedIn { return "Plugged In" }
        return "On Battery"
    }

    var body: some View {
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
                Text("Battery")
                    .font(.headline)

                Text(battery.level.formattedPercentage)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(accentColor)

                Text(statusText)
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
}
