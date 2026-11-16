import Foundation

// Standalone checks: no XCTest/Xcode runtime, app launch or user data required.
@main
struct WidgetAndDrawerChecks {
    static func main() throws {
        let checks = WidgetAndDrawerChecks()
        checks.testAnimationOnlyRunsWhenAllowed()
        checks.testWaveIsPeriodicAndStaysWithinBounds()
        checks.testHiddenStyleReservesNoHeight()
        checks.testNoNoteIsSharedByDefault()
        checks.testOnlyAllowlistedNotesAreExported()
        checks.testArchivedAndRemovedNotesAreExcluded()
        checks.testDeepLinkUsesOriginalIdentity()
        checks.testAllThemeTextContrastsArePreserved()
        try checks.testSnapshotRoundTripAndRevocationDoNotTouchOriginals()
        try checks.testMalformedAndUnknownSchemaAreSafe()
        print("PASS: 10 widget/drawer checks, wave periodicity verified, synthetic data only.")
    }

    func testAnimationOnlyRunsWhenAllowed() {
        for style in [DrawerStripStyle.original, .wave] {
            XCTAssertTrue(DrawerAppearance.shouldAnimate(
                style: style, isPresented: true, reduceMotion: false, windowIsVisible: true
            ))
        }
        // Never animate a hidden strip.
        XCTAssertFalse(DrawerAppearance.shouldAnimate(
            style: .hidden, isPresented: true, reduceMotion: false, windowIsVisible: true
        ))
        XCTAssertFalse(DrawerAppearance.shouldAnimate(
            style: .wave, isPresented: false, reduceMotion: false, windowIsVisible: true
        ))
        XCTAssertFalse(DrawerAppearance.shouldAnimate(
            style: .wave, isPresented: true, reduceMotion: true, windowIsVisible: true
        ))
        XCTAssertFalse(DrawerAppearance.shouldAnimate(
            style: .wave, isPresented: true, reduceMotion: false, windowIsVisible: false
        ))
    }

    func testWaveIsPeriodicAndStaysWithinBounds() {
        let wavelength = DrawerWaveGeometry.wavelength
        XCTAssertEqual(
            DrawerWaveGeometry.centerY(at: 0),
            DrawerWaveGeometry.centerY(at: wavelength),
            accuracy: 0.0001
        )
        XCTAssertEqual(
            DrawerWaveGeometry.centerY(at: wavelength * 0.3),
            DrawerWaveGeometry.centerY(at: wavelength * 1.3),
            accuracy: 0.0001
        )
        // The wave stays inside the strip for any phase.
        for step in 0...80 {
            let y = DrawerWaveGeometry.centerY(at: wavelength * Double(step) / 80)
            XCTAssertTrue(y >= 0 && y <= DrawerWaveGeometry.height)
        }
    }

    func testHiddenStyleReservesNoHeight() {
        XCTAssertEqual(DrawerAppearance.stripHeight(for: .hidden), 0)
        XCTAssertTrue(DrawerAppearance.stripHeight(for: .original) > 0)
        XCTAssertTrue(DrawerAppearance.stripHeight(for: .wave) > 0)
    }

    func testNoNoteIsSharedByDefault() {
        let notes = [NoteData(title: "Private", content: "Do not export")]
        XCTAssertTrue(NoteWidgetPublisher.snapshot(notes: notes, allowedIDs: []).notes.isEmpty)
    }

    func testOnlyAllowlistedNotesAreExported() {
        let shared = NoteData(title: "Allowed", content: "Example")
        let privateNote = NoteData(title: "Private", content: "Never export")
        let snapshot = NoteWidgetPublisher.snapshot(
            notes: [privateNote, shared], allowedIDs: [shared.id.uuidString]
        )
        XCTAssertEqual(snapshot.notes.map(\.id), [shared.id])
        XCTAssertEqual(snapshot.notes.first?.content, shared.content)
    }

