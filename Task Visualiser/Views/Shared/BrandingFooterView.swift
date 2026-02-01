import SwiftUI

struct BrandingFooterView: View {
    var compact: Bool = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        if compact {
            compactLayout
        } else {
            fullLayout
        }
    }

    private var compactLayout: some View {
        VStack(spacing: 2) {
            Text("Monitor My Solar")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Link(destination: URL(string: "https://github.com/MonitorMySolar/Task-Visualiser")!) {
                Text("v\(appVersion)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var fullLayout: some View {
        HStack(spacing: 6) {
            Text("Monitor My Solar")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("v\(appVersion)")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
            Link(destination: URL(string: "https://github.com/MonitorMySolar/Task-Visualiser")!) {
                Image(systemName: "link")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
