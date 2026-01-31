import SwiftUI
import Charts

struct NetworkChartView: View {
    let viewModel: NetworkViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                currentSection
                historySection
            }
            .padding()
        }
        .navigationTitle("Network")
        .task {
            await viewModel.refreshHistory()
        }
    }

    private var currentSection: some View {
        GroupBox("Current Throughput") {
            HStack(spacing: 40) {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title)
                        .foregroundStyle(.networkInColor)
                    Text(ByteRateFormatter.string(bytesPerSecond: viewModel.currentUsage.bytesInPerSecond))
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .monospacedDigit()
                    Text("Download")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()
                    .frame(height: 60)

                VStack(spacing: 8) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                        .foregroundStyle(.networkOutColor)
                    Text(ByteRateFormatter.string(bytesPerSecond: viewModel.currentUsage.bytesOutPerSecond))
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .monospacedDigit()
                    Text("Upload")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
    }

    private var historySection: some View {
        GroupBox("History") {
            Chart {
                ForEach(Array(viewModel.history.enumerated()), id: \.offset) { index, sample in
                    LineMark(
                        x: .value("Time", sample.timestamp),
                        y: .value("Download", sample.bytesInPerSecond),
                        series: .value("Direction", "In")
                    )
                    .foregroundStyle(.networkInColor)
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Time", sample.timestamp),
                        y: .value("Upload", sample.bytesOutPerSecond),
                        series: .value("Direction", "Out")
                    )
                    .foregroundStyle(.networkOutColor)
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartForegroundStyleScale([
                "In": Color.networkInColor,
                "Out": Color.networkOutColor
            ])
            .chartYAxisLabel("Bytes/s")
            .frame(height: 250)
            .padding()
        }
    }
}
