// Shims for the native capture harness (`capture-native.swift`).
//
// UpdaterManager.swift links Sparkle (SPUStandardUpdaterController), which cannot be
// compiled with a plain `swiftc` invocation. The capture harness compiles the real
// views, so it only needs the updater surface those views read. Capture-only:
// never part of the app target.
import Foundation
import SwiftUI

enum BrainChannelVersionStatus {
    case updateAvailable, upToDate, installedAhead, otherChannel, unavailable

    var symbol: String {
        switch self {
        case .updateAvailable: "arrow.down.circle.fill"
        case .upToDate: "checkmark.circle.fill"
        case .installedAhead: "arrow.up.circle.fill"
        case .otherChannel: "circle.dashed"
        case .unavailable: "questionmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .updateAvailable: .accentColor
        case .upToDate: .green
        case .installedAhead: .orange
        case .otherChannel, .unavailable: .secondary
        }
    }

    var localizationKey: String {
        switch self {
        case .updateAvailable: "about.statusUpdateAvailable"
        case .upToDate: "about.statusUpToDate"
        case .installedAhead: "about.statusInstalledAhead"
        case .otherChannel: "about.statusOtherChannel"
        case .unavailable: "about.statusUnavailable"
        }
    }
}

final class UpdaterManager: NSObject, ObservableObject {
    static let shared = UpdaterManager()

    @Published var availableUpdateVersion: String?
    @Published var latestStableVersion: String?
    @Published var latestDevVersion: String?

    func versionStatus(for channel: String) -> BrainChannelVersionStatus { .unavailable }
    func checkForUpdates() {}
    func refreshAvailableVersions() {}
}
