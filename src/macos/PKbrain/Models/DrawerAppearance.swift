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

enum DrawerStripPattern: String, CaseIterable, Identifiable {
    case ribbon, original
    var id: String { rawValue }
    var localizationKey: String { "drawer.pattern.\(rawValue)" }
}

/// One periodic tile: neighboring tiles meet without a jump. The view paints
/// this once, then translates the ribbon instead of redrawing it every frame.
enum DrawerRibbonGeometry {
    static let tileWidth = 320.0
    static let height = 32.0
    static let columnCount = 40

    /// Height at horizontal position `x` for a wave whose period is exactly one
    /// tile width, so tiles repeated side by side join without a seam.
    static func centerY(at x: Double, amplitude: Double = 5, phaseShift: Double = 0) -> Double {
        let phase = x / tileWidth * 2 * .pi + phaseShift
        return height / 2 + sin(phase) * amplitude + sin(phase * 2 + phaseShift) * (amplitude * 0.3)
    }

    static func tileCount(for width: Double) -> Int {
        guard width.isFinite, width > 0 else { return 2 }
        return Int(ceil(width / tileWidth)) + 2
    }
}

enum DrawerAppearance {
    static func clampedOpacity(_ value: Double) -> Double {
        value.isFinite ? min(1, max(0, value)) : 0.35
    }

    static func shouldAnimate(
        style: DrawerStripStyle, isPresented: Bool,
        reduceMotion: Bool, windowIsVisible: Bool
    ) -> Bool {
        // A nonactivating NSPanel can be visible while its app is inactive.
        style == .animatedWave && isPresented && !reduceMotion && windowIsVisible
    }
}
