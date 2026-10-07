//
//  PKSettingsViews.swift
//  PKbrain
//
//  Shell de réglages commun aux apps PK — port fidèle du pattern PKmonitor
//  (voir la skill pk-settings-shell) : sidebar 220 pt sur .regularMaterial,
//  recherche profonde avec surlignage, groupes localisés, drapeaux de langue,
//  version en pied ; pages partagées About (versions Stable/Dev + crédits),
//  Support (Ko-fi) et Project Library.
//

import AppKit
import SwiftUI

// MARK: - Notifications

extension Notification.Name {
    /// Demande à la fenêtre Réglages (si ouverte) d'afficher une section précise.
    static let pkSelectSettingsSection = Notification.Name("PKSelectSettingsSection")
    /// La langue de l'app a changé (drapeaux de la sidebar, picker Général).
    static let appLanguageDidChange = Notification.Name("PKAppLanguageDidChange")
    /// Demande à surligner un réglage précis (titre exact localisé du réglage).
    static let pkHighlightSetting = Notification.Name("PKHighlightSetting")
}

// MARK: - Sections

/// Sections de la sidebar. `rawValue` = identifiant stable anglais (recherche,
/// notifications) ; l'affichage passe par `title` localisé.
enum PKSettingsSection: String, CaseIterable, Identifiable {
    case general = "General"
    case shortcuts = "Shortcuts"
    case lab = "Lab"
    case stickies = "Stickies"
    case clipboard = "PKClipboard"
    case drawer = "Drawer"
    case library = "Project Library"
    case support = "Help & Support"
    case about = "About"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: "gearshape"
        case .shortcuts: "keyboard"
        case .lab: "flask"
        case .stickies: "note.text"
        case .clipboard: "clipboard"
        case .drawer: "rectangle.bottomthird.inset.filled"
        case .library: "square.grid.2x2"
        case .support: "heart.fill"
        case .about: "info.circle"
        }
    }

    /// Titre affiché, localisé (rawValue reste l'identifiant stable).
    var title: String {
        switch self {
        case .general: localizedString("sidebar.general")
        case .shortcuts: localizedString("sidebar.shortcuts")
        case .lab: localizedString("sidebar.lab")
        case .stickies: localizedString("sidebar.stickies")
        case .clipboard: localizedString("sidebar.clipboard")
        case .drawer: localizedString("sidebar.drawer")
        case .library: localizedString("sidebar.library")
        case .support: localizedString("sidebar.support")
        case .about: localizedString("sidebar.about")
        }
    }

    var category: String {
        switch self {
        case .general, .shortcuts, .lab: "APP"
        case .stickies, .clipboard, .drawer: "NOTES"
        case .library, .support, .about: "PK PROJECTS"
        }
    }

    var groupKey: String {
        switch category {
        case "APP": "group.app"
        case "NOTES": "group.notes"
        default: "group.projects"
        }
    }

    /// Couleur d'icône dans la sidebar : Support (rouge Ko-fi) et About
    /// (accent) se détachent en couleur, comme le don Ko-fi du menu.
    var iconTint: Color? {
        switch self {
        case .support: Color(red: 1.0, green: 0.37, blue: 0.36)
        case .about: .accentColor
        default: nil
        }
    }

    var keywords: String {
        let extra: String
        switch self {
        case .general: extra = "language langue storage stockage backup sauvegarde accessibility ocr import export general"
        case .shortcuts: extra = "shortcuts raccourcis clavier keyboard hotkeys global"
        case .lab: extra = "lab labo plugins communauté expérimental"
        case .stickies: extra = "stickies post-it notes typing effets calcul inline"
        case .clipboard: extra = "clipboard presse-papiers history historique capture items"
        case .drawer: extra = "drawer tiroir edge bord position"
        case .about: extra = "about à propos versions updates crédits credits"
        default: extra = ""
        }
        return "\(rawValue) \(category) \(extra)".lowercased()
    }
}

// MARK: - Liens partagés

enum ProjectLinks {
    static let github = URL(string: "https://github.com/mondary/PKbrain")!
    static let issues = URL(string: "https://github.com/mondary/PKbrain/issues")!
    static let githubProfile = URL(string: "https://github.com/mondary")!
    static let koFi = URL(string: "https://ko-fi.com/pouark")!
    static let jorts = URL(string: "https://github.com/elly-code/jorts")!
}

// MARK: - Recherche profonde

