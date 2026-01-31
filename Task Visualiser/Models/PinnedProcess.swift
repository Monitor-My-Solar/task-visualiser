import Foundation

struct PinnedProcess: Codable, Identifiable, Hashable {
    var id: String { identifier }
    let identifier: String
    let displayName: String
}
