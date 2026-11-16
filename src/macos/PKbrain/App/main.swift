import AppKit

// Diagnostics without starting AppKit, the clipboard monitor or NoteStorage.
if CommandLine.arguments.contains("--widget-status") {
    let embedded = Bundle.main.builtInPlugInsURL.map {
        FileManager.default.fileExists(atPath: $0.appendingPathComponent("PKbrainWidgets.appex").path)
    } ?? false
    let groupAvailable = WidgetSnapshotStore.configured() != nil
    print("widgetExtensionEmbedded=\(embedded) appGroupAvailable=\(groupAvailable)")
    exit(embedded && groupAvailable ? 0 : 1)
}

let application = NSApplication.shared
let delegate = AppDelegate()

application.delegate = delegate
application.setActivationPolicy(.regular)
application.run()
