import AppKit
import SwiftUI

struct GeneralPreferencesView: View {
    @ObservedObject var settings: AppSettings
    let storageURL: URL
    let onRestartRequested: () -> Void
    let onRunBackupNow: () -> Void

    @State private var accessibilityGranted = AccessibilityPermissionHelper.isTrusted()
    private let statusTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PreferenceSectionCard(
                    title: localizedString("language"),
                    subtitle: "Choose the app language.",
                    systemImage: "globe"
                ) {
                    Picker("", selection: $settings.selectedLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                accessibilityCard
                storageCard
                behaviorCard
                clipboardCard
                importExportCard
                backupCard
                cleanupCard
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(statusTimer) { _ in
            accessibilityGranted = AccessibilityPermissionHelper.isTrusted()
        }
    }

    private var accessibilityCard: some View {
        PreferenceSectionCard(
            title: "Accessibility",
            subtitle: "Required for clipboard paste automation and global input actions.",
            systemImage: "accessibility"
        ) {
            HStack(spacing: 12) {
                Image(systemName: accessibilityGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accessibilityGranted ? Color.green : Color.orange)
                    .frame(width: 26, height: 26)

                VStack(alignment: .leading, spacing: 2) {
                    Text(accessibilityGranted ? "Access granted" : "Access not granted")
                        .font(.subheadline.weight(.medium))
                    Text("You can ask macOS for the permission again from here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Button("Request again") {
                    AccessibilityPermissionHelper.requestPermission()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var storageCard: some View {
        PreferenceSectionCard(
            title: localizedString("storage"),
            subtitle: "Where notes, clips, and assets are stored.",
            systemImage: "externaldrive"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text(storageURL.deletingLastPathComponent().path)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.04), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .textSelection(.enabled)

                HStack(spacing: 12) {
                    Button(localizedString("change")) {
                        chooseStorageDirectory()
                    }

                    Spacer()

                    Text(localizedString("restart_required"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var behaviorCard: some View {
        PreferenceSectionCard(
            title: localizedString("new_notes"),
            subtitle: "Defaults for new sticky notes and typing feedback.",
            systemImage: "note.text"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(localizedString("randomize_new_note_position"), isOn: $settings.randomizeNewNotePosition)
                    .toggleStyle(.switch)

                Text(localizedString("randomize_new_note_position_hint"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text(localizedString("typing_effects"))
                        .font(.subheadline.weight(.medium))

                    Picker(localizedString("effect"), selection: $settings.typingEffect) {
                        ForEach(TypingEffect.allCases) { effect in
                            Text(effect.displayName).tag(effect)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(localizedString("typing_effects_hint"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text(localizedString("inline_calculations"))
                        .font(.subheadline.weight(.medium))

                    Toggle(localizedString("show_results_while_typing"), isOn: $settings.inlineCalculations)
                        .toggleStyle(.switch)
                    Toggle(localizedString("show_brand_icons_while_typing"), isOn: $settings.inlineBrandIcons)
                        .toggleStyle(.switch)

                    Text(localizedString("inline_calculations_hint"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var clipboardCard: some View {
        PreferenceSectionCard(
            title: localizedString("clipboard"),
            subtitle: "Drawer position and feedback sounds.",
            systemImage: "clipboard"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Picker(localizedString("position"), selection: $settings.clipboardDrawerEdge) {
                    Text(localizedString("position_top")).tag(ClipboardDrawerEdge.top)
                    Text(localizedString("position_bottom")).tag(ClipboardDrawerEdge.bottom)
                    Text(localizedString("position_left")).tag(ClipboardDrawerEdge.left)
                    Text(localizedString("position_right")).tag(ClipboardDrawerEdge.right)
                }
                .pickerStyle(.segmented)

                Text(localizedString("clipboard_position_hint"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    soundRow(
                        title: "Copy sound",
                        selection: $settings.clipboardCopySound,
                        testAction: { ClipboardSoundPlayer.play(settings.clipboardCopySound) }
                    )
                    soundRow(
                        title: "Paste sound",
                        selection: $settings.clipboardPasteSound,
                        testAction: { ClipboardSoundPlayer.play(settings.clipboardPasteSound) }
                    )
                }
            }
        }
    }

    private var importExportCard: some View {
        PreferenceSectionCard(
            title: localizedString("import_export"),
            subtitle: "Move note data in and out of the app.",
            systemImage: "square.and.arrow.down.on.square"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Button(localizedString("export")) { exportNotes() }
                    Button(localizedString("import")) { importNotes() }
                    Spacer()
                }

                Text(localizedString("import_export_hint"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var backupCard: some View {
        PreferenceSectionCard(
            title: "Backup",
            subtitle: "Full-data snapshots, manual restore, and cloud-friendly auto backups.",
            systemImage: "externaldrive.badge.checkmark"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Enable automatic backups", isOn: $settings.autoBackupEnabled)
                    .toggleStyle(.switch)

                HStack(spacing: 10) {
                    Text("Backup folder")
                    Spacer()
                    Text(settings.autoBackupDirectoryURL?.path ?? "No folder selected")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Button("Choose folder") {
                        chooseAutoBackupDirectory()
                    }
                }

                HStack(spacing: 10) {
                    Text("Backup every")
                    Stepper(value: $settings.autoBackupIntervalHours, in: 1...168, step: 1) {
                        Text("\(settings.autoBackupIntervalHours) h")
                    }
                }

                HStack(spacing: 10) {
                    Button("Backup now") {
                        onRunBackupNow()
                    }
                    .disabled(!settings.autoBackupEnabled || settings.autoBackupDirectoryURL == nil)

                    Spacer()
                }

                Text("Automatic backups copy the full PKbrain data folder to the chosen destination on a regular schedule. A timestamped backup folder is created each time, which works well with cloud-synced folders like Google Drive or Dropbox.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                HStack(spacing: 10) {
                    Button("Exporter toutes les donnees") { exportFullBackup() }
                    Button("Restaurer une sauvegarde") { importFullBackup() }
                    Spacer()
                }

                Text("Sauvegarde/restauration du dossier complet PKbrain (notes, clipboard, tags, assets).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var cleanupCard: some View {
        PreferenceSectionCard(
            title: localizedString("cleanup"),
            subtitle: "Archive legacy folders and old backup files.",
            systemImage: "archivebox"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Button(localizedString("archive_legacy_backups")) {
                    archiveLegacyBackups()
                }

                Text(localizedString("archive_legacy_backups_hint"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func soundRow(title: String, selection: Binding<ClipboardFeedbackSound>, testAction: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            Text(title)
            Spacer()
            Picker("", selection: selection) {
                ForEach(ClipboardFeedbackSound.allCases) { sound in
                    Text(sound.displayName).tag(sound)
                }
            }
            .labelsHidden()
            .frame(width: 180)

            Button("Test") {
                testAction()
            }
            .buttonStyle(.bordered)
        }
    }

    private func chooseStorageDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = localizedString("choose")

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else {
            return
        }

        settings.storageDirectoryPath = url.path
        onRestartRequested()
    }

    private func chooseAutoBackupDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else {
            return
        }

        settings.autoBackupDirectoryPath = url.path
    }

    private func exportNotes() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "pkbrain_saved_state.json"
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let destinationURL = panel.url else {
            return
        }

        do {
            let data = try Data(contentsOf: storageURL)
            try data.write(to: destinationURL, options: [.atomic])
        } catch {
            NSLog("PKbrain: failed to export notes: \(error)")
        }
    }

    private func importNotes() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let sourceURL = panel.url else {
            return
        }

        do {
            let data = try Data(contentsOf: sourceURL)

            // Basic sanity check: ensure it decodes as [NoteData]
            _ = try JSONDecoder().decode([NoteData].self, from: data)

            let fm = FileManager.default
            try fm.createDirectory(at: storageURL.deletingLastPathComponent(), withIntermediateDirectories: true)

            if fm.fileExists(atPath: storageURL.path) {
                let backupURL = storageURL.deletingLastPathComponent()
                    .appendingPathComponent("saved_state.backup.json")
                try? fm.removeItem(at: backupURL)
                try fm.copyItem(at: storageURL, to: backupURL)
            }

            try data.write(to: storageURL, options: [.atomic])
            onRestartRequested()
        } catch {
            NSLog("PKbrain: failed to import notes: \(error)")
        }
    }

    private func archiveLegacyBackups() {
        let storageDir = storageURL.deletingLastPathComponent()
        let candidates: [URL] = [
            storageDir.appendingPathComponent("Notes/Duplicates", isDirectory: true),
            storageDir.appendingPathComponent("Trash/Duplicates", isDirectory: true),
            storageDir.appendingPathComponent("saved_state.json.bak"),
            storageDir.appendingPathComponent("saved_state.backup.json")
        ]

        let existing = candidates.filter { FileManager.default.fileExists(atPath: $0.path) }
        guard !existing.isEmpty else {
            let alert = NSAlert()
            alert.messageText = "Nothing to archive"
            alert.informativeText = "No legacy folders or backup files were found."
            alert.runModal()
            return
        }

        let alert = NSAlert()
        alert.messageText = "Archive legacy folders and backups?"
        alert.informativeText = "This will move legacy folders and saved_state backup files into an Archive folder inside your storage directory."
        alert.addButton(withTitle: "Archive")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let fm = FileManager.default
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let stamp = formatter.string(from: Date())
        let archiveDir = storageDir
            .appendingPathComponent("Archive", isDirectory: true)
            .appendingPathComponent("Cleanup-\(stamp)", isDirectory: true)
        do {
            try fm.createDirectory(at: archiveDir, withIntermediateDirectories: true)

            for src in existing {
                let target = archiveDir.appendingPathComponent(src.lastPathComponent, isDirectory: src.hasDirectoryPath)
                try? fm.removeItem(at: target)
                try fm.moveItem(at: src, to: target)
            }

            let done = NSAlert()
            done.messageText = "Archive created"
            done.informativeText = archiveDir.path
            done.runModal()
        } catch {
            let failed = NSAlert()
            failed.messageText = "Archive failed"
            failed.informativeText = error.localizedDescription
            failed.runModal()
        }
    }

    private func exportFullBackup() {
        let storageDir = storageURL.deletingLastPathComponent()
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Exporter"

        guard panel.runModal() == .OK, let destinationRoot = panel.url else { return }

        do {
            let backupURL = try AutoBackupService.createBackup(
                sourceDirectory: storageDir,
                destinationRoot: destinationRoot,
                prefix: "PKbrain-backup"
            )

            let done = NSAlert()
            done.messageText = "Backup cree"
            done.informativeText = backupURL.path
            done.runModal()
        } catch {
            let failed = NSAlert()
            failed.messageText = "Export backup echoue"
            failed.informativeText = error.localizedDescription
            failed.runModal()
        }
    }

    private func importFullBackup() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Restaurer"

        guard panel.runModal() == .OK, let backupDir = panel.url else { return }

        let savedState = backupDir.appendingPathComponent("saved_state.json")
        guard FileManager.default.fileExists(atPath: savedState.path) else {
            let alert = NSAlert()
            alert.messageText = "Sauvegarde invalide"
            alert.informativeText = "Le dossier choisi ne contient pas saved_state.json."
            alert.runModal()
            return
        }

        let confirm = NSAlert()
        confirm.messageText = "Restaurer cette sauvegarde ?"
        confirm.informativeText = "Le dossier actuel sera archive puis remplace par la sauvegarde selectionnee."
        confirm.addButton(withTitle: "Restaurer")
        confirm.addButton(withTitle: "Annuler")
        guard confirm.runModal() == .alertFirstButtonReturn else { return }

        let fm = FileManager.default
        let storageDir = storageURL.deletingLastPathComponent()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let stamp = formatter.string(from: Date())
        let archiveDir = storageDir.deletingLastPathComponent()
            .appendingPathComponent("PKbrain-pre-restore-\(stamp)", isDirectory: true)

        do {
            if fm.fileExists(atPath: archiveDir.path) {
                try fm.removeItem(at: archiveDir)
            }
            if fm.fileExists(atPath: storageDir.path) {
                try fm.copyItem(at: storageDir, to: archiveDir)
                try fm.removeItem(at: storageDir)
            }
            try fm.copyItem(at: backupDir, to: storageDir)
            onRestartRequested()

            let done = NSAlert()
            done.messageText = "Restauration terminee"
            done.informativeText = "Backup precedent archive: \(archiveDir.path)"
            done.runModal()
        } catch {
            let failed = NSAlert()
            failed.messageText = "Restauration echouee"
            failed.informativeText = error.localizedDescription
            failed.runModal()
        }
    }
}
