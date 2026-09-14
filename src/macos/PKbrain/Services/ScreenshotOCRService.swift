import AppKit
import Vision

/// TRex-style screenshot OCR: interactive screen selection, Vision text recognition,
/// result copied to the clipboard and shown in a small floating panel.
final class ScreenshotOCRService: NSObject, NSTextViewDelegate {
    private var panel: NSPanel?
    private var textView: NSTextView?
    private var dismissTimer: Timer?
    private var panelText = ""

    func start() {
        // Screen Recording TCC permission (required for the screencapture subprocess).
        if !CGPreflightScreenCaptureAccess() {
            if !CGRequestScreenCaptureAccess() {
                showPermissionAlert()
                return
            }
        }

        let target = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("pkbrain-ocr-\(UUID().uuidString).png")
        defer { try? FileManager.default.removeItem(at: target) }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        // -i interactive selection, -x no capture sound. Exit != 0 when the user presses Esc.
        task.arguments = ["-i", "-x", target.path]
        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            return
        }
        guard task.terminationStatus == 0, let image = NSImage(contentsOf: target) else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let text = Self.recognizeText(in: image)
            DispatchQueue.main.async {
                self?.finish(text: text)
            }
        }
    }

    private static func recognizeText(in image: NSImage) -> String {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return "" }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["fr-FR", "en-US"]
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return ""
        }
        return (request.results ?? [])
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
    }

    private func finish(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showPanel(text: localizedString("ocr_no_text"), emptyResult: true)
            return
        }

        panelText = trimmed
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(trimmed, forType: .string)
        ClipboardSoundPlayer.playCopy()
        // The ClipboardManager picks up the pasteboard change, so the OCR text
        // also lands in the clipboard history automatically.
        showPanel(text: trimmed, emptyResult: false)
    }

    // MARK: - Result panel

    private func showPanel(text: String, emptyResult: Bool) {
        dismissPanel()

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 190),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = localizedString(emptyResult ? "ocr_result_title_empty" : "ocr_result_title")
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let textView = NSTextView()
        textView.isEditable = !emptyResult
        textView.isSelectable = true
        textView.isRichText = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.string = text
        textView.backgroundColor = .clear
        textView.textColor = emptyResult ? .secondaryLabelColor : .labelColor
        textView.textContainerInset = NSSize(width: 8, height: 8)
        if emptyResult {
            textView.backgroundColor = NSColor.windowBackgroundColor
        }
        textView.delegate = self

        scrollView.documentView = textView
        panel.contentView = scrollView
        self.panel = panel
        self.textView = textView

        // Place the panel near the mouse (where the user just selected), clamped to screen.
        let mouse = NSEvent.mouseLocation
        if let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) ?? NSScreen.main {
            let visible = screen.visibleFrame
            let size = NSSize(width: min(400, visible.width - 32), height: min(220, visible.height - 32))
            let origin = NSPoint(
                x: min(max(mouse.x - size.width / 2, visible.minX + 16), visible.maxX - size.width - 16),
                y: min(max(mouse.y + 24, visible.minY + 16), visible.maxY - size.height - 16)
            )
            panel.setFrame(NSRect(origin: origin, size: size), display: false)
        }

        panel.orderFrontRegardless()
        scheduleDismiss()
    }

    func textDidChange(_ notification: Notification) {
        // Keep the clipboard in sync if the user fixes an OCR mistake in the panel.
        panelText = textView?.string ?? panelText
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(panelText, forType: .string)
        scheduleDismiss()
    }

    private func scheduleDismiss() {
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] _ in
            self?.dismissPanel()
        }
    }

    private func dismissPanel() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        panel?.orderOut(nil)
        panel = nil
        textView = nil
    }

    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = localizedString("ocr_permission_title")
        alert.informativeText = localizedString("ocr_permission_body")
        alert.addButton(withTitle: localizedString("ocr_permission_open_settings"))
        alert.addButton(withTitle: "OK")
        if alert.runModal() == .alertFirstButtonReturn,
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}
