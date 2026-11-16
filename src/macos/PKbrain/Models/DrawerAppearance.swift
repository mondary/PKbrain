import Foundation

/// Bottom strip of the drawer. Three plain choices, matching what actually
/// reads well: nothing (space reclaimed), the discreet original, or a real wave.
enum DrawerStripStyle: String, CaseIterable, Identifiable {
    case hidden, original, wave

    var id: String { rawValue }
    var localizationKey: String { "drawer.strip.\(rawValue)" }

    /// Legacy values from earlier builds map onto the three real choices.
    init(stored: String?) {
        switch stored {
        case "hidden": self = .hidden
        case "original", "staticWave": self = .original
        case "wave", "animatedWave", "ribbon": self = .wave
        default: self = .wave
        }
    }
}

enum DrawerAppearance {
    /// Height reserved for the strip. Zero when hidden so the drawer genuinely
    /// reclaims the space instead of leaving a gap.
    static func stripHeight(for style: DrawerStripStyle) -> Double {
        style == .hidden ? 0 : 40
    }

    /// Decorative motion only runs while the drawer is actually on screen and
    /// the user has not asked to reduce motion.
    static func shouldAnimate(
        style: DrawerStripStyle, isPresented: Bool,
        reduceMotion: Bool, windowIsVisible: Bool
    ) -> Bool {
        style != .hidden && isPresented && !reduceMotion && windowIsVisible
    }
}

/// One clean, periodic wave. A single sine whose period is `wavelength`, so it
/// can be translated sideways without a seam. Shared by the renderer and tests.
enum DrawerWaveGeometry {
    static let height = 40.0
    static let amplitude = 7.0
    static let wavelength = 300.0

    static func centerY(at x: Double, amplitude: Double = amplitude, phaseShift: Double = 0) -> Double {
        height / 2 + sin(x / wavelength * 2 * .pi + phaseShift) * amplitude
    }
}
