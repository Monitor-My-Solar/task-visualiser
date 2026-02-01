import SwiftUI

enum SidebarTab: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case cpu = "CPU"
    case memory = "Memory"
    case gpu = "GPU"
    case network = "Network"
    case disk = "Disk"
    case battery = "Energy"
    case thermal = "Thermal"
    case processes = "Processes"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: "square.grid.2x2"
        case .cpu: "cpu"
        case .memory: "memorychip"
        case .gpu: "display"
        case .network: "network"
        case .disk: "internaldrive"
        case .battery: "bolt.fill"
        case .thermal: "thermometer.medium"
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
