import AppKit
import ApplicationServices
import Foundation

enum AccessibilityPermissionHelper {
    static func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    static func requestPermission() {
        guard !isTrusted() else { return }

        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)

        if !isTrusted() {
            openAccessibilitySettings()
        }
    }

    static func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
