import SwiftUI

struct CPUSummaryWidget: View {
    let usage: Double
    let sparkline: [Double]

    var body: some View {
        HStack {
            GaugeView(
                value: usage,
                total: 100,
                label: "CPU",
                color: .cpuColor,
                lineWidth: 8
            )
            .frame(width: 80, height: 100)

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("CPU Usage")
                    .font(.headline)

                Text(usage.formattedPercentage)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(.cpuColor)

                if !sparkline.isEmpty {
                    MiniSparklineView(values: sparkline, color: .cpuColor, maxValue: 100)
                        .frame(height: 30)
                }
            }
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
