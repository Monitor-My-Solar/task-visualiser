import Foundation

struct GitHubRelease: Codable {
    let tagName: String
    let name: String?
    let body: String?
    let htmlUrl: String
    let publishedAt: String?
    let assets: [Asset]

    struct Asset: Codable {
        let name: String
        let browserDownloadUrl: String
        let size: Int

        enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadUrl = "browser_download_url"
            case size
        }
    }

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case htmlUrl = "html_url"
        case publishedAt = "published_at"
        case assets
    }

    var version: SemanticVersion? {
        SemanticVersion(string: tagName)
    }

    var dmgAsset: Asset? {
        assets.first { $0.name.hasSuffix(".dmg") }
    }

    var downloadURL: URL? {
        if let dmg = dmgAsset {
            return URL(string: dmg.browserDownloadUrl)
        }
        return URL(string: htmlUrl)
    }
}
