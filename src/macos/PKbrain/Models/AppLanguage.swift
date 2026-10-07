import Foundation

enum AppLanguage: String, CaseIterable, Codable, Identifiable {
    case english = "en"
    case french = "fr"
    case italian = "it"
    case german = "de"
    case spanish = "es"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: "English"
        case .french: "Français"
        case .italian: "Italiano"
        case .german: "Deutsch"
        case .spanish: "Español"
        }
    }

    /// Drapeau pour les boutons de langue de la sidebar Réglages
    /// (pattern pk-settings-shell).
    var flagEmoji: String {
        switch self {
        case .english: "🇬🇧"
        case .french: "🇫🇷"
        case .italian: "🇮🇹"
        case .german: "🇩🇪"
        case .spanish: "🇪🇸"
        }
    }

    /// Langue effective : celle du LocalizationController (tenue à jour par
    /// AppSettings.applyLanguagePreference), avec repli anglais.
    static var current: AppLanguage {
        AppLanguage(rawValue: LocalizationController.shared.languageCode) ?? .english
    }

    var localizedName: String {
        switch self {
        case .english: "English"
        case .french: "Français"
        case .italian: "Italiano"
        case .german: "Deutsch"
        case .spanish: "Español"
        }
    }

    var locale: Locale {
        Locale(identifier: rawValue)
    }
}
