import AppKit
import Foundation

enum ClipboardSoundPlayer {
    static func play(_ sound: ClipboardFeedbackSound) {
        guard let soundName = sound.soundName else { return }
        NSSound(named: soundName)?.play()
    }

    static func playCopy(from defaults: UserDefaults = .standard) {
        play(resolve(defaults.string(forKey: "clipboard-copy-sound"), fallback: .pop))
    }

    static func playPaste(from defaults: UserDefaults = .standard) {
        play(resolve(defaults.string(forKey: "clipboard-paste-sound"), fallback: .tink))
    }

    private static func resolve(_ rawValue: String?, fallback: ClipboardFeedbackSound) -> ClipboardFeedbackSound {
        guard let rawValue, let sound = ClipboardFeedbackSound(rawValue: rawValue) else {
            return fallback
        }
        return sound
    }
}
