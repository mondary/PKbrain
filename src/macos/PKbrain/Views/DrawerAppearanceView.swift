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
    let pattern: DrawerStripPattern
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var animates: Bool {
        DrawerAppearance.shouldAnimate(
            style: style,
            isPresented: isPresented,
            reduceMotion: reduceMotion,
            windowIsVisible: true
        )
    }

    var body: some View {
        if style != .hidden {
            Group {
                switch pattern {
                case .ribbon:
                    if #available(macOS 14.0, *) {
                        RibbonStrip(animates: animates)
                    } else {
                        LegacyBrailleStrip(animates: animates)
                    }
                case .original:
                    LegacyBrailleStrip(animates: animates)
                }
            }
            .frame(height: 40)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color(NSColor.separatorColor).opacity(0.4))
                    .frame(height: 1)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color(NSColor.separatorColor).opacity(0.18))
                    .frame(height: 1)
            }
            .background(Color(NSColor.separatorColor).opacity(0.1))
            .clipped()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

/// A slow, seamless "liquid" ribbon. The horizontal offset is a pure function of
/// the current time, so the motion is deterministic (never relies on a value
/// changing to start), stops when paused, and only translates a pre-laid-out
/// strip — no per-frame layout or repainting of the shapes themselves.
@available(macOS 14.0, *)
private struct RibbonStrip: View {
    let animates: Bool

    /// Seconds for the ribbon to drift exactly one tile width (one wave period).
    private static let loopDuration = 26.0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !animates)) { context in
            Canvas { graphics, size in
                let time = animates ? context.date.timeIntervalSinceReferenceDate : 0
                let tileWidth = DrawerRibbonGeometry.tileWidth
                let travel = (time / Self.loopDuration).truncatingRemainder(dividingBy: 1) * tileWidth

                // Three parallax layers drifting at different rates for depth.
                let layers: [(speed: Double, amplitude: Double, lineWidth: Double, opacity: Double)] = [
                    (1.0, 6.0, 1.6, 0.42),
                    (0.62, 4.2, 1.1, 0.26),
                    (1.35, 2.4, 0.9, 0.18)
                ]

                for (index, layer) in layers.enumerated() {
                    var wave = Path()
                    let phaseShift = Double(index) * 0.9
                    let xOffset = -travel * layer.speed
                    // Draw a full period beyond both edges so the drift stays seamless.
                    let startX = xOffset - tileWidth
                    let endX = size.width + tileWidth
                    let stepCount = 240
                    for step in 0...stepCount {
                        let x = startX + (endX - startX) * Double(step) / Double(stepCount)
                        let y = DrawerRibbonGeometry.centerY(at: x - xOffset, amplitude: layer.amplitude, phaseShift: phaseShift)
                        let point = CGPoint(x: x, y: y)
                        if step == 0 { wave.move(to: point) } else { wave.addLine(to: point) }
                    }
                    let accent = Color.accentColor.opacity(layer.opacity)
                    graphics.stroke(
                        wave,
                        with: .linearGradient(
                            Gradient(colors: [
                                accent.opacity(0.15),
                                accent,
                                accent.opacity(0.15)
                            ]),
                            startPoint: CGPoint(x: 0, y: size.height / 2),
                            endPoint: CGPoint(x: size.width, y: size.height / 2)
                        ),
                        style: StrokeStyle(lineWidth: layer.lineWidth, lineCap: .round, lineJoin: .round)
                    )

                    // A trail of dots riding the main wave.
                    if index == 0 {
                        let dotCount = Int(size.width / 26) + 2
                        for dot in 0..<dotCount {
                            let x = Double(dot) * 26 + (xOffset.truncatingRemainder(dividingBy: 26))
                            let y = DrawerRibbonGeometry.centerY(at: x - xOffset, amplitude: layer.amplitude, phaseShift: phaseShift)
                            let fade = 0.18 + 0.22 * (sin(x / size.width * .pi))
                            let dotRect = CGRect(x: x - 1.8, y: y - 1.8, width: 3.6, height: 3.6)
                            graphics.fill(
                                Path(ellipseIn: dotRect),
                                with: .color(Color.accentColor.opacity(fade))
                            )
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The original braille-style strip, kept as a selectable pattern and as the
/// macOS 13 renderer. A pre-laid-out text run translated with a one-shot
/// repeatForever animation, triggered once on appearance.
private struct LegacyBrailleStrip: View {
    let animates: Bool

    private static let pattern = "⠿⠟⠛⠻⠽⠾⠷⠯⠟⠿   "
    private static let repeatCount = 70
    private static let loopDuration = 50.0

    @State private var started = false

    var body: some View {
        GeometryReader { geo in
            let line = String(repeating: Self.pattern, count: Self.repeatCount)
            ZStack(alignment: .leading) {
                Color.clear
                HStack(spacing: 0) {
                    Text(line).fixedSize(horizontal: true, vertical: false)
                    Text(line).fixedSize(horizontal: true, vertical: false)
                }
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(Color(NSColor.tertiaryLabelColor).opacity(0.5))
                .tracking(2.2)
                .frame(width: geo.size.width * 2, alignment: .leading)
                .offset(x: started ? -geo.size.width : 0)
                .animation(
                    animates
                        ? .linear(duration: Self.loopDuration).repeatForever(autoreverses: false)
                        : nil,
                    value: started
                )
            }
            .onAppear {
                // Flip once so the repeatForever animation is actually triggered.
                started = false
                if animates {
                    DispatchQueue.main.async { started = true }
                }
            }
        }
    }
}
