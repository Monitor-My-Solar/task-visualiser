import SwiftUI

enum SidebarTab: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case cpu = "CPU"
    case memory = "Memory"
    case network = "Network"
    case disk = "Disk"
    case battery = "Battery"
    case processes = "Processes"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: "square.grid.2x2"
        case .cpu: "cpu"
        case .memory: "memorychip"
        case .network: "network"
        case .disk: "internaldrive"
        case .battery: "battery.100percent"
        case .processes: "list.bullet.rectangle"
        }
    }
}

@Observable
final class AppState {
    var selectedTab: SidebarTab? = .dashboard
    var refreshInterval: TimeInterval = 1.0
    var historyDuration: TimeInterval = 600.0
    @ObservationIgnored @AppStorage("showMenuBarExtra") var showMenuBarExtra: Bool = true

    var isSandboxed: Bool {
        SandboxDetector.isSandboxed
    }
}
