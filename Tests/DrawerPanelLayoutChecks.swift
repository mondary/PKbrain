import AppKit
import SwiftUI

/// Layout-only regression: no NSWindow, screenshot, input or user data.
@main
struct DrawerPanelLayoutChecks {
    @MainActor
    static func main() {
        // Reproduce the previous modifier order: the minimum frame centres the
        // shorter painted content, leaving a 5 pt transparent strip at the top.
        let legacyProbes = Probes()
        let legacy = NSHostingView(rootView: Color.clear
            .frame(height: 370)
            .background(Probe(name: "content", probes: legacyProbes))
            .frame(minWidth: 900, minHeight: 380))
        legacy.sizingOptions = []
        legacy.frame = NSRect(x: 0, y: 0, width: 1200, height: 380)
        legacy.layoutSubtreeIfNeeded()
        guard let legacyContent = legacyProbes.views["content"] else {
            fatalError("Legacy layout probe was not mounted")
        }
        let legacyFrame = legacy.convert(legacyContent.bounds, from: legacyContent)
        let legacyGap = legacy.isFlipped
            ? legacyFrame.minY - legacy.bounds.minY
            : legacy.bounds.maxY - legacyFrame.maxY
        precondition(abs(legacyGap - 5) < 0.01, "Legacy gap must be reproduced")

        for style in DrawerStripStyle.allCases {
            let stripHeight = DrawerAppearance.stripHeight(for: style)
            for extraHeight in [0.0, 80.0] {
                let minimumHeight = 380 + stripHeight
                let height = minimumHeight + extraHeight
                let probes = Probes()
                let root = Color.clear
                    .frame(height: 370 + stripHeight)
                    .background(Probe(name: "content", probes: probes))
                    .modifier(DrawerPanelLayout(minimumWidth: 900, minimumHeight: minimumHeight))
                    .background(Probe(name: "panel", probes: probes))
                let host = NSHostingView(rootView: root)
                host.sizingOptions = []
                host.frame = NSRect(x: 0, y: 0, width: 1200, height: height)
                host.layoutSubtreeIfNeeded()
                guard let content = probes.views["content"],
                      let panel = probes.views["panel"] else {
                    fatalError("Layout probes were not mounted")
                }
                let contentFrame = host.convert(content.bounds, from: content)
                let panelFrame = host.convert(panel.bounds, from: panel)
                precondition(abs(panelFrame.width - host.bounds.width) < 0.01)
                precondition(abs(panelFrame.height - host.bounds.height) < 0.01)
                let gap = host.isFlipped
                    ? contentFrame.minY - host.bounds.minY
                    : host.bounds.maxY - contentFrame.maxY
                precondition(abs(gap) < 0.01, "\(style): transparent top gap \(gap)")
            }
        }
        print("PASS: legacy 5 pt gap reproduced; corrected drawer fills its hosting view and stays top-aligned in all 3 strip modes (6 layouts); no windows opened.")
    }
}

private final class Probes {
    var views: [String: NSView] = [:]
}

private struct Probe: NSViewRepresentable {
    let name: String
    let probes: Probes

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        probes.views[name] = view
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
