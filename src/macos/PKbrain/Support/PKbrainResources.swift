import Foundation

enum PKbrainResources {
    static let bundle: Bundle = {
        let resourcesURL = Bundle.main.resourceURL ?? Bundle.main.bundleURL
        return Bundle(url: resourcesURL.appendingPathComponent("PKbrain_PKbrain.bundle")) ?? .main
    }()
}

/// CalVer version (YYYY.MM.PATCH). Source of truth: the VERSION file at the
/// repo root, bundled as a resource at build time.
enum AppVersion {
    static let current: String = {
        if let url = PKbrainResources.bundle.url(forResource: "VERSION", withExtension: nil),
           let text = try? String(contentsOf: url, encoding: .utf8) {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }
        return "dev"
    }()
}
