// Build with the app's current Models, Stores, Support, Services and Views sources.
// No AppDelegate, NoteStorage instance, global clipboard or user session is opened.
import AppKit
import SwiftUI

@main
struct CaptureNative {
    @MainActor static func main() throws {
        let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        let scratch = FileManager.default.temporaryDirectory.appendingPathComponent("pkbrain-store-capture-\(UUID())")
        try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: scratch) }
        _ = NSApplication.shared
        NSApp.setActivationPolicy(.prohibited)
        NSApp.appearance = NSAppearance(named: .aqua)
        let suite = "PKbrainCapture-\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = AppSettings(defaults: defaults)
        settings.selectedLanguage = .french
        settings.randomizeNewNotePosition = false
        FontRegistrar.registerBundledFonts()

        let notes = [
            NoteData(title: "Une idée à garder", theme: .banana, content: "Moins de friction.\nPlus de place pour les idées.\n\nÀ retenir pour notre projet :\n • Une interface qui s’efface\n • Un raccourci pour chaque geste\n • Le plaisir des petits détails", zoom: 120, width: 400, height: 360),
            NoteData(title: "Le budget du projet", theme: .blueberry, content: "Budget de lancement\n\nbudget = 1200\ndesign = 450\ndev = 600\nbudget - design - dev\n\nGarder une marge pour la suite.", zoom: 120, width: 400, height: 360),
            NoteData(title: "Pour demain", theme: .mint, content: " • Affiner la première impression\n • Partager les pistes de design\n • Préparer le prototype\n\nUne chose à la fois.\nEt les bonnes idées à portée de main.", zoom: 120, width: 400, height: 360)
        ]
        let entries = notes.map { ClipboardView.NoteDeckItem(id: $0.id, title: $0.title, content: $0.content, theme: $0.theme, isPinned: false, updatedAt: Date()) }
        let texts: [(String, String, String)] = [
            ("com.apple.Safari", "Safari", "Moins de friction.\nPlus de place pour les idées."),
            ("com.apple.mail", "Mail", "On se retrouve jeudi à 10 h pour découvrir les nouvelles pistes du projet."),
            ("com.microsoft.VSCode", "Visual Studio Code", "const idea = capture();\nconst note = idea.keep();\nnote.add(yourThoughts);"),
            ("com.apple.Safari", "Safari", "Une bonne interface ne demande pas votre attention. Elle vous la rend."),
            ("com.apple.finder", "Finder", "Présentation du projet\nVersion finale • Septembre 2026"),
            ("com.apple.mail", "Mail", "Le prototype est validé. Prochaine étape : préparer la présentation.")
        ]
        var items = texts.enumerated().map { index, text in
            ClipboardManager.Item(id: UUID(), createdAt: Date().addingTimeInterval(Double(-index * 130)), sourceBundleID: text.0, sourceAppName: text.1, kind: .text, previewText: text.2, payload: .text(text.2), isPinned: index == 0, isLocked: false, isTrashed: false, tags: ["Projet"])
        }
        items.insert(ClipboardManager.Item(id: UUID(), createdAt: Date().addingTimeInterval(-60), sourceBundleID: "com.figma.Desktop", sourceAppName: "Figma", kind: .color, previewText: "#DFF8EF", payload: .colorHex("#DFF8EF"), isPinned: false, isLocked: false, isTrashed: false, tags: ["Design"]), at: 1)
        let persistence = ClipboardPersistence(baseDirectory: scratch)
        persistence.save(items)
        let clipboard = ClipboardManager(pasteboard: NSPasteboard(name: NSPasteboard.Name("PKbrainCapture-\(UUID())")), persistence: persistence)
        // Deliberately never call clipboard.start(): no observation of the system pasteboard.
        for (index, note) in notes.enumerated() {
            let document = NoteDocument(data: note)
            let controller = NoteWindowController(document: document, settings: settings, onNew: {}, onDelete: {}, onSave: {}, onShowEmoji: {}, onShowList: {}, onDocumentChanged: {})
            let window = controller.window!
            window.setContentSize(NSSize(width: 400, height: 360))
            try capture(window: window, name: "note-\(index + 1)", output: output)
        }
        let drawer = ClipboardView(clipboard: clipboard, drawerEdge: .top, notesProvider: { entries }, onCreateNoteFromItem: { _ in }, onOpenNote: { _ in }, onCopyItem: { _ in }, onDismiss: {}, onPaste: {}, shouldHandleKeyboard: { false }, onContextStateChanged: { _ in }, onToggleStandardWindow: {}, onShowPreferences: {}, onOpenFinder: {}, onRunBackupNow: {})
        try render(drawer, size: NSSize(width: 1440, height: 420), name: "drawer", output: output)
        let full = ClipboardStandardWindowView(clipboard: clipboard, settings: settings, storageRootURL: scratch, startsInSettingsMode: false, notesProvider: { entries }, onCreateNoteFromItem: { _ in }, onOpenNote: { _ in }, onCopyItem: { _ in }, onPaste: {}, onLoadFavicon: { _ in nil }, onLoadURLPreviewImage: { _ in nil }, onShowPreferences: {}, onOpenFinder: {}, onRunBackupNow: {})
        try render(full, size: NSSize(width: 1200, height: 760), name: "library", output: output)
        for (name, bundleID) in [("safari", "com.apple.Safari"), ("mail", "com.apple.mail"), ("finder", "com.apple.finder"), ("code", "com.microsoft.VSCode"), ("figma", "com.figma.Desktop")] {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                let icon = NSWorkspace.shared.icon(forFile: url.path)
                let image = NSImage(size: NSSize(width: 128, height: 128))
                image.lockFocus(); icon.draw(in: NSRect(x: 0, y: 0, width: 128, height: 128)); image.unlockFocus()
                if let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff), let png = bitmap.representation(using: .png, properties: [:]) { try png.write(to: output.appendingPathComponent("app-\(name).png")) }
            }
        }
        print("Native views captured with synthetic data in \(output.path)")
    }

    @MainActor static func render<V: View>(_ view: V, size: NSSize, name: String, output: URL) throws {
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = NSHostingView(rootView: view.environment(\.colorScheme, .light))
        window.setContentSize(size)
        try capture(window: window, name: name, output: output)
    }

    @MainActor static func capture(window: NSWindow, name: String, output: URL) throws {
        window.setFrameOrigin(NSPoint(x: -10000, y: -10000))
        window.orderBack(nil)
        let view = window.contentView!
        view.layoutSubtreeIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(1.3))
        view.layoutSubtreeIfNeeded()
        let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
        view.cacheDisplay(in: view.bounds, to: bitmap)
        try bitmap.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent("\(name).png"))
        window.orderOut(nil)
    }
}