/// Une entrée de la recherche profonde des Réglages : un réglage individuel
/// rattaché à sa section. `settingKey` est une clé de localisation (stable) :
/// le titre affiché ET l'identifiant de surlignage sont résolus au runtime via
/// `localizedString(settingKey)` pour rester localisés dans les 5 langues.
struct SettingsSearchEntry: Identifiable {
    let settingKey: String
    let section: PKSettingsSection
    let keywords: String
    var id: String { "\(section.rawValue)/\(settingKey)" }
    var localizedTitle: String { localizedString(settingKey) }
}

/// Index statique des réglages recherchables. « sauvegarde » ou « ocr »
/// amène au bon réglage avec surlignage, etc.
enum PKSettingsSearch {
    private static let entries: [SettingsSearchEntry] = [
        // General
        .init(settingKey: "language", section: .general, keywords: "language langue change changer system système restart"),
        .init(settingKey: "accessibility", section: .general, keywords: "accessibility accessibilité permission ax trusted autorisation"),
        .init(settingKey: "storage", section: .general, keywords: "storage stockage dossier directory chemin path data données"),
        .init(settingKey: "new_notes", section: .general, keywords: "new notes nouvelles notes position randomize edge bords post-it typing effets"),
        .init(settingKey: "clipboard", section: .general, keywords: "clipboard presse-papiers position tiroir drawer sons sounds copy paste"),
        .init(settingKey: "ocr_card_title", section: .general, keywords: "ocr screenshot capture reconnaissance texte output sortie"),
        .init(settingKey: "import_export", section: .general, keywords: "import export importer exporter json notes saved state"),
        .init(settingKey: "backup", section: .general, keywords: "backup sauvegarde auto automatique folder dossier interval"),
        .init(settingKey: "cleanup", section: .general, keywords: "cleanup nettoyage archive legacy anciens duplicates"),
        // PKClipboard
        .init(settingKey: "capture_active", section: .clipboard, keywords: "capture active actif pause history historique"),
        .init(settingKey: "max_items", section: .clipboard, keywords: "max items éléments limite nombre historique"),
        .init(settingKey: "max_age_days", section: .clipboard, keywords: "max age jours durée retention rétention"),
        .init(settingKey: "source_privacy_mode", section: .clipboard, keywords: "source privacy mode privé allow block liste apps applications"),
        .init(settingKey: "data_backup_full", section: .clipboard, keywords: "backup full complète export restore restaurer données"),
        // Drawer
        .init(settingKey: "drawer_position", section: .drawer, keywords: "drawer tiroir position edge bord haut bas gauche droite"),
        // Stickies
        .init(settingKey: "randomize_new_note_position", section: .stickies, keywords: "randomize aléatoire position nouvelles notes"),
        .init(settingKey: "show_results_while_typing", section: .stickies, keywords: "inline calculs calculations results résultats typing frappe"),
        .init(settingKey: "show_brand_icons_while_typing", section: .stickies, keywords: "brand icons icônes marques logo typing frappe"),
        // Shortcuts
        .init(settingKey: "shortcuts", section: .shortcuts, keywords: "shortcuts raccourcis clavier keyboard global hotkeys"),
        // Lab
        .init(settingKey: "community_plugins", section: .lab, keywords: "plugins communauté community template dossier folder"),
        // About
        .init(settingKey: "about.updates", section: .about, keywords: "updates mises à jour canal channel stable dev versions sparkle"),
        .init(settingKey: "about.credits", section: .about, keywords: "credits crédits inspirations jorts numara pastepal open source"),
    ]

    static func match(_ query: String) -> [SettingsSearchEntry] {
        let words = query.split(separator: " ").map(String.init)
        return entries.filter { entry in
            let haystack = "\(entry.localizedTitle) \(entry.section.title) \(entry.keywords)".lowercased()
            return words.allSatisfy { haystack.contains($0) }
        }
    }
}

/// Surlignage temporaire d'un réglage dont le titre localisé correspond
/// à l'entrée choisie dans la recherche : fond accent qui s'estompe.
struct SettingHighlight: ViewModifier {
    let title: String
    @State private var flash = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(flash ? Color.accentColor.opacity(0.25) : .clear)
            )
            .onReceive(NotificationCenter.default.publisher(for: .pkHighlightSetting)) { note in
                guard let target = note.object as? String, target == title else { return }
                withAnimation(.easeIn(duration: 0.12)) { flash = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                    withAnimation(.easeOut(duration: 0.7)) { flash = false }
                }
            }
    }
}

