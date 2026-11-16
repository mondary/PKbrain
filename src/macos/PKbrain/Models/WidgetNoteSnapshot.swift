import Foundation

/// A read-only projection. This module never opens NoteStorage or the Notes/
/// directory; an extension can therefore never trigger a storage migration.
struct WidgetNoteSnapshot: Codable, Equatable, Identifiable {
    let id: UUID
    let title: String
    let content: String
    let backgroundHex: Int
    let foregroundHex: Int

    var noteURL: URL {
        URL(string: "pkbrain://note/\(id.uuidString)")!
    }
}

struct WidgetSnapshot: Codable, Equatable {
    static let currentSchemaVersion = 1
    let schemaVersion: Int
    let notes: [WidgetNoteSnapshot]

    init(notes: [WidgetNoteSnapshot]) {
        schemaVersion = Self.currentSchemaVersion
        self.notes = notes
    }
}

struct WidgetSnapshotStore {
    static let fileName = "widget-notes.json"
    let directory: URL

    static func configured(bundle: Bundle = .main) -> WidgetSnapshotStore? {
        guard let group = bundle.object(forInfoDictionaryKey: "PKbrainWidgetAppGroup") as? String,
              !group.isEmpty, !group.contains("$("),
              let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) else {
            return nil
        }
        return WidgetSnapshotStore(directory: directory)
    }

    func read() -> WidgetSnapshot {
        guard let data = try? Data(contentsOf: directory.appendingPathComponent(Self.fileName)),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data),
              snapshot.schemaVersion == WidgetSnapshot.currentSchemaVersion else {
            return WidgetSnapshot(notes: [])
        }
        return snapshot
    }

    /// Atomically replace the complete allowlisted projection, including when it
    /// becomes empty. Revocation, deletion and archiving remove stale copies.
    @discardableResult
    func write(_ snapshot: WidgetSnapshot) throws -> Bool {
        guard snapshot != read() else { return false }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        try encoder.encode(snapshot).write(
            to: directory.appendingPathComponent(Self.fileName), options: .atomic
        )
        return true
    }
}
