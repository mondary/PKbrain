import AppKit
import Combine
import Foundation

final class AutoBackupService {
    private struct Configuration: Equatable {
        let enabled: Bool
        let destinationPath: String
        let intervalHours: Int

        var isConfigured: Bool {
            enabled && !destinationPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && intervalHours > 0
        }
    }

    private let settings: AppSettings
    private let sourceDirectoryProvider: () -> URL?
    private let prepareForBackup: () -> Void
    private var timer: Timer?
    private var cancellables: Set<AnyCancellable> = []
    private var lastConfiguration: Configuration?
    private var isBackingUp = false

    init(
        settings: AppSettings,
        sourceDirectoryProvider: @escaping () -> URL?,
        prepareForBackup: @escaping () -> Void
    ) {
        self.settings = settings
        self.sourceDirectoryProvider = sourceDirectoryProvider
        self.prepareForBackup = prepareForBackup
        observeSettings()
    }

    func performBackupNow() {
        performBackup(force: true)
    }

    private func observeSettings() {
        Publishers.CombineLatest3(
            settings.$autoBackupEnabled,
            settings.$autoBackupDirectoryPath,
            settings.$autoBackupIntervalHours
        )
        .map { enabled, destinationPath, intervalHours in
            Configuration(
                enabled: enabled,
                destinationPath: destinationPath,
                intervalHours: max(1, intervalHours)
            )
        }
        .removeDuplicates()
        .sink { [weak self] config in
            self?.apply(config)
        }
        .store(in: &cancellables)
    }

    private func apply(_ configuration: Configuration) {
        let shouldTriggerImmediateBackup =
            configuration.isConfigured &&
            (
                lastConfiguration == nil ||
                lastConfiguration?.enabled != true && configuration.enabled ||
                lastConfiguration?.destinationPath != configuration.destinationPath && configuration.enabled
            )

        lastConfiguration = configuration
        timer?.invalidate()
        timer = nil

        guard configuration.isConfigured else { return }

        let interval = TimeInterval(configuration.intervalHours * 3600)
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.performBackup()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer

        if shouldTriggerImmediateBackup {
            performBackup()
        }
    }

    private func performBackup(force: Bool = false) {
        guard !isBackingUp else { return }
        guard let sourceDirectory = sourceDirectoryProvider() else { return }
        guard let destinationRoot = settings.autoBackupDirectoryURL else { return }
        guard settings.autoBackupEnabled || force else { return }
        guard settings.autoBackupIntervalHours > 0 || force else { return }
        guard !isDescendant(destinationRoot, of: sourceDirectory) else {
            NSLog("PKbrain: auto backup destination cannot be inside source directory: %@", destinationRoot.path)
            return
        }

        isBackingUp = true
        prepareForBackup()

        DispatchQueue.global(qos: .utility).async { [sourceDirectory, destinationRoot] in
            defer {
                DispatchQueue.main.async { [weak self] in
                    self?.isBackingUp = false
                }
            }

            do {
                _ = try Self.createBackup(
                    sourceDirectory: sourceDirectory,
                    destinationRoot: destinationRoot,
                    prefix: "PKbrain-auto-backup"
                )
            } catch {
                NSLog("PKbrain: auto backup failed: %@", error.localizedDescription)
            }
        }
    }

    private func isDescendant(_ candidate: URL, of parent: URL) -> Bool {
        let candidatePath = candidate.standardizedFileURL.resolvingSymlinksInPath().path
        let parentPath = parent.standardizedFileURL.resolvingSymlinksInPath().path
        if candidatePath == parentPath { return true }
        return candidatePath.hasPrefix(parentPath.hasSuffix("/") ? parentPath : parentPath + "/")
    }

    static func createBackup(
        sourceDirectory: URL,
        destinationRoot: URL,
        prefix: String = "PKbrain-backup"
    ) throws -> URL {
        let fm = FileManager.default
        try fm.createDirectory(at: destinationRoot, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let stamp = formatter.string(from: Date())
        let backupURL = destinationRoot.appendingPathComponent("\(prefix)-\(stamp)", isDirectory: true)

        if fm.fileExists(atPath: backupURL.path) {
            try fm.removeItem(at: backupURL)
        }

        try fm.copyItem(at: sourceDirectory, to: backupURL)
        return backupURL
    }
}