// MARK: - Icônes & assets partagés

@MainActor
enum PKAppIcon {
    private static var cache: [Int: NSImage] = [:]

    static func image(side: CGFloat) -> NSImage {
        let pixels = max(16, Int(side * 2))
        if let cached = cache[pixels] { return cached }
        let source = NSImage(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "PKbrain", ofType: "icns") ?? ""))
            ?? NSApp.applicationIconImage
            ?? NSImage()
        let image = NSImage(size: NSSize(width: pixels, height: pixels))
        image.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        source.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels), from: .zero, operation: .sourceOver, fraction: 1.0)
        image.unlockFocus()
        cache[pixels] = image
        return image
    }
}

/// Icône d'un projet PK (Resources/ProjectIcons/<name>.png dans le bundle
/// de ressources SPM), avec repli sur l'icône de l'app.
struct ProjectIconView: View {
    let name: String

    var body: some View {
        if let image = Self.load(name: name) {
            Image(nsImage: image).resizable().interpolation(.high).scaledToFit()
        } else {
            Image(nsImage: PKAppIcon.image(side: 64))
                .resizable().scaledToFit()
        }
    }

    static func load(name: String) -> NSImage? {
        guard let directory = PKbrainResources.bundle.url(forResource: "ProjectIcons", withExtension: nil) else {
            return nil
        }
        return NSImage(contentsOf: directory.appendingPathComponent("\(name).png"))
    }
}

/// Capture d'écran d'un projet PK (Resources/ProjectScreenshots/<name>.png).
enum ProjectScreenshot {
    static func load(name: String) -> NSImage? {
        guard let directory = PKbrainResources.bundle.url(forResource: "ProjectScreenshots", withExtension: nil) else {
            return nil
        }
        return NSImage(contentsOf: directory.appendingPathComponent("\(name).png"))
    }
}

/// Logo Ko-fi embarqué (Resources/kofi-logo.png dans le bundle SPM).
enum KofiLogo {
    static var image: NSImage? {
        PKbrainResources.bundle.url(forResource: "kofi-logo", withExtension: "png")
            .flatMap(NSImage.init(contentsOf:))
    }
}

// MARK: - En-tête de page (pattern PKmonitor)

struct SettingsHeader: View {
    let title: String
    let subtitle: String
    var icon: String = "gearshape"

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 34, height: 34)
                        .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    Text(title).font(.system(size: 28, weight: .bold, design: .rounded))
                }
                Text(subtitle).font(.system(size: 13)).foregroundStyle(.secondary)
                    .padding(.leading, 44)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }
}

// MARK: - Ligne de lien réutilisable (Support + crédits)

