import SwiftUI

struct MemorySummaryWidget: View {
    let memory: MemoryUsage
    let sparkline: [Double]

    var body: some View {
        HStack {
            GaugeView(
                value: memory.usagePercentage,
                total: 100,
                label: "Memory",
                color: .memoryColor,
                lineWidth: 8
            )
            .frame(width: 80, height: 100)

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Memory")
                    .font(.headline)

                Text("\(memory.used.formattedByteCount) / \(memory.totalPhysical.formattedByteCount)")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.memoryColor)

                if !sparkline.isEmpty {
                    MiniSparklineView(values: sparkline, color: .memoryColor, maxValue: 100)
                        .frame(height: 30)
                }
            }
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
