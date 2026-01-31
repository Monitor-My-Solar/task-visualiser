import SwiftUI
import Charts

struct DiskChartView: View {
    let viewModel: DiskViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                currentSection
                historySection
            }
            .padding()
        }
        .navigationTitle("Disk")
        .task {
            await viewModel.refreshHistory()
        }
    }

    private var currentSection: some View {
        GroupBox("Current Activity") {
            HStack(spacing: 40) {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.title)
                        .foregroundStyle(.diskReadColor)
                    Text(ByteRateFormatter.string(bytesPerSecond: viewModel.currentUsage.readPerSecond))
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .monospacedDigit()
                    Text("Read")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()
                    .frame(height: 60)

                VStack(spacing: 8) {
                    Image(systemName: "arrow.up.doc.fill")
                        .font(.title)
                        .foregroundStyle(.diskWriteColor)
                    Text(ByteRateFormatter.string(bytesPerSecond: viewModel.currentUsage.writePerSecond))
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .monospacedDigit()
                    Text("Write")
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
                        y: .value("Read", sample.readPerSecond),
                        series: .value("Activity", "Read")
                    )
                    .foregroundStyle(.diskReadColor)
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Time", sample.timestamp),
                        y: .value("Write", sample.writePerSecond),
                        series: .value("Activity", "Write")
                    )
                    .foregroundStyle(.diskWriteColor)
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartForegroundStyleScale([
                "Read": Color.diskReadColor,
                "Write": Color.diskWriteColor
            ])
            .chartYAxisLabel("Bytes/s")
            .frame(height: 250)
            .padding()
        }
    }
}
