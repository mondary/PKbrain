import AppKit

final class StatusMenuController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private weak var manager: NoteManager?

    private let onNewNote: () -> Void
    private let onShowAllNotes: () -> Void
    private let onHideAllNotes: () -> Void
    private let onSaveAllNotes: () -> Void
    private let onShowSettings: () -> Void
    private let onShowAbout: () -> Void
    private let onRestart: () -> Void
    private let onShowList: () -> Void
    private let onShowClipboard: () -> Void
    private let onShowClipboardWindow: () -> Void
    private let onScreenshotOCR: () -> Void
    private let onStickNotesToEdges: () -> Void
    private let isStuckToEdges: () -> Bool
    private let onQuit: () -> Void
    private let onCheckForUpdates: () -> Void
    private let settings: AppSettings

    init(
        manager: NoteManager,
        onNewNote: @escaping () -> Void,
        onShowAllNotes: @escaping () -> Void,
        onHideAllNotes: @escaping () -> Void,
        onSaveAllNotes: @escaping () -> Void,
        onShowSettings: @escaping () -> Void,
        onShowAbout: @escaping () -> Void,
        onRestart: @escaping () -> Void,
        onShowList: @escaping () -> Void,
        onShowClipboard: @escaping () -> Void,
        onShowClipboardWindow: @escaping () -> Void,
        onScreenshotOCR: @escaping () -> Void = {},
        onStickNotesToEdges: @escaping () -> Void = {},
        isStuckToEdges: @escaping () -> Bool = { false },
        onQuit: @escaping () -> Void,
        onCheckForUpdates: @escaping () -> Void = {},
        settings: AppSettings
    ) {
        statusItem = NSStatusBar.system.statusItem(withLength: 26)
        self.manager = manager
        self.onNewNote = onNewNote
        self.onShowAllNotes = onShowAllNotes
        self.onHideAllNotes = onHideAllNotes
        self.onSaveAllNotes = onSaveAllNotes
        self.onShowSettings = onShowSettings
        self.onShowAbout = onShowAbout
        self.onRestart = onRestart
        self.onShowList = onShowList
        self.onShowClipboard = onShowClipboard
        self.onShowClipboardWindow = onShowClipboardWindow
        self.onScreenshotOCR = onScreenshotOCR
        self.onStickNotesToEdges = onStickNotesToEdges
        self.isStuckToEdges = isStuckToEdges
        self.onQuit = onQuit
        self.onCheckForUpdates = onCheckForUpdates
        self.settings = settings

        super.init()

        if let button = statusItem.button {
            button.image = Self.statusIcon()
            button.imagePosition = .imageOnly
            button.imageScaling = .scaleProportionallyUpOrDown
            button.toolTip = "PKbrain"
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        menu.delegate = self
    }

    func menuWillOpen(_ theMenu: NSMenu) {
        guard theMenu === menu else { return }
        rebuildMenu()
    }

    func menuDidClose(_ theMenu: NSMenu) {
        // Le menu est monté à la volée pour ce clic : on le détache pour que
        // le clic suivant (gauche ou droit) repasse par statusItemClicked.
        statusItem.menu = nil
    }

    /// Clic gauche = menu complet (les notes d'abord, puis les actions) ;
    /// clic droit = bloc d'actions compact Settings / Ko-fi / Updates /
    /// About / Quit (pattern PKmonitor).
    @objc private func statusItemClicked(_ sender: Any?) {
        let isRightClick = NSApp.currentEvent?.type == .rightMouseUp
        statusItem.menu = isRightClick ? makeCompactMenu() : menu
        statusItem.button?.performClick(nil)
    }

    @objc private func openNote(_ sender: NSMenuItem) {
        guard let uuidString = sender.representedObject as? String,
              let noteID = UUID(uuidString: uuidString) else {
            return
        }

        manager?.focusNote(documentID: noteID)
    }

    @objc private func newNote(_ sender: NSMenuItem) {
        onNewNote()
    }

    @objc private func showAllNotes(_ sender: NSMenuItem) {
        onShowAllNotes()
    }

    @objc private func hideAllNotes(_ sender: NSMenuItem) {
        onHideAllNotes()
    }

    @objc private func saveAllNotes(_ sender: NSMenuItem) {
        onSaveAllNotes()
    }

    @objc private func showSettings(_ sender: NSMenuItem) {
        onShowSettings()
    }

    @objc private func showAbout(_ sender: NSMenuItem) {
        onShowAbout()
    }

    @objc private func supportDeveloper(_ sender: NSMenuItem) {
        guard let url = URL(string: "https://ko-fi.com/pouark") else { return }
        NSWorkspace.shared.open(url)
    }

    @objc private func quit(_ sender: NSMenuItem) {
        onQuit()
    }

    @objc private func restart(_ sender: NSMenuItem) {
        onRestart()
    }

    @objc private func showList(_ sender: NSMenuItem) {
        onShowList()
    }

    @objc private func showClipboard(_ sender: NSMenuItem) {
        onShowClipboard()
    }

    @objc private func showClipboardWindow(_ sender: NSMenuItem) {
        onShowClipboardWindow()
    }

    @objc private func runScreenshotOCR(_ sender: NSMenuItem) {
        onScreenshotOCR()
    }

    @objc private func stickNotesToEdges(_ sender: NSMenuItem) {
        onStickNotesToEdges()
    }

    private func rebuildMenu() {
        menu.removeAllItems()

        // Ordre canonique (pattern PKmonitor) : la DONNÉE d'abord — les notes
        // ouvertes. Puis les actions de l'app en un bloc, un bloc compact
        // Settings / Ko-fi / Updates / About, et Quit sous un séparateur.
        // Chaque item porte un picto 16×16 inline (aligné sur le logo Ko-fi).
        let notes = manager?.menuEntries() ?? []

        if notes.isEmpty {
            let emptyItem = NSMenuItem(title: localizedString("no_notes"), action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            Self.setInlineMenuIcon(Self.menuSymbol("note.text"), on: emptyItem)
            menu.addItem(emptyItem)
        } else {
            for note in notes {
                let item = NSMenuItem(
                    title: note.title.truncatedForMenu,
                    action: #selector(openNote(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = note.id.uuidString
                let swatch = note.theme.menuSwatchImage
                swatch.size = NSSize(width: 16, height: 16)
                Self.setInlineMenuIcon(swatch, on: item)
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())
        menu.addItem(actionItem(localizedString("new_note"), action: #selector(newNote(_:)), shortcut: .newStickyNote, systemImage: "plus.square.on.square"))
        if manager?.areAllNotesVisible == true {
            menu.addItem(actionItem(localizedString("hide_all_notes"), action: #selector(hideAllNotes(_:)), shortcut: .showAllNotes, systemImage: "eye.slash"))
        } else {
            menu.addItem(actionItem(localizedString("show_all_notes"), action: #selector(showAllNotes(_:)), shortcut: .showAllNotes, systemImage: "eye"))
        }
        menu.addItem(actionItem(localizedString("show_list"), action: #selector(showList(_:)), shortcut: .showNotesList, systemImage: "list.bullet.rectangle"))
        menu.addItem(actionItem(localizedString("show_clipboard_drawer"), action: #selector(showClipboard(_:)), keyEquivalent: "v", modifiers: [.command, .shift], systemImage: "clipboard"))
        menu.addItem(actionItem(localizedString("show_clipboard_window"), action: #selector(showClipboardWindow(_:)), shortcut: .showClipboardWindow, systemImage: "macwindow"))
        menu.addItem(actionItem(localizedString("screenshot_ocr"), action: #selector(runScreenshotOCR(_:)), shortcut: .screenshotOCR, systemImage: "text.viewfinder"))
        menu.addItem(actionItem(
            localizedString(isStuckToEdges() ? "unstick_notes_from_edges" : "stick_notes_to_edges"),
            action: #selector(stickNotesToEdges(_:)),
            keyEquivalent: "",
            systemImage: isStuckToEdges() ? "rectangle.on.rectangle.slash" : "rectangle.on.rectangle"
        ))
        menu.addItem(.separator())

        menu.addItem(actionItem(localizedString("settings"), action: #selector(showSettings(_:)), shortcut: .preferences, systemImage: "gearshape.fill"))

        let donate = NSMenuItem(title: localizedString("support_pkbrain"), action: #selector(supportDeveloper(_:)), keyEquivalent: "")
        donate.target = self
        Self.setInlineMenuIcon(Self.kofiMenuLogo() ?? Self.menuSymbol("heart.fill"), on: donate)
        menu.addItem(donate)

        let updateItem = NSMenuItem(title: localizedString("check_for_updates"), action: #selector(checkForUpdates(_:)), keyEquivalent: "")
        updateItem.target = self
        Self.setInlineMenuIcon(Self.menuSymbol("arrow.clockwise.circle.fill"), on: updateItem)
        menu.addItem(updateItem)

        let aboutItem = NSMenuItem(title: localizedString("about_pkbrain"), action: #selector(showAbout(_:)), keyEquivalent: "")
        aboutItem.target = self
        Self.setInlineMenuIcon(Self.menuSymbol("info.circle.fill"), on: aboutItem)
        menu.addItem(aboutItem)

        menu.addItem(.separator())
        let restartItem = NSMenuItem(title: localizedString("restart_pkbrain"), action: #selector(restart(_:)), keyEquivalent: "")
        restartItem.target = self
        Self.setInlineMenuIcon(Self.menuSymbol("arrow.triangle.2.circlepath"), on: restartItem)
        menu.addItem(restartItem)
        let quit = NSMenuItem(title: localizedString("quit_pkbrain"), action: #selector(quit(_:)), keyEquivalent: "q")
        quit.target = self
        Self.setInlineMenuIcon(Self.menuSymbol("rectangle.portrait.and.arrow.right"), on: quit)
        menu.addItem(quit)
    }

    /// Bloc d'actions compact du clic droit : Settings, Ko-fi, Updates,
    /// About, puis Restart/Quit sous un séparateur (pattern PKmonitor).
    private func makeCompactMenu() -> NSMenu {
        let compact = NSMenu(title: "PKbrain")
        compact.delegate = self
        compact.addItem(actionItem(localizedString("settings"), action: #selector(showSettings(_:)), shortcut: .preferences, systemImage: "gearshape.fill"))

        let donate = NSMenuItem(title: localizedString("support_pkbrain"), action: #selector(supportDeveloper(_:)), keyEquivalent: "")
        donate.target = self
        Self.setInlineMenuIcon(Self.kofiMenuLogo() ?? Self.menuSymbol("heart.fill"), on: donate)
        compact.addItem(donate)

        let updateItem = NSMenuItem(title: localizedString("check_for_updates"), action: #selector(checkForUpdates(_:)), keyEquivalent: "")
        updateItem.target = self
        Self.setInlineMenuIcon(Self.menuSymbol("arrow.clockwise.circle.fill"), on: updateItem)
        compact.addItem(updateItem)

        let aboutItem = NSMenuItem(title: localizedString("about_pkbrain"), action: #selector(showAbout(_:)), keyEquivalent: "")
        aboutItem.target = self
        Self.setInlineMenuIcon(Self.menuSymbol("info.circle.fill"), on: aboutItem)
        compact.addItem(aboutItem)

        compact.addItem(.separator())
        let restartItem = NSMenuItem(title: localizedString("restart_pkbrain"), action: #selector(restart(_:)), keyEquivalent: "")
        restartItem.target = self
        Self.setInlineMenuIcon(Self.menuSymbol("arrow.triangle.2.circlepath"), on: restartItem)
        compact.addItem(restartItem)
        let quit = NSMenuItem(title: localizedString("quit_pkbrain"), action: #selector(quit(_:)), keyEquivalent: "q")
        quit.target = self
        Self.setInlineMenuIcon(Self.menuSymbol("rectangle.portrait.and.arrow.right"), on: quit)
        compact.addItem(quit)
        return compact
    }

    @objc private func checkForUpdates(_ sender: NSMenuItem) {
        onCheckForUpdates()
    }

    /// Picto de menu : SF Symbol en template (adapte dark/light), 16×16 pour
    /// s'aligner sur les swatches de notes et le logo Ko-fi.
    private static func menuSymbol(_ name: String) -> NSImage? {
        let configuration = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(configuration)
        image?.isTemplate = true
        image?.size = NSSize(width: 16, height: 16)
        return image
    }

    /// Logo Ko-fi 16×16 non template pour le menu (le vrai logo, pas un SF
    /// Symbol de repli).
    private static func kofiMenuLogo() -> NSImage? {
        guard let logo = KofiLogo.image else { return nil }
        logo.isTemplate = false
        logo.size = NSSize(width: 16, height: 16)
        return logo
    }

    /// Dans le menu du status item, NSMenuItem.image n'était pas rendu de
    /// façon fiable. Une attachment dans le titre rend l'icône visible et
    /// réserve exactement la même largeur pour tous les items.
    private static func setInlineMenuIcon(_ image: NSImage?, on item: NSMenuItem) {
        guard let image else { return }
        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = NSRect(x: 0, y: -3, width: 16, height: 16)
        let title = NSMutableAttributedString(attachment: attachment)
        title.append(NSAttributedString(string: "  \(item.title)"))
        item.image = nil
        item.attributedTitle = title
    }

    private func actionItem(
        _ title: String,
        action: Selector,
        shortcut actionShortcut: ShortcutAction,
        systemImage: String? = nil
    ) -> NSMenuItem {
        let shortcut = settings.shortcut(for: actionShortcut)
        return actionItem(
            title,
            action: action,
            keyEquivalent: shortcut.normalizedKey,
            modifiers: shortcut.modifier.flags,
            systemImage: systemImage
        )
    }

    private func actionItem(
        _ title: String,
        action: Selector,
        keyEquivalent: String,
        modifiers: NSEvent.ModifierFlags = [.command],
        systemImage: String? = nil
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        item.keyEquivalentModifierMask = keyEquivalent.isEmpty ? [] : modifiers
        if let systemImage {
            Self.setInlineMenuIcon(Self.menuSymbol(systemImage), on: item)
        }
        return item
    }

    private static func statusIcon() -> NSImage {
        let isDevBuild = (Bundle.main.object(forInfoDictionaryKey: "PKbrainBuildChannel") as? String)?.lowercased() == "dev"
        let configuration = NSImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        let symbol = NSImage(systemSymbolName: "note.text", accessibilityDescription: "PKbrain")?
            .withSymbolConfiguration(configuration)

        // Use the same artwork as the application itself in the menu bar.
        if let appIcon = Bundle.main.url(forResource: "PKbrain", withExtension: "icns")
            .flatMap(NSImage.init(contentsOf:)) {
            let image = resizedStatusIcon(from: appIcon)
            image.isTemplate = false
            return image
        }

        if let statusIcon = Bundle.main.url(forResource: "PKbrainStatus", withExtension: "png")
            .flatMap(NSImage.init(contentsOf:)) {
            let image = resizedStatusIcon(from: statusIcon)
            image.isTemplate = false
            return image
        }

        if let appIcon = NSApp.applicationIconImage, appIcon.size.width > 0, appIcon.size.height > 0 {
            let image = resizedStatusIcon(from: appIcon)
            if isDevBuild {
                let red = tintedStatusIcon(from: image, tint: NSColor.systemRed.withAlphaComponent(0.45))
                red.isTemplate = false
                return red
            }
            image.isTemplate = false
            return image
        }

        let fallback = symbol ?? NSImage(size: NSSize(width: 18, height: 18))
        fallback.isTemplate = true
        return fallback
    }

    private static func tintedStatusIcon(from source: NSImage, tint: NSColor) -> NSImage {
        let image = NSImage(size: source.size)
        image.lockFocus()
        source.draw(in: NSRect(origin: .zero, size: source.size))
        tint.setFill()
        NSRect(origin: .zero, size: source.size).fill(using: .sourceAtop)
        image.unlockFocus()
        return image
    }

    private static func resizedStatusIcon(from source: NSImage) -> NSImage {
        let targetSize = NSSize(width: 18, height: 18)
        let image = NSImage(size: targetSize)
        image.lockFocus()
        source.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: source.size),
            operation: .sourceOver,
            fraction: 1.0
        )
        image.unlockFocus()
        return image
    }
}

private extension String {
    var truncatedForMenu: String {
        let fallback = trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled" : self
        guard fallback.count > 42 else {
            return fallback
        }

        let prefix = fallback.prefix(39)
        return "\(prefix)…"
    }
}
