import SwiftUI

struct UpdateAlertView: View {
    @Environment(UpdaterService.self) private var updaterService

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.down.app")
                .font(.system(size: 40))
                .foregroundStyle(.tint)

            Text("Update Available")
                .font(.title2.bold())

            if let release = updaterService.latestRelease {
                Text("Version \(release.tagName) is available")
                    .foregroundStyle(.secondary)

                if let body = release.body, !body.isEmpty {
                    ScrollView {
                        Text(body)
                            .font(.body)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 200)
                    .padding(8)
                    .background(.quaternary.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                if let asset = release.dmgAsset {
                    Text(ByteCountFormatter.string(fromByteCount: Int64(asset.size), countStyle: .file))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                Button("Later") {
                    updaterService.dismissUpdate()
                }
                .keyboardShortcut(.cancelAction)

                Button("Skip This Version") {
                    updaterService.skipVersion()
                }

                Button("Download Update") {
                    updaterService.openDownloadPage()
                    updaterService.dismissUpdate()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}
