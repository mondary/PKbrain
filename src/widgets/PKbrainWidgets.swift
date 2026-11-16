import AppIntents
import SwiftUI
import WidgetKit

struct NoteEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Note"
    static var defaultQuery = NoteEntityQuery()

    let id: String
    let title: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(title)") }
}

struct NoteEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [NoteEntity] {
        let ids = Set(identifiers)
        return notes.filter { ids.contains($0.id.uuidString) }.map {
            NoteEntity(id: $0.id.uuidString, title: $0.title)
        }
    }

    func suggestedEntities() async throws -> [NoteEntity] {
        notes.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }.map {
            NoteEntity(id: $0.id.uuidString, title: $0.title)
        }
    }

    private var notes: [WidgetNoteSnapshot] {
        WidgetSnapshotStore.configured()?.read().notes ?? []
    }
}

struct SelectNoteIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Choose a note"
    static var description = IntentDescription("Choose a note you have allowed in PKbrain.")

    @Parameter(title: "Note")
    var note: NoteEntity?
}

struct NoteEntry: TimelineEntry {
    let date: Date
    let note: WidgetNoteSnapshot?
}

struct NoteTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> NoteEntry {
        // Synthetic, never show a private note in the widget gallery.
        NoteEntry(date: Date(), note: WidgetNoteSnapshot(
            id: UUID(), title: "PKbrain", content: "Your note, on your desktop.",
            backgroundHex: 0xFFF3B0, foregroundHex: 0x111111
        ))
    }

    func snapshot(for configuration: SelectNoteIntent, in context: Context) async -> NoteEntry {
        entry(for: configuration)
    }

    func timeline(for configuration: SelectNoteIntent, in context: Context) async -> Timeline<NoteEntry> {
        Timeline(entries: [entry(for: configuration)], policy: .after(Date().addingTimeInterval(15 * 60)))
    }

    private func entry(for configuration: SelectNoteIntent) -> NoteEntry {
        let notes = WidgetSnapshotStore.configured()?.read().notes ?? []
        return NoteEntry(date: Date(), note: notes.first { $0.id.uuidString == configuration.note?.id })
    }
}

struct NoteWidgetView: View {
    let entry: NoteEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(entry.note?.title.isEmpty == false ? entry.note!.title : "PKbrain")
                    .font(.headline)
                    .lineLimit(family == .systemSmall ? 1 : 2)
                Spacer(minLength: 4)
                Image(systemName: "note.text")
                    .font(.caption)
                    .accessibilityHidden(true)
            }
            if let note = entry.note {
                Text(note.content)
                    .font(.system(size: family == .systemSmall ? 13 : 15))
                    .lineLimit(family == .systemSmall ? 5 : family == .systemMedium ? 6 : 18)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("Choose an allowed note in Edit Widget. If it was removed or archived, choose another note.")
                    .font(.caption)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(color(entry.note?.foregroundHex ?? 0x111111))
        .containerBackground(for: .widget) {
            color(entry.note?.backgroundHex ?? 0xFFF3B0)
        }
        .widgetURL(entry.note?.noteURL ?? URL(string: "pkbrain://list")!)
    }

    private func color(_ hex: Int) -> Color {
        Color(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

@main
struct PKbrainNoteWidget: Widget {
    let kind = "PKbrainNoteWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectNoteIntent.self, provider: NoteTimelineProvider()) { entry in
            NoteWidgetView(entry: entry)
        }
        .configurationDisplayName("PKbrain Note")
        .description("Keep a chosen note on your desktop.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
