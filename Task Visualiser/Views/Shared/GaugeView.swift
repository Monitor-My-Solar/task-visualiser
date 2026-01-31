import SwiftUI

struct GaugeView: View {
    let value: Double
    let total: Double
    let label: String
    var color: Color = .blue
    var lineWidth: CGFloat = 10

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return min(max(value / total, 0), 1)
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: lineWidth)

                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: fraction)

                Text(value.formattedPercentage)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .monospacedDigit()
            }

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
