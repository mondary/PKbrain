import Foundation
import WidgetKit

enum NoteWidgetPublisher {
    static let kind = "PKbrainNoteWidget"

    static var isConfigured: Bool {
        WidgetSnapshotStore.configured() != nil &&
            Bundle.main.builtInPlugInsURL.map {
                FileManager.default.fileExists(atPath: $0.appendingPathComponent("PKbrainWidgets.appex").path)
            } == true
    }

    static func snapshot(notes: [NoteData], allowedIDs: [String]) -> WidgetSnapshot {
        let allowed = Set(allowedIDs)
        return WidgetSnapshot(notes: notes
            .filter { !$0.isArchived && allowed.contains($0.id.uuidString) }
            .sorted { $0.id.uuidString < $1.id.uuidString }
            .map {
                WidgetNoteSnapshot(
                    id: $0.id, title: $0.title, content: $0.content,
                    backgroundHex: $0.theme.backgroundHex,
                    foregroundHex: ($0.theme.autoTextColor.usingColorSpace(.deviceRGB)?.redComponent ?? 0) > 0.5 ? 0xFFFFFF : 0x000000
                )
            })
    }

    static func publish(notes: [NoteData], allowedIDs: [String]) {
        guard let store = WidgetSnapshotStore.configured() else { return }
        do {
            if try store.write(snapshot(notes: notes, allowedIDs: allowedIDs)) {
                WidgetCenter.shared.reloadTimelines(ofKind: kind)
            }
        } catch {
            // Do not log titles or content: widgets can contain private notes.
            NSLog("PKbrain: widget snapshot could not be updated (%@)", error.localizedDescription)
        }
    }
}
