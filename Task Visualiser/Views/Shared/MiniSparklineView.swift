import SwiftUI
import Charts

struct MiniSparklineView: View {
    let values: [Double]
    var color: Color = .blue
    var maxValue: Double? = nil

    private var resolvedMax: Double {
        if let maxValue, maxValue > 0 { return maxValue }
        return values.max() ?? 1
    }

    var body: some View {
        Chart(Array(values.enumerated()), id: \.offset) { index, value in
            LineMark(
                x: .value("Time", index),
                y: .value("Value", value)
            )
            .foregroundStyle(color)
            .interpolationMethod(.catmullRom)

            AreaMark(
                x: .value("Time", index),
                y: .value("Value", value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [color.opacity(0.3), color.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
        }
        .chartYScale(domain: 0...resolvedMax)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
    }
}