struct PKLinkRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let url: URL

    var body: some View {
        Link(destination: url) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - À propos

struct AboutSettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject private var updater = UpdaterManager.shared
    @State private var language: AppLanguage

    init(settings: AppSettings) {
        self.settings = settings
        _language = State(initialValue: settings.selectedLanguage)
    }

    private var version: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String).flatMap { $0.isEmpty ? nil : $0 }
            ?? AppVersion.current
    }

    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }

    private var isDevBuild: Bool {
        version.localizedCaseInsensitiveContains("-dev")
    }

    private var effectiveUpdateChannel: String {
        isDevBuild ? "dev" : settings.updateChannel
    }

    private var updateChannelSelection: Binding<String> {
        Binding(
            get: { effectiveUpdateChannel },
            set: { if !isDevBuild { settings.updateChannel = $0 } }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    Image(nsImage: PKAppIcon.image(side: 88))
                        .resizable().interpolation(.high)
                        .frame(width: 88, height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 1))
                        .shadow(color: .black.opacity(0.3), radius: 12, y: 8)
                        .padding(.top, 36)
                        .padding(.bottom, 16)

                    Text("PKbrain").font(.system(size: 24, weight: .bold))
                    Text("\(localizedString("about.installedVersion")) \(version) (\(build))")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                    Text(localizedString("about.byPK"))
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                        .padding(.bottom, 32)

                    aboutText
                        .frame(maxWidth: 480)
                        .padding(.bottom, 32)

                    creditsSection
                        .frame(maxWidth: 480)
                        .padding(.bottom, 32)

                }
                .frame(maxWidth: .infinity)
            }

            Divider()

            updateSection
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

            Divider()

            footer
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            language = settings.selectedLanguage
            updater.refreshAvailableVersions()
        }
        .onReceive(NotificationCenter.default.publisher(for: .appLanguageDidChange)) { _ in
            language = settings.selectedLanguage
        }
    }

    /// Crédits des projets sur lesquels PKbrain est construit ou dont il
    /// s'inspire (pattern Pulse : chaque inspiration est nommée et liée).
    private var creditsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localizedString("about.credits"))
                .font(.headline)
                .modifier(SettingHighlight(title: localizedString("about.credits")))

            VStack(spacing: 0) {
                PKLinkRow(icon: "note.text", title: "Jorts", subtitle: localizedString("credits.jorts"), url: ProjectLinks.jorts)
                Divider().padding(.leading, 52)
                PKLinkRow(icon: "plus.forwardslash.minus", title: "Numara Calculator", subtitle: localizedString("credits.numara"), url: URL(string: "https://github.com/bornova/numara-calculator")!)
                Divider().padding(.leading, 52)
                PKLinkRow(icon: "function", title: "Caligator", subtitle: localizedString("credits.caligator"), url: URL(string: "https://github.com/teamxenox/caligator")!)
                Divider().padding(.leading, 52)
                PKLinkRow(icon: "paintbrush", title: "developer-icons", subtitle: localizedString("credits.devicons"), url: URL(string: "https://github.com/xandemon/developer-icons")!)
                Divider().padding(.leading, 52)
                PKLinkRow(icon: "macwindow", title: "PastePal", subtitle: localizedString("credits.pastepal"), url: URL(string: "https://pasteapp.org")!)
            }
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(localizedString("credits.note"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.primary.opacity(0.025)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.08), lineWidth: 1))
    }

    /// Gestion des mises à jour collée au À propos (pattern PKmonitor) :
    /// canal Stable/Dev, dernières versions publiées, vérification manuelle.
    private var updateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localizedString("about.updates"))
                .font(.headline)
                .modifier(SettingHighlight(title: localizedString("about.updates")))

            HStack(spacing: 10) {
                versionColumn(
                    title: localizedString("about.stableVersion"),
                    value: updater.latestStableVersion ?? localizedString("about.notPublished"),
                    status: updater.versionStatus(for: "stable")
                )
                versionColumn(
                    title: localizedString("about.devVersion"),
                    value: updater.latestDevVersion ?? localizedString("about.notPublished"),
                    status: updater.versionStatus(for: "dev")
                )
            }

            HStack(spacing: 12) {
                Picker(localizedString("about.updateChannel"), selection: updateChannelSelection) {
                    Text("Stable").tag("stable")
                    Text("Dev").tag("dev")
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .accessibilityLabel(localizedString("about.updateChannel"))
                .frame(width: 190)
                .disabled(isDevBuild)
                Spacer(minLength: 0)
                Button { updater.checkForUpdates() } label: {
                    Label(updateButtonTitle, systemImage: updater.availableUpdateVersion == nil
                        ? "arrow.triangle.2.circlepath"
                        : "arrow.down.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }

            Text(effectiveUpdateChannel == "dev"
                 ? localizedString("about.channelDevCaption")
                 : localizedString("about.channelStableCaption"))
                .font(.caption)
                .foregroundStyle(.secondary)

        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.primary.opacity(0.025)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.08), lineWidth: 1))
    }

    private var updateButtonTitle: String {
        guard let available = updater.availableUpdateVersion else { return localizedString("about.checkForUpdates") }
        return String(format: localizedString("about.installVersion"), available)
    }

    private func versionColumn(title: String, value: String, status: BrainChannelVersionStatus) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary).lineLimit(1)
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .help(value)
            Label(localizedString(status.localizationKey), systemImage: status.symbol)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(status.color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var aboutText: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(localizedString("about.greeting"))
                .italic()
                .font(.system(size: 13))

            Text(localizedString("about.pitch"))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            Text(localizedString("about.body"))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            Text(localizedString("about.care"))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            Text(localizedString("about.thanks"))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            Text("— PK")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
    }

    private var footer: some View {
        HStack(alignment: .center, spacing: 16) {
            Link(destination: ProjectLinks.github) {
                Label("GitHub", systemImage: "network")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Link(destination: ProjectLinks.issues) {
                Label("Issues", systemImage: "exclamationmark.bubble")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Link(destination: ProjectLinks.koFi) {
                HStack(spacing: 4) {
                    if let logo = KofiLogo.image {
                        Image(nsImage: logo)
                            .resizable()
                            .frame(width: 12, height: 12)
                    }
                    Text(localizedString("footer.supportOnKofi"))
                }
                .font(.caption)
                .foregroundStyle(Color(red: 1.0, green: 0.37, blue: 0.36))
            }
            Spacer()
            Text("macOS 13+")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Support (Ko-fi)

struct SupportSettingsView: View {
    @State private var language = AppLanguage.current

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .padding(.top, 36)
                    .padding(.bottom, 24)

                VStack(spacing: 16) {
                    coffeeCard
                    linksCard
                }
                .frame(maxWidth: 480)
                .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity)
        }
        .onAppear { language = AppLanguage.current }
        .onReceive(NotificationCenter.default.publisher(for: .appLanguageDidChange)) { _ in
            language = AppLanguage.current
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "heart.fill")
                .font(.system(size: 36))
                .foregroundStyle(.red)

            Text(localizedString("support.title"))
                .font(.system(size: 20, weight: .bold))

            Text(localizedString("support.subtitle"))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var coffeeCard: some View {
        HStack(spacing: 12) {
            Group {
                if let logo = KofiLogo.image {
                    Image(nsImage: logo).resizable().interpolation(.high)
                } else {
                    Image(systemName: "cup.and.saucer.fill").font(.system(size: 22))
                }
            }
            .frame(width: 28, height: 28)
            .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text("Ko-fi")
                    .font(.system(size: 14, weight: .semibold))
                Text(localizedString("support.kofi.subtitle"))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Link(destination: ProjectLinks.koFi) {
                Text(localizedString("support.donate"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color(red: 1.0, green: 0.37, blue: 0.36))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var linksCard: some View {
        VStack(spacing: 0) {
            PKLinkRow(icon: "network", title: "GitHub", subtitle: localizedString("support.github.subtitle"), url: ProjectLinks.github)
            Divider().padding(.leading, 52)
            PKLinkRow(icon: "exclamationmark.bubble", title: localizedString("support.issues.title"), subtitle: localizedString("support.issues.subtitle"), url: ProjectLinks.issues)
            Divider().padding(.leading, 52)
            PKLinkRow(icon: "chevron.left.slash.chevron.right", title: localizedString("support.original.title"), subtitle: localizedString("support.original.subtitle"), url: ProjectLinks.jorts)
            Divider().padding(.leading, 52)
            PKLinkRow(icon: "person.crop.circle", title: localizedString("support.profile.title"), subtitle: localizedString("support.profile.subtitle"), url: ProjectLinks.githubProfile)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Project Library

struct ProjectLibraryView: View {
    @State private var language = AppLanguage.current

    /// Project Library partagée entre apps PK (même liste que PKmonitor et
    /// PKwindowsManagement) : descriptions et types localisés par clé,
    /// liens GitHub vérifiés (HTTP 200).
    private struct Project: Identifiable {
        let id: String
        let title: String
        let kindKey: String
        let descKey: String
        let iconAsset: String
        let screenshot: String?
        let tintHex: String
        var kind: String { localizedString(kindKey) }
        var description: String { localizedString(descKey) }
        var url: URL { URL(string: "https://github.com/mondary/\(id)")! }
    }

    private let projects = [
        Project(id: "PKbrain", title: "PKbrain", kindKey: "kind.macos", descKey: "desc.PKbrain", iconAsset: "PKbrain", screenshot: "PKbrain", tintHex: "#6366F1"),
        Project(id: "PKmonitor", title: "PKmonitor", kindKey: "kind.macos", descKey: "desc.PKmonitor", iconAsset: "PKmonitor", screenshot: "PKmonitor", tintHex: "#0EA5E9"),
        Project(id: "PKwindowsManagement", title: "PKwindowsManagement", kindKey: "kind.macos", descKey: "desc.PKwindowsManagement", iconAsset: "PKwindowsManagement", screenshot: nil, tintHex: "#F97316"),
        Project(id: "monocode", title: "MonoCode PK", kindKey: "kind.macos", descKey: "desc.MonoCodePK", iconAsset: "MonoCodePK", screenshot: nil, tintHex: "#22D3EE"),
        Project(id: "media-downloader", title: "PKMediaDownloader", kindKey: "kind.macos", descKey: "desc.PKMediaDownloader", iconAsset: "PKMediaDownloader", screenshot: nil, tintHex: "#F43F5E"),
        Project(id: "Macos_PKarchives", title: "PKarchives", kindKey: "kind.macos", descKey: "desc.PKarchives", iconAsset: "PKarchives", screenshot: "PKarchives", tintHex: "#8B5CF6"),
        Project(id: "Macos_PKpowerlines", title: "PKpowerlines", kindKey: "kind.macos", descKey: "desc.PKpowerlines", iconAsset: "PKpowerlines", screenshot: "PKpowerlines", tintHex: "#10B981"),
        Project(id: "PKmac-cleanup", title: "LaunchPad", kindKey: "kind.macos", descKey: "desc.LaunchPad", iconAsset: "PKmac-cleanup", screenshot: nil, tintHex: "#EC4899"),
        Project(id: "Chrome_SimpleGMAIL", title: "PKMail", kindKey: "kind.cross", descKey: "desc.PKMail", iconAsset: "PKMail", screenshot: nil, tintHex: "#EA4335"),
        Project(id: "Chrome_PKshortcuts", title: "PK Chrome Shortcuts", kindKey: "kind.chrome", descKey: "desc.PKChromeShortcuts", iconAsset: "PKshortcuts", screenshot: nil, tintHex: "#F59E0B")
    ]

    private var featured: Project { projects.first { $0.id == "PKbrain" }! }
    private var gridProjects: [Project] { projects.filter { $0.id != "PKbrain" } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SettingsHeader(title: localizedString("library.title"), subtitle: localizedString("library.subtitle"), icon: "square.grid.2x2")
                featuredCard(featured)
                Text(localizedString("library.more")).font(.system(size: 18, weight: .bold, design: .rounded))
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                    ForEach(gridProjects) { project in
                        projectCard(project)
                    }
                }
                Link(destination: ProjectLinks.githubProfile) { Label(localizedString("library.viewAll"), systemImage: "arrow.up.right.square") }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 6)
            }.padding(28)
        }
        .onAppear { language = AppLanguage.current }
        .onReceive(NotificationCenter.default.publisher(for: .appLanguageDidChange)) { _ in
            language = AppLanguage.current
        }
    }

    private func featuredCard(_ project: Project) -> some View {
        Link(destination: project.url) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        ProjectIconView(name: project.iconAsset)
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: .black.opacity(0.18), radius: 5, y: 2)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(project.title).font(.system(size: 24, weight: .bold, design: .rounded))
                            Text(project.kind.uppercased()).font(.system(size: 10, weight: .bold)).foregroundStyle(Color(nsColor: NSColor(hexString: project.tintHex) ?? .controlAccentColor))
                        }
                    }
                    Text(project.description)
                        .font(.system(size: 13)).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(3)
                    Label(localizedString("library.star"), systemImage: "star.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Color.accentColor, in: Capsule())
                }
                .padding(22)
                .frame(maxWidth: 340, alignment: .topLeading)
                if let image = project.screenshot.flatMap(ProjectScreenshot.load) {
                    GeometryReader { geo in
                        Image(nsImage: image)
                            .resizable().interpolation(.high)
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(alignment: .leading) {
                        LinearGradient(colors: [Color(nsColor: .controlBackgroundColor), .clear], startPoint: .leading, endPoint: .trailing)
                            .frame(width: 60)
                    }
                }
            }
            .frame(height: 210)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 0.5))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func projectCard(_ project: Project) -> some View {
        Link(destination: project.url) {
            VStack(alignment: .leading, spacing: 0) {
                Group {
                    if let shot = project.screenshot, let image = ProjectScreenshot.load(name: shot) {
                        Image(nsImage: image)
                            .resizable().interpolation(.high)
                            .scaledToFill()
                            .frame(width: 300, height: 150)
                            .clipped()
                    } else {
                        ZStack {
                            LinearGradient(colors: [Color(nsColor: NSColor(hexString: project.tintHex) ?? .controlAccentColor).opacity(0.75), Color(nsColor: NSColor(hexString: project.tintHex) ?? .controlAccentColor).opacity(0.35)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                            ProjectIconView(name: project.iconAsset)
                                .frame(width: 74, height: 74)
                                .shadow(color: .black.opacity(0.25), radius: 8, y: 3)
                        }
                    }
                }
                .frame(height: 150)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay(alignment: .topLeading) {
                    Text(project.kind.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(10)
                }
                HStack(alignment: .top, spacing: 10) {
                    ProjectIconView(name: project.iconAsset)
                        .frame(width: 30, height: 30)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(project.title).font(.system(size: 14, weight: .semibold))
                        Text(project.description).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(2)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(.tertiary)
                }
                .padding(14)
            }
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 0.5))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mode Réglages (remplace le contenu de la fenêtre PKclipboard)

/// Le shell complet des Réglages, tel qu'il remplace le contenu de travail de
/// la fenêtre principale : sidebar 220 pt + panneau de contenu, avec retour
/// vers le studio presse-papiers (pattern pk-settings-shell).
struct PKSettingsModeView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var clipboard: ClipboardManager
    @ObservedObject private var updater = UpdaterManager.shared
    let storageRootURL: URL
    let initialSection: PKSettingsSection
    let onRunBackupNow: () -> Void
    let onBack: () -> Void

    @State private var selection: PKSettingsSection
    @State private var searchText = ""
    @State private var language: AppLanguage

    init(
        settings: AppSettings,
        clipboard: ClipboardManager,
        storageRootURL: URL,
        initialSection: PKSettingsSection = .general,
        onRunBackupNow: @escaping () -> Void = {},
        onBack: @escaping () -> Void
    ) {
        self.settings = settings
        self.clipboard = clipboard
        self.storageRootURL = storageRootURL
        self.initialSection = initialSection
        self.onRunBackupNow = onRunBackupNow
        self.onBack = onBack
        _selection = State(initialValue: initialSection)
        _language = State(initialValue: settings.selectedLanguage)
    }

    /// Recherche intelligente : les entrées de l'index profonde (réglages
    /// individuels, mots-clés bilingues) priment ; la liste de sections
    /// filtrée reste le comportement de repli.
    private var searchQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var searchEntries: [SettingsSearchEntry] {
        guard !searchQuery.isEmpty else { return [] }
        return PKSettingsSearch.match(searchQuery)
    }

    private var filteredSections: [PKSettingsSection] {
        guard !searchQuery.isEmpty else { return PKSettingsSection.allCases }
        var sections = PKSettingsSection.allCases.filter { $0.keywords.contains(searchQuery) }
        for entry in searchEntries where !sections.contains(entry.section) {
            sections.append(entry.section)
        }
        return PKSettingsSection.allCases.filter { sections.contains($0) }
    }

    private var groupedSections: [(String, [PKSettingsSection])] {
        let grouped = Dictionary(grouping: filteredSections, by: \.category)
        return ["APP", "NOTES", "PK PROJECTS"].compactMap { key in
            guard let values = grouped[key], !values.isEmpty else { return nil }
            return (key, values)
        }
    }

    private func selectEntry(_ entry: SettingsSearchEntry) {
        selection = entry.section
        NotificationCenter.default.post(name: .pkHighlightSetting, object: entry.localizedTitle)
    }

    private func languageFlag(_ language: AppLanguage) -> some View {
        let isActive = settings.selectedLanguage == language
        return Button {
            settings.selectedLanguage = language
            self.language = language
        } label: {
            Text(language.flagEmoji)
                .font(.system(size: 15))
                .padding(3)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isActive ? Color.accentColor.opacity(0.15) : .clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(isActive ? Color.accentColor : .clear, lineWidth: 1)
                )
                .opacity(isActive ? 1 : 0.65)
        }
        .buttonStyle(.plain)
        .help(language.displayName)
        .accessibilityLabel(language.displayName)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                onBack()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                    Text(localizedString("back"))
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.8))
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            HStack(spacing: 10) {
                Image(nsImage: PKAppIcon.image(side: 34))
                    .resizable().interpolation(.high).scaledToFit()
                    .frame(width: 34, height: 34)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("PKbrain").font(.headline)
                    Text(localizedString("app_tagline")).font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 18)

            Text(localizedString("sidebar.settings").uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            HStack(spacing: 7) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField(localizedString("sidebar.searchPlaceholder"), text: $searchText)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        if let first = searchEntries.first {
                            selectEntry(first)
                        } else if let first = filteredSections.first {
                            selection = first
                        }
                    }
            }
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 7))
            .padding(.horizontal, 12)

            if !searchEntries.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(searchEntries.prefix(7)) { entry in
                        Button {
                            selectEntry(entry)
                        } label: {
                            HStack(spacing: 7) {
                                Image(systemName: entry.section.icon)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 14)
                                Text(entry.localizedTitle)
                                    .font(.system(size: 12))
                                    .lineLimit(1)
                                Spacer(minLength: 4)
                                Text(entry.section.title)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                            }
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 8)
                            .frame(height: 24)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 5)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(nsColor: .separatorColor).opacity(0.6), lineWidth: 0.5))
                .padding(.horizontal, 12)
            } else if !searchText.isEmpty && searchQuery.count >= 2 && filteredSections.isEmpty {
                Text(localizedString("search.noResults"))
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 20)
            }

            VStack(spacing: 3) {
                ForEach(groupedSections, id: \.0) { group, sections in
                    Text(localizedString(groupKey(for: group)))
                        .font(.system(size: 9, weight: .bold)).foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20).padding(.top, 8)
                    ForEach(sections) { section in
                        Button {
                            selection = section
                        } label: {
                            HStack(spacing: 11) {
                                Image(systemName: section.icon)
                                    .font(.system(size: 14, weight: .medium))
                                    .frame(width: 20)
                                    .foregroundStyle(section.iconTint ?? (selection == section ? Color.primary : Color.secondary))
                                Text(section.title)
                                    .font(.system(size: 13, weight: selection == section ? .semibold : .regular))
                                Spacer()
                            }
                            .foregroundStyle(selection == section ? .primary : .secondary)
                            .padding(.horizontal, 12)
                            .frame(height: 34)
                            .background(selection == section ? Color.accentColor.opacity(0.13) : .clear,
                                        in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 10)
                    }
                }
            }
            .padding(.top, 12)
            Spacer()
            HStack(spacing: 6) {
                ForEach([AppLanguage.french, .english, .italian, .german, .spanish]) { language in
                    languageFlag(language)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)

            HStack(spacing: 5) {
                Text("PKbrain \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? AppVersion.current)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if let available = updater.availableUpdateVersion {
                    Button { updater.checkForUpdates() } label: {
                        Label(available, systemImage: "arrow.down.circle.fill")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                    .help(String(format: localizedString("about.installVersion"), available))
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 18)
        }
        .frame(width: 220)
        .background(.regularMaterial)
    }

    private func groupKey(for category: String) -> String {
        switch category {
        case "APP": "group.app"
        case "NOTES": "group.notes"
        default: "group.projects"
        }
    }

    private func requestRestart() {
        let alert = NSAlert()
        alert.messageText = localizedString("restart_required")
        alert.informativeText = localizedString("restart_required_message")
        alert.runModal()
    }

    @ViewBuilder
    private var content: some View {
        switch selection {
        case .general:
            GeneralPreferencesView(
                settings: settings,
                storageURL: storageRootURL.appendingPathComponent("saved_state.json"),
                onRestartRequested: { requestRestart() },
                onRunBackupNow: { onRunBackupNow() }
            )
        case .shortcuts:
            ShortcutsPreferencesView(settings: settings)
                .padding(24)
        case .lab:
            ScrollView {
                LabSettingsView(storageRootURL: storageRootURL)
                    .padding(24)
            }
        case .stickies:
            ScrollView {
                StickiesSettingsView(settings: settings)
                    .padding(24)
            }
        case .clipboard:
            ClipboardDataSettingsView(
                settings: settings,
                clipboard: clipboard,
                storageRootURL: storageRootURL
            )
        case .drawer:
            ScrollView {
                DrawerSettingsView(settings: settings)
                    .padding(24)
            }
        case .library:
            ProjectLibraryView()
        case .support:
            SupportSettingsView()
        case .about:
            AboutSettingsView(settings: settings)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onReceive(NotificationCenter.default.publisher(for: .pkSelectSettingsSection)) { note in
            if let raw = note.object as? String, let section = PKSettingsSection(rawValue: raw) {
                selection = section
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .appLanguageDidChange)) { _ in
            language = settings.selectedLanguage
        }
        .onAppear { updater.refreshAvailableVersions() }
    }
}

// MARK: - NSColor hex string

extension NSColor {
    /// Init depuis une chaîne hexadécimale "#RRGGBB" ou "#RRGGBBAA".
    convenience init?(hexString: String) {
        var s = String(hexString.filter { $0.isHexDigit })
        guard s.count == 6 || s.count == 8 else { return nil }
        if s.count == 6 { s += "FF" }
        var value: UInt64 = 0
        Scanner(string: s).scanHexInt64(&value)
        self.init(
            srgbRed: CGFloat((value >> 24) & 0xFF) / 255,
            green: CGFloat((value >> 16) & 0xFF) / 255,
            blue: CGFloat((value >> 8) & 0xFF) / 255,
            alpha: CGFloat(value & 0xFF) / 255
        )
    }
}
