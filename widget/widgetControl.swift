import AppIntents
import SwiftUI
import WidgetKit

#if os(iOS)
struct SystemStatusControl: ControlWidget {
    static let kind = "com.monitormysolar.Task-Visualiser.systemStatus"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: RefreshMetricsIntent()) {
                let snapshot = SharedDataStore.load()
                Label {
                    Text("CPU \(String(format: "%.0f%%", snapshot.cpuUsage))")
                } icon: {
                    Image(systemName: "cpu")
                }
            }
        }
        .displayName("System Status")
        .description("Shows current CPU usage. Tap to refresh.")
    }
}
#endif

struct RefreshMetricsIntent: AppIntent {
    static var title: LocalizedStringResource { "Refresh Metrics" }

    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
