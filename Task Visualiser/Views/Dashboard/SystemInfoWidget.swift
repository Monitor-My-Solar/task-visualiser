import SwiftUI

struct SystemInfoWidget: View {
    var body: some View {
        HStack(spacing: 0) {
            infoItem(icon: "desktopcomputer", label: "Hostname", value: SysctlHelpers.hostname())
            Divider().frame(height: 40).padding(.horizontal, 8)
            infoItem(icon: "gear", label: "OS", value: SysctlHelpers.osVersion())
            Divider().frame(height: 40).padding(.horizontal, 8)
            infoItem(icon: "cpu", label: "CPU", value: shortCPUName())
            Divider().frame(height: 40).padding(.horizontal, 8)
            infoItem(icon: "clock", label: "Uptime", value: SysctlHelpers.formattedUptime())
            Divider().frame(height: 40).padding(.horizontal, 8)
            infoItem(icon: "cpu", label: "Cores", value: "\(SysctlHelpers.physicalCores())P / \(SysctlHelpers.logicalCores())L")
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func infoItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.caption, design: .rounded, weight: .semibold))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private func shortCPUName() -> String {
        let brand = SysctlHelpers.cpuBrand()
        if let range = brand.range(of: "Apple ") {
            return String(brand[range.upperBound...])
        }
        return brand
    }
}
