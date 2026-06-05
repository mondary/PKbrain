import AppKit
import Foundation

final class AppSettings: ObservableObject {
    private enum Keys {
        static let scribblyModeActive = "scribbly-mode-active"
        static let hideActionBar = "hide-bar"
        static let listItemPrefix = "list-item-start"
        static let selectedLanguage = "selected-language"
        static let shortcuts = "keyboard-shortcuts"
        static let storageDirectory = "storage-directory"
        static let randomizeNewNotePosition = "randomize-new-note-position"
        static let typingEffect = "typing-effect"
        static let inlineCalculations = "inline-calculations"
        static let inlineBrandIcons = "inline-brand-icons"
        static let clipboardDrawerEdge = "clipboard-drawer-edge"
        static let clipboardMaxItems = "clipboard-max-items"
        static let clipboardMaxAgeDays = "clipboard-max-age-days"
        static let clipboardSourceMode = "clipboard-source-mode"
        static let clipboardSourceList = "clipboard-source-list"
        static let clipboardCopySound = "clipboard-copy-sound"
        static let clipboardPasteSound = "clipboard-paste-sound"
        static let autoBackupEnabled = "auto-backup-enabled"
        static let autoBackupDirectoryPath = "auto-backup-directory-path"
        static let autoBackupIntervalHours = "auto-backup-interval-hours"
    }

    private let defaults: UserDefaults

    @Published var scribblyModeActive: Bool {
        didSet { defaults.set(scribblyModeActive, forKey: Keys.scribblyModeActive) }
    }

    @Published var hideActionBar: Bool {
        didSet { defaults.set(hideActionBar, forKey: Keys.hideActionBar) }
    }

    @Published var listItemPrefix: String {
        didSet { defaults.set(listItemPrefix, forKey: Keys.listItemPrefix) }
    }

    @Published var selectedLanguage: AppLanguage {
        didSet {
            defaults.set(selectedLanguage.rawValue, forKey: Keys.selectedLanguage)
            applyLanguagePreference()
        }
    }

    @Published private(set) var shortcuts: [ShortcutAction: KeyboardShortcutSetting]

    @Published var storageDirectoryPath: String {
        didSet { defaults.set(storageDirectoryPath, forKey: Keys.storageDirectory) }
    }

    @Published var randomizeNewNotePosition: Bool {
        didSet { defaults.set(randomizeNewNotePosition, forKey: Keys.randomizeNewNotePosition) }
    }

    @Published var typingEffect: TypingEffect {
        didSet { defaults.set(typingEffect.rawValue, forKey: Keys.typingEffect) }
    }

    @Published var inlineCalculations: Bool {
        didSet { defaults.set(inlineCalculations, forKey: Keys.inlineCalculations) }
    }

    @Published var inlineBrandIcons: Bool {
        didSet { defaults.set(inlineBrandIcons, forKey: Keys.inlineBrandIcons) }
    }

    @Published var clipboardDrawerEdge: ClipboardDrawerEdge {
        didSet { defaults.set(clipboardDrawerEdge.rawValue, forKey: Keys.clipboardDrawerEdge) }
    }

    @Published var clipboardMaxItems: Int {
        didSet { defaults.set(clipboardMaxItems, forKey: Keys.clipboardMaxItems) }
    }

    @Published var clipboardMaxAgeDays: Int {
        didSet { defaults.set(clipboardMaxAgeDays, forKey: Keys.clipboardMaxAgeDays) }
    }

    @Published var clipboardSourceMode: ClipboardSourceMode {
        didSet { defaults.set(clipboardSourceMode.rawValue, forKey: Keys.clipboardSourceMode) }
    }

    @Published var clipboardSourceList: [String] {
        didSet {
            if let data = try? JSONEncoder().encode(clipboardSourceList) {
                defaults.set(data, forKey: Keys.clipboardSourceList)
            }
        }
    }

    @Published var clipboardCopySound: ClipboardFeedbackSound {
        didSet { defaults.set(clipboardCopySound.rawValue, forKey: Keys.clipboardCopySound) }
    }

