import AppKit
import SwiftUI

/// The bottom strip. Only three modes: nothing (the drawer reclaims the
/// height), the discreet original, or a real rolling wave.
struct DrawerWaveStrip: View {
    let style: DrawerStripStyle
    let isPresented: Bool
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
        // Zero height when hidden: the enclosing VStack collapses and the
        // drawer itself is shortened by the controller, so the space is freed.
        if style != .hidden {
            Group {
                switch style {
                case .wave:
                    if #available(macOS 14.0, *) {
                        RollingWaveStrip(animates: animates)
                    } else {
                        OriginalStrip(animates: animates)
                    }
                case .original:
                    OriginalStrip(animates: animates)
                case .hidden:
                    EmptyView()
                }
            }
            .frame(height: DrawerAppearance.stripHeight(for: style))
            .frame(maxWidth: .infinity)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color(NSColor.separatorColor).opacity(0.35))
                    .frame(height: 1)
            }
            .clipped()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

/// A single sine wave rolling sideways. The horizontal offset is a pure
/// function of the current date, so the motion is deterministic and always
/// moving (it never waits for a state change to start). One clean wave, not a
/// stack of sliding gradients.
@available(macOS 14.0, *)
private struct RollingWaveStrip: View {
    let animates: Bool

    /// Seconds for the wave to travel exactly one wavelength (seamless loop).
    private static let loopDuration = 12.0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !animates)) { context in
            Canvas { graphics, size in
                let wavelength = DrawerWaveGeometry.wavelength
                let time = animates ? context.date.timeIntervalSinceReferenceDate : 0
                // Travel one wavelength over loopDuration, then wrap.
                let shift = (time / Self.loopDuration).truncatingRemainder(dividingBy: 1) * wavelength

                // Two waves: a main one and a fainter echo slightly behind,
                // both solid accent so it reads as a wave, not as filters.
                let layers: [(speed: Double, amplitude: Double, width: Double, opacity: Double)] = [
                    (1.0, DrawerWaveGeometry.amplitude, 1.8, 0.55),
                    (1.0, DrawerWaveGeometry.amplitude * 0.72, 1.1, 0.22)
                ]

                for (index, layer) in layers.enumerated() {
                    var wave = Path()
                    let phaseShift = index == 0 ? 0 : .pi * 0.35
                    let offset = shift * layer.speed + Double(index) * 40
                    let startX = -wavelength
                    let endX = size.width + wavelength
                    let steps = 200
                    for step in 0...steps {
                        let x = startX + (endX - startX) * Double(step) / Double(steps)
                        let y = DrawerWaveGeometry.centerY(
                            at: x + offset,
                            amplitude: layer.amplitude,
                            phaseShift: phaseShift
                        )
                        let point = CGPoint(x: x, y: y)
                        if step == 0 { wave.move(to: point) } else { wave.addLine(to: point) }
                    }
                    graphics.stroke(
                        wave,
                        with: .color(Color.accentColor.opacity(layer.opacity)),
                        style: StrokeStyle(lineWidth: layer.width, lineCap: .round, lineJoin: .round)
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The original discreet strip: a monospaced line drifting slowly sideways.
/// Kept because it reads as a quiet texture rather than a graphic.
private struct OriginalStrip: View {
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
                started = false
                if animates {
                    DispatchQueue.main.async { started = true }
                }
            }
        }
    }
}
