import SwiftUI
import Charts

struct ProcessDetailChartView: View {
    let process: ProcessEntry
    let history: [ProcessMetricSnapshot]

    var body: some View {
        HStack(spacing: 0) {
            processInfo
                .frame(width: 180)
                .padding(.trailing, 12)

            Divider()

            cpuChart
                .padding(.horizontal, 12)

            Divider()

            memoryChart
                .padding(.leading, 12)
        }
        .padding()
    }

    private var processInfo: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                if let icon = process.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: "app")
                        .font(.title)
                        .frame(width: 32, height: 32)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(process.name)
                        .font(.headline)
                        .lineLimit(1)
                    Text("PID \(process.pid)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            LabeledContent("CPU", value: process.formattedCPU)
                .font(.caption)
            LabeledContent("Memory", value: process.formattedMemory)
                .font(.caption)
            LabeledContent("User", value: process.user)
                .font(.caption)
        }
    }

    private var cpuChart: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("CPU Usage")
                .font(.caption)
                .foregroundStyle(.secondary)

            if history.count >= 2 {
                Chart(Array(history.enumerated()), id: \.offset) { index, sample in
                    LineMark(
                        x: .value("Time", index),
                        y: .value("CPU", sample.cpuUsage)
                    )
                    .foregroundStyle(Color.cpuColor)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Time", index),
                        y: .value("CPU", sample.cpuUsage)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.cpuColor.opacity(0.3), Color.cpuColor.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                .chartYScale(domain: 0...max(history.map(\.cpuUsage).max() ?? 1, 1))
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(v.formattedPercentage)
                                    .font(.system(size: 9))
                            }
                        }
                        AxisGridLine()
                    }
                }
            } else {
                ContentUnavailableView {
                    Label("Collecting data...", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.caption)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var memoryChart: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Memory")
                .font(.caption)
                .foregroundStyle(.secondary)

            if history.count >= 2 {
                let maxMem = Double(history.map(\.memoryBytes).max() ?? 1)
                Chart(Array(history.enumerated()), id: \.offset) { index, sample in
                    LineMark(
                        x: .value("Time", index),
                        y: .value("Memory", Double(sample.memoryBytes))
                    )
                    .foregroundStyle(Color.memoryColor)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Time", index),
                        y: .value("Memory", Double(sample.memoryBytes))
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.memoryColor.opacity(0.3), Color.memoryColor.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                .chartYScale(domain: 0...max(maxMem, 1))
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(UInt64(v).formattedByteCount)
                                    .font(.system(size: 9))
                            }
                        }
                        AxisGridLine()
                    }
                }
            } else {
                ContentUnavailableView {
                    Label("Collecting data...", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.caption)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