    @Published var clipboardPasteSound: ClipboardFeedbackSound {
        didSet { defaults.set(clipboardPasteSound.rawValue, forKey: Keys.clipboardPasteSound) }
    }

    @Published var autoBackupEnabled: Bool {
        didSet { defaults.set(autoBackupEnabled, forKey: Keys.autoBackupEnabled) }
    }

    @Published var autoBackupDirectoryPath: String {
        didSet { defaults.set(autoBackupDirectoryPath, forKey: Keys.autoBackupDirectoryPath) }
    }

    @Published var autoBackupIntervalHours: Int {
        didSet { defaults.set(max(1, autoBackupIntervalHours), forKey: Keys.autoBackupIntervalHours) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Keys.scribblyModeActive: false,
            Keys.hideActionBar: false,
            Keys.listItemPrefix: " • ",
            Keys.selectedLanguage: AppLanguage.english.rawValue,
            Keys.storageDirectory: "",
            Keys.randomizeNewNotePosition: true
            ,
            Keys.typingEffect: TypingEffect.off.rawValue,
            Keys.inlineCalculations: true,
            Keys.inlineBrandIcons: true,
            Keys.clipboardDrawerEdge: ClipboardDrawerEdge.top.rawValue,
            Keys.clipboardMaxItems: 5000,
            Keys.clipboardMaxAgeDays: 365,
            Keys.clipboardSourceMode: ClipboardSourceMode.allowAll.rawValue,
            Keys.clipboardCopySound: ClipboardFeedbackSound.pop.rawValue,
            Keys.clipboardPasteSound: ClipboardFeedbackSound.tink.rawValue,
            Keys.autoBackupEnabled: false,
            Keys.autoBackupDirectoryPath: "",
            Keys.autoBackupIntervalHours: 24
        ])

        scribblyModeActive = defaults.bool(forKey: Keys.scribblyModeActive)
        hideActionBar = defaults.bool(forKey: Keys.hideActionBar)
        listItemPrefix = defaults.string(forKey: Keys.listItemPrefix) ?? " • "

        let languageRaw = defaults.string(forKey: Keys.selectedLanguage) ?? AppLanguage.english.rawValue
        selectedLanguage = AppLanguage(rawValue: languageRaw) ?? .english
        shortcuts = Self.loadShortcuts(from: defaults)
        storageDirectoryPath = defaults.string(forKey: Keys.storageDirectory) ?? ""
        randomizeNewNotePosition = defaults.bool(forKey: Keys.randomizeNewNotePosition)
        let effectRaw = defaults.string(forKey: Keys.typingEffect) ?? TypingEffect.off.rawValue
        typingEffect = TypingEffect(rawValue: effectRaw) ?? .off
        inlineCalculations = defaults.bool(forKey: Keys.inlineCalculations)
        inlineBrandIcons = defaults.bool(forKey: Keys.inlineBrandIcons)
        let edgeRaw = defaults.string(forKey: Keys.clipboardDrawerEdge) ?? ClipboardDrawerEdge.top.rawValue
        clipboardDrawerEdge = ClipboardDrawerEdge(rawValue: edgeRaw) ?? .top
        // Migration floor for existing installs: keep at least 5000 items / 365 days
        // unless the user explicitly sets higher values later.
        clipboardMaxItems = max(5000, defaults.integer(forKey: Keys.clipboardMaxItems))
        clipboardMaxAgeDays = max(365, defaults.integer(forKey: Keys.clipboardMaxAgeDays))
        let sourceModeRaw = defaults.string(forKey: Keys.clipboardSourceMode) ?? ClipboardSourceMode.allowAll.rawValue
        clipboardSourceMode = ClipboardSourceMode(rawValue: sourceModeRaw) ?? .allowAll
        if let data = defaults.data(forKey: Keys.clipboardSourceList),
           let list = try? JSONDecoder().decode([String].self, from: data) {
            clipboardSourceList = list
        } else {
            clipboardSourceList = []
        }
        let copySoundRaw = defaults.string(forKey: Keys.clipboardCopySound) ?? ClipboardFeedbackSound.pop.rawValue
        clipboardCopySound = ClipboardFeedbackSound(rawValue: copySoundRaw) ?? .pop
        let pasteSoundRaw = defaults.string(forKey: Keys.clipboardPasteSound) ?? ClipboardFeedbackSound.tink.rawValue
        clipboardPasteSound = ClipboardFeedbackSound(rawValue: pasteSoundRaw) ?? .tink
        autoBackupEnabled = defaults.bool(forKey: Keys.autoBackupEnabled)
        autoBackupDirectoryPath = defaults.string(forKey: Keys.autoBackupDirectoryPath) ?? ""
        autoBackupIntervalHours = max(1, defaults.integer(forKey: Keys.autoBackupIntervalHours))

