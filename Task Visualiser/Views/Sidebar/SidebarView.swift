import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarTab?
    @Environment(SystemMonitorService.self) private var monitorService

    private var visibleTabs: [SidebarTab] {
        SidebarTab.allCases.filter { tab in
            if tab == .battery { return monitorService.currentStats.battery.isPresent }
            return true
        }
    }

    var body: some View {
        List(visibleTabs, selection: $selection) { tab in
            Label(tab.rawValue, systemImage: tab.icon)
                .tag(tab)
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 160, ideal: 200)
        .safeAreaInset(edge: .bottom) {
            BrandingFooterView()
                .background(.bar)
        }
    }
}
