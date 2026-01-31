import WidgetKit
import AppIntents

struct MetricSelectionIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "System Metric" }
    static var description: IntentDescription { "Choose which system metric to display." }

    @Parameter(title: "Metric", default: .cpu)
    var metric: MetricType
}

enum MetricType: String, AppEnum {
    case cpu = "CPU"
    case memory = "Memory"
    case network = "Network"
    case disk = "Disk"

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Metric" }

    static var caseDisplayRepresentations: [MetricType: DisplayRepresentation] {
        [
            .cpu: "CPU",
            .memory: "Memory",
            .network: "Network",
            .disk: "Disk"
        ]
    }
}
