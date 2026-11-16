import Foundation

enum DrawerStripStyle: String, CaseIterable, Identifiable {
    case hidden, staticWave, animatedWave
    var id: String { rawValue }
    var localizationKey: String { "drawer.strip.\(rawValue)" }
}

enum DrawerSurfaceStyle: String, CaseIterable, Identifiable {
    case classic, frosted, liquidGlass
    var id: String { rawValue }
    var localizationKey: String { "drawer.surface.\(rawValue)" }
}

enum DrawerAppearance {
    static func clampedOpacity(_ value: Double) -> Double {
        value.isFinite ? min(1, max(0, value)) : 0.35
    }

    static func shouldAnimate(
        style: DrawerStripStyle, isPresented: Bool,
        reduceMotion: Bool, applicationIsActive: Bool
    ) -> Bool {
        style == .animatedWave && isPresented && !reduceMotion && applicationIsActive
    }
}