    func testArchivedAndRemovedNotesAreExcluded() {
        let archived = NoteData(title: "Archive", content: "Example", isArchived: true)
        let removedID = UUID().uuidString
        XCTAssertTrue(NoteWidgetPublisher.snapshot(
            notes: [archived], allowedIDs: [archived.id.uuidString, removedID]
        ).notes.isEmpty)
    }

    func testDeepLinkUsesOriginalIdentity() {
        let note = NoteData(title: "Original", content: "Text")
        let document = NoteDocument(data: note)
        XCTAssertEqual(document.package().id, note.id)
        let snapshot = NoteWidgetPublisher.snapshot(notes: [note], allowedIDs: [note.id.uuidString])
        XCTAssertEqual(snapshot.notes.first?.noteURL.absoluteString, "pkbrain://note/\(note.id.uuidString)")
    }

    func testAllThemeTextContrastsArePreserved() {
        for theme in NoteTheme.allCases {
            let note = NoteData(title: "Example", theme: theme)
            let exported = NoteWidgetPublisher.snapshot(notes: [note], allowedIDs: [note.id.uuidString]).notes[0]
            XCTAssertEqual(exported.backgroundHex, theme.backgroundHex)
            XCTAssertTrue([0x000000, 0xFFFFFF].contains(exported.foregroundHex))
        }
    }

    func testSnapshotRoundTripAndRevocationDoNotTouchOriginals() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let original = directory.appendingPathComponent("original.md")
        let sentinel = Data("Unmodified original\n".utf8)
        try sentinel.write(to: original)
        let store = WidgetSnapshotStore(directory: directory)
        let note = NoteData(title: "Example", content: "Synthetic text")
        let snapshot = NoteWidgetPublisher.snapshot(notes: [note], allowedIDs: [note.id.uuidString])
        XCTAssertTrue(try store.write(snapshot))
        XCTAssertEqual(store.read(), snapshot)
        XCTAssertFalse(try store.write(snapshot))
        XCTAssertTrue(try store.write(WidgetSnapshot(notes: [])))
        XCTAssertTrue(store.read().notes.isEmpty)
        XCTAssertEqual(try Data(contentsOf: original), sentinel)
    }

    func testMalformedAndUnknownSchemaAreSafe() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent(WidgetSnapshotStore.fileName)
        let store = WidgetSnapshotStore(directory: directory)
        XCTAssertTrue(store.read().notes.isEmpty)
        try Data("invalid".utf8).write(to: url)
        XCTAssertTrue(store.read().notes.isEmpty)
        try Data(#"{"schemaVersion":999,"notes":[]}"#.utf8).write(to: url)
        XCTAssertTrue(store.read().notes.isEmpty)
    }

    private func temporaryDirectory() throws -> URL {
        let base = ProcessInfo.processInfo.environment["PKBRAIN_TEST_TEMP"]
            .map { URL(fileURLWithPath: $0, isDirectory: true) } ?? FileManager.default.temporaryDirectory
        let directory = base.appendingPathComponent("pkbrain-tests-\(UUID())", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}

private func XCTAssertTrue(_ value: Bool, file: StaticString = #file, line: UInt = #line) {
    precondition(value, "Expected true", file: file, line: line)
}

private func XCTAssertFalse(_ value: Bool, file: StaticString = #file, line: UInt = #line) {
    precondition(!value, "Expected false", file: file, line: line)
}

private func XCTAssertEqual<T: Equatable>(_ lhs: T, _ rhs: T, file: StaticString = #file, line: UInt = #line) {
    precondition(lhs == rhs, "Values differ", file: file, line: line)
}

private func XCTAssertEqual(_ lhs: Double, _ rhs: Double, accuracy: Double, file: StaticString = #file, line: UInt = #line) {
    precondition(abs(lhs - rhs) <= accuracy, "Values differ", file: file, line: line)
}

private func XCTAssertGreaterThanOrEqual<T: Comparable>(_ lhs: T, _ rhs: T, file: StaticString = #file, line: UInt = #line) {
    precondition(lhs >= rhs, "Expected lhs >= rhs", file: file, line: line)
}
