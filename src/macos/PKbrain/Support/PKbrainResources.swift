import Foundation

enum PKbrainResources {
    static let bundle: Bundle = {
        let resourcesURL = Bundle.main.resourceURL ?? Bundle.main.bundleURL
        return Bundle(url: resourcesURL.appendingPathComponent("PKbrain_PKbrain.bundle")) ?? .main
    }()
}

/// CalVer version (YYYY.MM.PATCH). Source de vérité : CHANGELOG.md, injecté
/// dans CFBundleShortVersionString par les scripts de build ; la ressource
/// VERSION embarquée n'est qu'un repli (exécution du binaire nu).
enum AppVersion {
    static let current: String = {
        if let info = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           !info.isEmpty {
            return info
        }
        if let url = PKbrainResources.bundle.url(forResource: "VERSION", withExtension: nil),
           let text = try? String(contentsOf: url, encoding: .utf8) {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }
        return "dev"
    }()
}
