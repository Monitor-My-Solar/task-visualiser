import Foundation
import SwiftUI

@Observable
final class UpdaterService {
    private(set) var latestRelease: GitHubRelease?
    private(set) var isChecking = false
    private(set) var lastChecked: Date?
    private(set) var lastError: String?

    var updateAvailable: Bool {
        guard let release = latestRelease,
              let remote = release.version,
              let local = SemanticVersion.current else {
            return false
        }
        return remote > local
    }

    var showUpdateAlert = false

    @ObservationIgnored @AppStorage("autoCheckForUpdates") var autoCheckForUpdates = true
    @ObservationIgnored @AppStorage("lastSkippedVersion") var lastSkippedVersion = ""

    private var periodicTask: Task<Void, Never>?
    private static let checkInterval: TimeInterval = 6 * 60 * 60 // 6 hours
    private static let apiURL = URL(string: "https://api.github.com/repos/Monitor-My-Solar/task-visualiser/releases/latest")!

    func startPeriodicChecks() {
        guard periodicTask == nil else { return }

        if autoCheckForUpdates {
            Task { await checkForUpdates(userInitiated: false) }
        }

        periodicTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Self.checkInterval))
                guard let self, self.autoCheckForUpdates else { continue }
                await self.checkForUpdates(userInitiated: false)
            }
        }
    }

    func stopPeriodicChecks() {
        periodicTask?.cancel()
        periodicTask = nil
    }

    @MainActor
    func checkForUpdates(userInitiated: Bool) async {
        guard !isChecking else { return }
        isChecking = true
        lastError = nil

        defer { isChecking = false }

        do {
            var request = URLRequest(url: Self.apiURL)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                lastError = "Invalid response"
                return
            }

            guard httpResponse.statusCode == 200 else {
                lastError = "GitHub API returned \(httpResponse.statusCode)"
                return
            }

            let decoder = JSONDecoder()
            let release = try decoder.decode(GitHubRelease.self, from: data)

            latestRelease = release
            lastChecked = Date()

            if let remote = release.version, let local = SemanticVersion.current, remote > local {
                if userInitiated || lastSkippedVersion != release.tagName {
                    showUpdateAlert = true
                }
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func skipVersion() {
        if let tag = latestRelease?.tagName {
            lastSkippedVersion = tag
        }
        showUpdateAlert = false
    }

    func dismissUpdate() {
        showUpdateAlert = false
    }

    func openDownloadPage() {
        guard let url = latestRelease?.downloadURL else { return }
        NSWorkspace.shared.open(url)
    }
}
