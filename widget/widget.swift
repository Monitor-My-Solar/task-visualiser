import WidgetKit
import SwiftUI

struct SystemMetricProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> MetricEntry {
        MetricEntry(date: .now, snapshot: .empty, metric: .cpu)
    }

    func snapshot(for configuration: MetricSelectionIntent, in context: Context) async -> MetricEntry {
        let data = SharedDataStore.load()
        return MetricEntry(date: .now, snapshot: data, metric: configuration.metric)
    }

    func timeline(for configuration: MetricSelectionIntent, in context: Context) async -> Timeline<MetricEntry> {
        let data = SharedDataStore.load()
        let entry = MetricEntry(date: .now, snapshot: data, metric: configuration.metric)
        return Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(5)))
    }
}

struct MetricEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
    let metric: MetricType
}

// MARK: - Widget Views

struct SystemMetricWidgetView: View {
    var entry: MetricEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundStyle(accentColor)
                Spacer()
                Text(entry.metric.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(primaryValue)
                .font(.system(.title, design: .rounded, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(accentColor)
                .minimumScaleFactor(0.6)

            Text(secondaryValue)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if !sparklineData.isEmpty {
                WidgetSparkline(values: sparklineData, color: accentColor)
                    .frame(height: 24)
            }
        }
    }

    private var mediumView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: iconName)
                        .font(.title3)
                        .foregroundStyle(accentColor)
                    Text(entry.metric.rawValue)
                        .font(.headline)
                }

                Spacer()

                Text(primaryValue)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(accentColor)
                    .minimumScaleFactor(0.5)

                Text(secondaryValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !sparklineData.isEmpty {
                WidgetSparkline(values: sparklineData, color: accentColor)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Computed per metric

    private var iconName: String {
        switch entry.metric {
        case .cpu: "cpu"
        case .memory: "memorychip"
        case .network: "network"
        case .disk: "internaldrive"
        }
    }

    private var accentColor: Color {
        switch entry.metric {
        case .cpu: .blue
        case .memory: .green
        case .network: .purple
        case .disk: .orange
        }
    }

    private var primaryValue: String {
        switch entry.metric {
        case .cpu:
            String(format: "%.1f%%", entry.snapshot.cpuUsage)
        case .memory:
            String(format: "%.1f%%", entry.snapshot.memoryUsagePercent)
        case .network:
            formatRate(entry.snapshot.networkInPerSec)
        case .disk:
            formatRate(entry.snapshot.diskReadPerSec)
        }
    }

    private var secondaryValue: String {
        switch entry.metric {
        case .cpu:
            "CPU Usage"
        case .memory:
            "\(formatBytes(entry.snapshot.memoryUsed)) / \(formatBytes(entry.snapshot.memoryTotal))"
        case .network:
            "\u{2191} \(formatRate(entry.snapshot.networkOutPerSec))"
        case .disk:
            "\u{2191} \(formatRate(entry.snapshot.diskWritePerSec))"
        }
    }

    private var sparklineData: [Double] {
        switch entry.metric {
        case .cpu: entry.snapshot.cpuHistory
        case .memory: entry.snapshot.memoryHistory
        case .network, .disk: []
        }
    }

    private func formatRate(_ bytesPerSec: Double) -> String {
        let abs = abs(bytesPerSec)
        if abs < 1024 { return String(format: "%.0f B/s", bytesPerSec) }
        if abs < 1024 * 1024 { return String(format: "%.1f KB/s", bytesPerSec / 1024) }
        if abs < 1024 * 1024 * 1024 { return String(format: "%.1f MB/s", bytesPerSec / (1024 * 1024)) }
        return String(format: "%.2f GB/s", bytesPerSec / (1024 * 1024 * 1024))
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }
}

// MARK: - Sparkline for widget

struct WidgetSparkline: View {
    let values: [Double]
    let color: Color

    var body: some View {
        Canvas { context, size in
            guard values.count > 1 else { return }
            let maxVal = max(values.max() ?? 1, 1)
            let step = size.width / CGFloat(values.count - 1)

            var path = Path()
            for (i, v) in values.enumerated() {
                let x = CGFloat(i) * step
                let y = size.height - (CGFloat(v / maxVal) * size.height)
                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
            }

            context.stroke(path, with: .color(color), lineWidth: 1.5)

            var fill = path
            fill.addLine(to: CGPoint(x: size.width, y: size.height))
            fill.addLine(to: CGPoint(x: 0, y: size.height))
            fill.closeSubpath()
            context.fill(fill, with: .color(color.opacity(0.2)))
        }
    }
}

// MARK: - Widget declaration

struct SystemMetricWidget: Widget {
    let kind = "SystemMetricWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: MetricSelectionIntent.self,
            provider: SystemMetricProvider()
        ) { entry in
            SystemMetricWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("System Monitor")
        .description("Shows live CPU, Memory, Network, or Disk usage.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
