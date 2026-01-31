import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = .blue
    var sparklineValues: [Double]? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                Spacer()

                if let sparklineValues, !sparklineValues.isEmpty {
                    MiniSparklineView(values: sparklineValues, color: color)
                        .frame(width: 60, height: 24)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .monospacedDigit()

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