        applyLanguagePreference()
    }

    private func applyLanguagePreference() {
        LocalizationController.shared.setLanguage(code: selectedLanguage.rawValue)

        // Best-effort: also update system localization preferences for formatters, etc.
        defaults.set([selectedLanguage.rawValue], forKey: "AppleLanguages")
        defaults.set(selectedLanguage.rawValue, forKey: "AppleLocale")
    }

    func resetListPrefix() {
        listItemPrefix = " • "
    }

    func shortcut(for action: ShortcutAction) -> KeyboardShortcutSetting {
        shortcuts[action] ?? action.defaultShortcut
    }

    func setShortcut(_ shortcut: KeyboardShortcutSetting, for action: ShortcutAction) {
        shortcuts[action] = shortcut
        saveShortcuts()
    }

    func resetShortcut(for action: ShortcutAction) {
        shortcuts[action] = action.defaultShortcut
        saveShortcuts()
    }

    private func saveShortcuts() {
        let rawShortcuts = Dictionary(uniqueKeysWithValues: shortcuts.map { ($0.key.rawValue, $0.value) })
        guard let data = try? JSONEncoder().encode(rawShortcuts) else {
            return
        }
        defaults.set(data, forKey: Keys.shortcuts)
    }

    private static func loadShortcuts(from defaults: UserDefaults) -> [ShortcutAction: KeyboardShortcutSetting] {
        var shortcuts = Dictionary(uniqueKeysWithValues: ShortcutAction.allCases.map { ($0, $0.defaultShortcut) })

        guard let data = defaults.data(forKey: Keys.shortcuts),
              let rawShortcuts = try? JSONDecoder().decode([String: KeyboardShortcutSetting].self, from: data)
        else {
            return shortcuts
        }

        for (rawAction, shortcut) in rawShortcuts {
            guard let action = ShortcutAction(rawValue: rawAction) else { continue }
            shortcuts[action] = shortcut
        }

        return shortcuts
    }

    var storageDirectoryURL: URL? {
        let trimmed = storageDirectoryPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(fileURLWithPath: trimmed, isDirectory: true)
    }

    var autoBackupDirectoryURL: URL? {
        let trimmed = autoBackupDirectoryPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(fileURLWithPath: trimmed, isDirectory: true)
    }
}

enum ClipboardDrawerEdge: String, CaseIterable, Identifiable {
    case top
    case bottom
    case left
    case right

    var id: String { rawValue }
}

enum ClipboardSourceMode: String, CaseIterable, Identifiable {
    case allowAll
    case blockList
    case allowList

    var id: String { rawValue }
}

enum ClipboardFeedbackSound: String, CaseIterable, Identifiable {
    case off
    case pop
    case tink
    case glass
    case hero
    case purr
    case submarine
    case bottle

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .off: return "Off"
        case .pop: return "Pop"
        case .tink: return "Tink"
        case .glass: return "Glass"
        case .hero: return "Hero"
        case .purr: return "Purr"
        case .submarine: return "Submarine"
        case .bottle: return "Bottle"
        }
    }

    var soundName: NSSound.Name? {
        switch self {
        case .off: return nil
        case .pop: return NSSound.Name("Pop")
        case .tink: return NSSound.Name("Tink")
        case .glass: return NSSound.Name("Glass")
        case .hero: return NSSound.Name("Hero")
        case .purr: return NSSound.Name("Purr")
        case .submarine: return NSSound.Name("Submarine")
        case .bottle: return NSSound.Name("Bottle")
        }
    }
}
