import Foundation

enum SandboxDetector {
    static let isSandboxed: Bool = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return home.contains("/Library/Containers/")
    }()
}
