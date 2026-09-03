import Foundation

enum PKbrainResources {
    static let bundle: Bundle = {
        let resourcesURL = Bundle.main.resourceURL ?? Bundle.main.bundleURL
        return Bundle(url: resourcesURL.appendingPathComponent("PKbrain_PKbrain.bundle")) ?? .main
    }()
}
