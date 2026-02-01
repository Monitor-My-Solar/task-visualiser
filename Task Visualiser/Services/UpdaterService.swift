import Foundation
import SwiftUI

@Observable
final class UpdaterService {
    private(set) var latestRelease: GitHubRelease?
    private(set) var isChecking = false
    private(set) var lastChecked: Date?
    private(set) var lastError: String?

    private(set) var isDownloading = false
    private(set) var downloadProgress: Double = 0
    private(set) var isInstalling = false
    private(set) var installError: String?

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
    private var downloadTask: Task<Void, Never>?
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

    // MARK: - In-App Update

    @MainActor
    func downloadAndInstall() {
        guard !isDownloading, !isInstalling else { return }
        guard let asset = latestRelease?.dmgAsset,
              let url = URL(string: asset.browserDownloadUrl) else {
            installError = "No DMG asset found in release"
            return
        }

        isDownloading = true
        downloadProgress = 0
        installError = nil

        downloadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let dmgPath = try await self.downloadDMG(from: url)
                await MainActor.run { self.isDownloading = false; self.isInstalling = true }
                try self.installFromDMG(at: dmgPath)
            } catch is CancellationError {
                await MainActor.run {
                    self.isDownloading = false
                    self.isInstalling = false
                }
            } catch {
                await MainActor.run {
                    self.isDownloading = false
                    self.isInstalling = false
                    self.installError = error.localizedDescription
                }
            }
        }
    }

    private func downloadDMG(from url: URL) async throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let destination = tempDir.appendingPathComponent("TaskVisualiser-update.dmg")

        // Remove any previous download
        try? FileManager.default.removeItem(at: destination)

        let (asyncBytes, response) = try await URLSession.shared.bytes(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw UpdateError.downloadFailed
        }

        let expectedLength = response.expectedContentLength
        var data = Data()
        if expectedLength > 0 {
            data.reserveCapacity(Int(expectedLength))
        }

        var downloaded: Int64 = 0
        for try await byte in asyncBytes {
            data.append(byte)
            downloaded += 1
            if expectedLength > 0 && downloaded % 65536 == 0 {
                let progress = Double(downloaded) / Double(expectedLength)
                await MainActor.run { self.downloadProgress = progress }
            }
        }
        await MainActor.run { self.downloadProgress = 1.0 }

        try data.write(to: destination)
        return destination
    }

    private func installFromDMG(at dmgPath: URL) throws {
        // If sandboxed, open the DMG in Finder instead
        if SandboxDetector.isSandboxed {
            NSWorkspace.shared.open(dmgPath)
            DispatchQueue.main.async {
                self.isInstalling = false
                self.showUpdateAlert = false
            }
            return
        }

        // Mount the DMG
        let mountPoint = FileManager.default.temporaryDirectory.appendingPathComponent("TaskVisualiser-mount")
        try? FileManager.default.removeItem(at: mountPoint)
        try FileManager.default.createDirectory(at: mountPoint, withIntermediateDirectories: true)

        let mountProcess = Process()
        mountProcess.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        mountProcess.arguments = ["attach", dmgPath.path, "-mountpoint", mountPoint.path, "-nobrowse", "-quiet"]
        try mountProcess.run()
        mountProcess.waitUntilExit()

        guard mountProcess.terminationStatus == 0 else {
            throw UpdateError.mountFailed
        }

        defer {
            // Unmount and clean up
            let detach = Process()
            detach.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
            detach.arguments = ["detach", mountPoint.path, "-quiet", "-force"]
            try? detach.run()
            detach.waitUntilExit()
            try? FileManager.default.removeItem(at: dmgPath)
        }

        // Find the .app in the mounted volume
        let contents = try FileManager.default.contentsOfDirectory(at: mountPoint, includingPropertiesForKeys: nil)
        guard let appBundle = contents.first(where: { $0.pathExtension == "app" }) else {
            throw UpdateError.appNotFound
        }

        // Get the path of the currently running app
        let currentAppPath = Bundle.main.bundlePath

        // Stage the new app to a temp location
        let stagedApp = FileManager.default.temporaryDirectory.appendingPathComponent("TaskVisualiser-staged.app")
        try? FileManager.default.removeItem(at: stagedApp)
        try FileManager.default.copyItem(at: appBundle, to: stagedApp)

        // Create a shell script to replace and relaunch
        let pid = ProcessInfo.processInfo.processIdentifier
        let script = """
        #!/bin/bash
        # Wait for the current app to exit
        while kill -0 \(pid) 2>/dev/null; do sleep 0.2; done
        # Replace the app
        rm -rf "\(currentAppPath)"
        cp -R "\(stagedApp.path)" "\(currentAppPath)"
        # Clean up staged app
        rm -rf "\(stagedApp.path)"
        # Relaunch
        open "\(currentAppPath)"
        """

        let scriptPath = FileManager.default.temporaryDirectory.appendingPathComponent("task-visualiser-update.sh")
        try script.write(to: scriptPath, atomically: true, encoding: .utf8)

        // Make it executable and run it
        let chmod = Process()
        chmod.executableURL = URL(fileURLWithPath: "/bin/chmod")
        chmod.arguments = ["+x", scriptPath.path]
        try chmod.run()
        chmod.waitUntilExit()

        let launcher = Process()
        launcher.executableURL = URL(fileURLWithPath: "/bin/bash")
        launcher.arguments = [scriptPath.path]
        launcher.standardOutput = FileHandle.nullDevice
        launcher.standardError = FileHandle.nullDevice
        try launcher.run()

        // Quit the current app so the script can replace it
        DispatchQueue.main.async {
            NSApplication.shared.terminate(nil)
        }
    }

    enum UpdateError: LocalizedError {
        case downloadFailed
        case mountFailed
        case appNotFound

        var errorDescription: String? {
            switch self {
            case .downloadFailed: "Failed to download the update"
            case .mountFailed: "Failed to mount the update disk image"
            case .appNotFound: "Could not find the application in the update"
            }
        }
    }
}
