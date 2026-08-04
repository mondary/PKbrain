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
                    subtitle: localizedString("language_hint"),
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
            title: localizedString("accessibility"),
            subtitle: localizedString("accessibility_hint"),
            systemImage: "accessibility"
        ) {
            HStack(spacing: 12) {
                Image(systemName: accessibilityGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accessibilityGranted ? Color.green : Color.orange)
                    .frame(width: 26, height: 26)

                VStack(alignment: .leading, spacing: 2) {
                    Text(accessibilityGranted ? localizedString("access_granted") : localizedString("access_not_granted"))
                        .font(.subheadline.weight(.medium))
                    Text(localizedString("access_hint"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Button(localizedString("request_again")) {
                    AccessibilityPermissionHelper.requestPermission()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var storageCard: some View {
        PreferenceSectionCard(
            title: localizedString("storage"),
            subtitle: localizedString("storage_hint"),
            systemImage: "externaldrive"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text(storageURL.deletingLastPathComponent().path)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.separatorColor).opacity(0.3), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
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
            subtitle: localizedString("new_notes_defaults"),
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
            subtitle: localizedString("clipboard_settings_hint"),
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
                        title: localizedString("copy_sound"),
                        selection: $settings.clipboardCopySound,
                        testAction: { ClipboardSoundPlayer.play(settings.clipboardCopySound) }
                    )
                    soundRow(
                        title: localizedString("paste_sound"),
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
            subtitle: localizedString("import_export_hint_2"),
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
            title: localizedString("backup"),
            subtitle: localizedString("backup_hint"),
            systemImage: "externaldrive.badge.checkmark"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(localizedString("enable_auto_backup"), isOn: $settings.autoBackupEnabled)
                    .toggleStyle(.switch)

                HStack(spacing: 10) {
                    Text(localizedString("backup_folder"))
                    Spacer()
                    Text(settings.autoBackupDirectoryURL?.path ?? localizedString("no_folder_selected"))
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Button(localizedString("choose_folder")) {
                        chooseAutoBackupDirectory()
                    }
                }

                HStack(spacing: 10) {
                    Text(localizedString("backup_every"))
                    Stepper(value: $settings.autoBackupIntervalHours, in: 1...168, step: 1) {
                        Text("\(settings.autoBackupIntervalHours) h")
                    }
                }

                HStack(spacing: 10) {
                    Button(localizedString("backup_now")) {
                        onRunBackupNow()
                    }
                    .disabled(!settings.autoBackupEnabled || settings.autoBackupDirectoryURL == nil)

                    Spacer()
                }

                Text(localizedString("backup_auto_desc"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                HStack(spacing: 10) {
                    Button(localizedString("export_backup")) { exportFullBackup() }
                    Button(localizedString("restore_backup")) { importFullBackup() }
                    Spacer()
                }

                Text(localizedString("backup_restore_desc"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var cleanupCard: some View {
        PreferenceSectionCard(
            title: localizedString("cleanup"),
            subtitle: localizedString("cleanup_hint"),
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

            Button(localizedString("test")) {
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
        panel.prompt = localizedString("choose")

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
            alert.messageText = localizedString("nothing_to_archive")
            alert.informativeText = localizedString("nothing_to_archive_msg")
            alert.runModal()
            return
        }

        let alert = NSAlert()
        alert.messageText = localizedString("archive_confirm_title")
        alert.informativeText = localizedString("archive_confirm_msg")
        alert.addButton(withTitle: localizedString("archive"))
        alert.addButton(withTitle: localizedString("cancel"))
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
            done.messageText = localizedString("archive_created")
            done.informativeText = archiveDir.path
            done.runModal()
        } catch {
            let failed = NSAlert()
            failed.messageText = localizedString("archive_failed")
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
        panel.prompt = localizedString("export")

        guard panel.runModal() == .OK, let destinationRoot = panel.url else { return }

        do {
            let backupURL = try AutoBackupService.createBackup(
                sourceDirectory: storageDir,
                destinationRoot: destinationRoot,
                prefix: "PKbrain-backup"
            )

            let done = NSAlert()
            done.messageText = localizedString("backup_created")
            done.informativeText = backupURL.path
            done.runModal()
        } catch {
            let failed = NSAlert()
            failed.messageText = localizedString("backup_failed")
            failed.informativeText = error.localizedDescription
            failed.runModal()
        }
    }

    private func importFullBackup() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = localizedString("restore")

        guard panel.runModal() == .OK, let backupDir = panel.url else { return }

        let savedState = backupDir.appendingPathComponent("saved_state.json")
        guard FileManager.default.fileExists(atPath: savedState.path) else {
            let alert = NSAlert()
            alert.messageText = localizedString("invalid_backup")
            alert.informativeText = localizedString("invalid_backup_msg")
            alert.runModal()
            return
        }

        let confirm = NSAlert()
        confirm.messageText = localizedString("restore_confirm_title")
        confirm.informativeText = localizedString("restore_confirm_msg")
        confirm.addButton(withTitle: localizedString("restore"))
        confirm.addButton(withTitle: localizedString("cancel"))
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
            done.messageText = localizedString("restore_complete")
            done.informativeText = localizedString("backup_previous_archived", archiveDir.path)
            done.runModal()
        } catch {
            let failed = NSAlert()
            failed.messageText = localizedString("restore_failed")
            failed.informativeText = error.localizedDescription
            failed.runModal()
        }
    }
}
