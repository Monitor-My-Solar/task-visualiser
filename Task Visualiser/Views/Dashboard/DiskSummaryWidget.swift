import SwiftUI

struct DiskSummaryWidget: View {
    let disk: DiskUsage
    let readSparkline: [Double]
    let writeSparkline: [Double]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "internaldrive")
                    .font(.title2)
                    .foregroundStyle(.diskColor)
                Text("Disk")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                            .font(.caption)
                            .foregroundStyle(.diskReadColor)
                        Text(ByteRateFormatter.string(bytesPerSecond: disk.readPerSecond))
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .monospacedDigit()
                    }
                    Text("Read")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.caption)
                            .foregroundStyle(.diskWriteColor)
                        Text(ByteRateFormatter.string(bytesPerSecond: disk.writePerSecond))
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .monospacedDigit()
                    }
                    Text("Write")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            if !readSparkline.isEmpty {
                MiniSparklineView(values: readSparkline, color: .diskReadColor)
                    .frame(height: 30)
            }
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
