import SwiftUI

struct NetworkSummaryWidget: View {
    let network: NetworkUsage
    let inSparkline: [Double]
    let outSparkline: [Double]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "network")
                    .font(.title2)
                    .foregroundStyle(.networkColor)
                Text("Network")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                            .font(.caption)
                            .foregroundStyle(.networkInColor)
                        Text(ByteRateFormatter.string(bytesPerSecond: network.bytesInPerSecond))
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .monospacedDigit()
                    }
                    Text("Download")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.caption)
                            .foregroundStyle(.networkOutColor)
                        Text(ByteRateFormatter.string(bytesPerSecond: network.bytesOutPerSecond))
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .monospacedDigit()
                    }
                    Text("Upload")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            if !inSparkline.isEmpty {
                MiniSparklineView(values: inSparkline, color: .networkInColor)
                    .frame(height: 30)
            }
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
