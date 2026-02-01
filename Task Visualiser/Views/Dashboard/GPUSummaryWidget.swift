import SwiftUI

struct GPUSummaryWidget: View {
    let usage: Double
    let sparkline: [Double]
    let vramUsed: UInt64?

    var body: some View {
        HStack {
            GaugeView(
                value: usage,
                total: 100,
                label: "GPU",
                color: .gpuColor,
                lineWidth: 8
            )
            .frame(width: 80, height: 100)

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("GPU Usage")
                    .font(.headline)

                Text(usage.formattedPercentage)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(.gpuColor)

                if let vram = vramUsed {
                    Text("VRAM: \(vram.formattedByteCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !sparkline.isEmpty {
                    MiniSparklineView(values: sparkline, color: .gpuColor, maxValue: 100)
                        .frame(height: 30)
                }
            }
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
