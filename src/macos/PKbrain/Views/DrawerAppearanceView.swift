import AppKit
import SwiftUI

/// Background only: opacity never applies to the cards or their text.
struct DrawerSurface: View {
    let style: DrawerSurfaceStyle
    let opacity: Double
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        Group {
            if reduceTransparency || style == .classic {
                Color(NSColor.windowBackgroundColor)
            } else if style == .liquidGlass {
                if #available(macOS 26.0, *) {
                    Color.clear
                        .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 28))
                        .overlay(Color(NSColor.windowBackgroundColor).opacity(opacity))
                } else {
                    frosted
                }
            } else {
                frosted
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var frosted: some View {
        DrawerVisualEffect()
            .overlay(Color(NSColor.windowBackgroundColor).opacity(opacity))
    }
}

private struct DrawerVisualEffect: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {}
}

struct DrawerWaveStrip: View {
    let style: DrawerStripStyle
    let isPresented: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    // NSHostingController in an AppKit app has no SwiftUI WindowGroup scene.
    // Observe AppKit activation instead of relying on a default scenePhase.
    @State private var applicationIsActive = NSApp.isActive

    private var animates: Bool {
        DrawerAppearance.shouldAnimate(
            style: style, isPresented: isPresented,
            reduceMotion: reduceMotion, applicationIsActive: applicationIsActive
        )
    }

    var body: some View {
        if style != .hidden {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !animates)) { context in
                Canvas { graphics, size in
                    let time = animates ? context.date.timeIntervalSinceReferenceDate : 0
                    for layer in 0..<2 {
                        var wave = Path()
                        let amplitude = layer == 0 ? 3.5 : 2.0
                        for step in 0...240 {
                            let x = size.width * Double(step) / 240
                            let phase = x / 180 + time * 0.45 + Double(layer) * 1.8
                            let y = size.height / 2 + sin(phase) * amplitude
                                + sin(phase * 0.63) * 1.5
                            let point = CGPoint(x: x, y: y)
                            if step == 0 { wave.move(to: point) } else { wave.addLine(to: point) }
                        }
                        graphics.stroke(
                            wave,
                            with: .color(.secondary.opacity(layer == 0 ? 0.35 : 0.15)),
                            style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round)
                        )
                    }
                }
            }
            .frame(height: 40)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .top) {
                Color.primary.opacity(0.07).frame(height: 1)
            }
            .clipped()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear { applicationIsActive = NSApp.isActive }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                applicationIsActive = true
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
                applicationIsActive = false
            }
        }
    }
}
