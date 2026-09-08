import AppKit
import SwiftUI

/// Edge-docked notes deck, ported from Noty (github.com/aimen08/noty, MIT).
/// One deck per screen side. Rest: a 12pt dark pill, one dash per note.
/// Hover the edge strip: tabs shingle along the edge (42ms stagger).
/// Click a tab: the full note window opens. Blank areas are click-through.

enum DeckSide: CaseIterable {
    // No top edge: the menu bar lives there and nothing reads well under it.
    case bottom, left, right

    var isVertical: Bool { self == .left || self == .right }
}

final class EdgeDeckManager {
    private var controllers: [EdgeNotesDeckController] = []
    private let entriesProvider: () -> [NoteMenuEntry]
    private let onNoteSelected: (UUID) -> Void
    private let onNewNote: () -> Void
    private var scattered = false

    init(entriesProvider: @escaping () -> [NoteMenuEntry], onNoteSelected: @escaping (UUID) -> Void, onNewNote: @escaping () -> Void) {
        self.entriesProvider = entriesProvider
        self.onNoteSelected = onNoteSelected
        self.onNewNote = onNewNote
        rebuild()
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.rebuild()
        }
    }

    /// Scrapbooking mode: note windows hide and every note stays stuck on an
    /// edge as a paper tab, scattered round-robin across the four sides.
    func setScattered(_ on: Bool) {
        scattered = on
        controllers.forEach { $0.setScattered(on) }
    }

    func rebuild() {
        controllers.forEach { $0.hide() }
        controllers = NSScreen.screens.flatMap { screen in
            DeckSide.allCases.map { side in
                EdgeNotesDeckController(
                    side: side,
                    screen: screen,
                    scattered: scattered,
                    entriesProvider: entriesProvider,
                    onNoteSelected: onNoteSelected,
                    onNewNote: onNewNote
                )
            }
        }
        controllers.forEach { $0.show() }
    }
}

final class EdgeNotesDeckController {
    let side: DeckSide
    let screen: NSScreen
    private let entriesProvider: () -> [NoteMenuEntry]
    private let onNoteSelected: (UUID) -> Void
    private let onNewNote: () -> Void

    private let panel = EdgeDeckPanel()
    private let model = EdgeDeckModel()
    private lazy var root = EdgeDeckRootView(
        side: side,
        model: model,
        entriesProvider: entriesProvider,
        onNoteSelected: onNoteSelected,
        onNewNote: onNewNote
    )

    init(
        side: DeckSide,
        screen: NSScreen,
        scattered: Bool = false,
        entriesProvider: @escaping () -> [NoteMenuEntry],
        onNoteSelected: @escaping (UUID) -> Void,
        onNewNote: @escaping () -> Void
    ) {
        self.side = side
        self.screen = screen
        self.entriesProvider = entriesProvider
        self.onNoteSelected = onNoteSelected
        self.onNewNote = onNewNote

        let container = EdgeDeckContentView()
        container.onPointerEntered = { [weak self] in self?.model.fanned = true }
        container.onPointerExited = { [weak self] in
            guard let self, !self.model.alwaysShown else { return }
            self.model.fanned = false
        }
        container.autoresizingMask = [.width, .height]

        let hosting = NSHostingView(rootView: root)
        hosting.autoresizingMask = [.width, .height]
        container.addSubview(hosting)
        panel.contentView = container
        model.alwaysShown = scattered
        model.fanned = scattered
    }

    func setScattered(_ on: Bool) {
        model.alwaysShown = on
        model.fanned = on
    }

    func show() {
        let visible = screen.visibleFrame
        let thick = DeckGeom.fanWidth + 20
        let frame: NSRect
        switch side {
        case .right: frame = NSRect(x: visible.maxX - thick, y: visible.minY, width: thick, height: visible.height)
        case .left: frame = NSRect(x: visible.minX, y: visible.minY, width: thick, height: visible.height)
        case .bottom: frame = NSRect(x: visible.minX, y: visible.minY, width: visible.width, height: thick)
        }
        panel.setFrame(frame, display: true)
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }
}

// MARK: - Panel & tracking

private final class EdgeDeckPanel: NSPanel {
    override var canBecomeKey: Bool { true }

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 70, height: 400),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovable = false
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        animationBehavior = .none
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
    }
}

/// Full-rect tracking that drives pill → fan. Blank regions stay click-through.
private final class EdgeDeckContentView: NSView {
    var onPointerEntered: (() -> Void)?
    var onPointerExited: (() -> Void)?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self
        ))
    }

    override func mouseEntered(with event: NSEvent) { onPointerEntered?() }
    override func mouseExited(with event: NSEvent) { onPointerExited?() }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let hit = super.hitTest(point)
        return hit === self ? nil : hit
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

// MARK: - Model

private final class EdgeDeckModel: ObservableObject {
    @Published var fanned = false
    /// Scrapbooking: the tabs stay out permanently and this deck only shows
    /// the notes scattered onto its side.
    @Published var alwaysShown = false
}

// MARK: - Geometry (ported from Noty's DeckGeom)

private enum DeckGeom {
    static let pillThick: CGFloat = 12
    static let dashThick: CGFloat = 7
    static let dashLength: CGFloat = 14
    static let dashGap: CGFloat = 5
    static let pillPad: CGFloat = 7

    static let tabThick: CGFloat = 30
    static let tabLap: CGFloat = 40
    static let pitchMin: CGFloat = 56
    static let pitchMax: CGFloat = 106
    static let pitchFloor: CGFloat = 36
    static let labelPad: CGFloat = 20
    static let labelInset: CGFloat = 12
    static let bleed: CGFloat = 14
    static let fanWidth: CGFloat = 50
    static let plusSize: CGFloat = 28
    static let plusGap: CGFloat = 12
    static let heightBudget: CGFloat = 0.68
    static let labelFontSize: CGFloat = 9.5

    static let labelFont = NSFont.systemFont(ofSize: labelFontSize, weight: .semibold)
    static let labelTracking: CGFloat = 0.1

    private static var labelCache: [String: CGFloat] = [:]

    static func labelWidth(_ title: String) -> CGFloat {
        let text = title.uppercased() as NSString
        guard text.length > 0 else { return 0 }
        if let hit = labelCache[text as String] { return hit }
        let w = text.size(withAttributes: [.font: labelFont]).width
            + labelTracking * CGFloat(text.length)
        if labelCache.count > 400 { labelCache.removeAll(keepingCapacity: true) }
        labelCache[text as String] = w
        return w
    }

    static func pillLength(noteCount: Int) -> CGFloat {
        let n = max(1, noteCount)
        return pillPad * 2 + CGFloat(n) * dashLength + CGFloat(n - 1) * dashGap
    }

    /// pitch = centre-to-centre spacing along the edge; item = pitch + lap (the shingle).
    static func layout(panelLength: CGFloat, count: Int, longestLabel: CGFloat) -> (pitch: CGFloat, itemLength: CGFloat) {
        let n = max(1, count)
        var pitch = min(pitchMax, max(pitchMin, longestLabel + labelPad))
        let budget = panelLength * heightBudget - (plusGap + plusSize)
        if CGFloat(n) * pitch + tabLap > budget {
            pitch = max(pitchFloor, (budget - tabLap) / CGFloat(n))
        }
        return (pitch, pitch + tabLap)
    }
}

// MARK: - Root view

private struct EdgeDeckRootView: View {
    let side: DeckSide
    @ObservedObject var model: EdgeDeckModel
    let entriesProvider: () -> [NoteMenuEntry]
    let onNoteSelected: (UUID) -> Void
    let onNewNote: () -> Void

    var body: some View {
        GeometryReader { geo in
            let all = entriesProvider()
            // When scattered, notes are dealt round-robin across the four sides.
            let entries = model.alwaysShown
                ? all.enumerated()
                    .filter { DeckSide.allCases[$0.offset % DeckSide.allCases.count] == side }
                    .map(\.element)
                : all
            let size = geo.size
            // The edge runs along this length; the panel is `thick` across it.
            let length = side.isVertical ? size.height : size.width
            let lay = DeckGeom.layout(
                panelLength: max(1, length),
                count: entries.count,
                longestLabel: entries.map { DeckGeom.labelWidth($0.title.isEmpty ? "Untitled" : $0.title) }.max() ?? 0
            )
            let stackLen = CGFloat(max(1, entries.count) - 1) * lay.pitch + lay.itemLength
                + DeckGeom.plusGap + DeckGeom.plusSize
            let center = (max(1, length) - stackLen) / 2
            let offset = min(max(12, center), max(12, length - stackLen - 12))

            ZStack(alignment: zAlignment) {
                EdgeFanColumn(
                    side: side,
                    entries: entries,
                    pitch: lay.pitch,
                    itemLength: lay.itemLength,
                    revealed: model.fanned,
                    onNoteSelected: onNoteSelected,
                    onNewNote: onNewNote
                )
                .padding(fanPaddingEdge, offset)
                .opacity(model.fanned ? 1 : 0)

                EdgePillView(side: side, entries: entries)
                    .padding(pillPaddingEdge, 1)
                    .opacity(model.fanned ? 0 : 1)
                    .animation(.easeInOut(duration: 0.20).delay(model.fanned ? 0 : 0.12), value: model.fanned)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: zAlignment)
        }
    }

    private var zAlignment: Alignment {
        switch side {
        case .right: .topTrailing
        case .left: .topLeading
        case .bottom: .bottomLeading
        }
    }

    /// Which padding axis carries the along-edge offset.
    private var fanPaddingEdge: Edge.Set {
        side.isVertical ? .top : .leading
    }

    /// The pill sits centred on the edge at rest, pinned by the ZStack alignment.
    private var pillPaddingEdge: Edge.Set {
        switch side {
        case .right: .trailing
        case .left: .leading
        case .bottom: .bottom
        }
    }
}

// MARK: - Pill

private struct EdgePillView: View {
    let side: DeckSide
    let entries: [NoteMenuEntry]

    var body: some View {
        dashStack
            .padding(side.isVertical ? .vertical : .horizontal, DeckGeom.pillPad)
            .frame(
                width: side.isVertical ? DeckGeom.pillThick : nil,
                height: side.isVertical ? nil : DeckGeom.pillThick
            )
            .background(pillShape)
    }

    private var dashStack: some View {
        let dashes = ForEach(entries, id: \.id) { entry in
            RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                .fill(entry.theme.accentColor)
                .frame(
                    width: side.isVertical ? DeckGeom.dashThick : DeckGeom.dashLength,
                    height: side.isVertical ? DeckGeom.dashLength : DeckGeom.dashThick
                )
        }
        return Group {
            if side.isVertical {
                VStack(spacing: DeckGeom.dashGap) { dashes }
            } else {
                HStack(spacing: DeckGeom.dashGap) { dashes }
            }
        }
    }

    private var pillShape: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(Color.black.opacity(0.55))
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous).fill(.ultraThinMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .shadow(color: .black.opacity(0.22), radius: 6, y: 1)
    }
}

// MARK: - Fan

private struct EdgeFanColumn: View {
    let side: DeckSide
    let entries: [NoteMenuEntry]
    let pitch: CGFloat
    let itemLength: CGFloat
    let revealed: Bool
    let onNoteSelected: (UUID) -> Void
    let onNewNote: () -> Void

    private var spacing: CGFloat { pitch - itemLength } // negative: the lap

    var body: some View {
        Group {
            if side.isVertical {
                VStack(alignment: .trailing, spacing: spacing) { content }
                    .frame(width: DeckGeom.tabThick)
            } else {
                HStack(alignment: .bottom, spacing: spacing) { content }
                    .frame(height: DeckGeom.tabThick)
            }
        }
    }

    @ViewBuilder private var content: some View {
        if entries.isEmpty {
            EdgeTab(
                side: side,
                title: "NEW NOTE",
                theme: nil,
                itemLength: itemLength,
                strip: pitch,
                revealed: revealed,
                stagingIndex: 0,
                action: onNewNote
            )
        }
        ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
            EdgeTab(
                side: side,
                title: entry.title.isEmpty ? "Untitled" : entry.title,
                theme: entry.theme,
                itemLength: itemLength,
                strip: pitch,
                revealed: revealed,
                stagingIndex: index,
                action: { onNoteSelected(entry.id) }
            )
        }
        plusButton
            .padding(side.isVertical ? .top : .leading, DeckGeom.plusGap - spacing) // undo the lap
            .staged(index: entries.count, total: entries.count + 1, revealed: revealed, side: side)
    }

    private var plusButton: some View {
        Button(action: onNewNote) {
            Image(systemName: "plus")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.primary.opacity(0.75))
                .frame(width: DeckGeom.plusSize, height: DeckGeom.plusSize)
                .background(Circle().fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.22), radius: 5, y: 1))
                .contentShape(Circle())
        }
        .buttonStyle(EdgePressStyle())
    }
}

// MARK: - Tab

private struct EdgeTab: View {
    let side: DeckSide
    let title: String
    let theme: NoteTheme?
    let itemLength: CGFloat
    let strip: CGFloat          // the part of this tab the next one does not cover
    let revealed: Bool
    let stagingIndex: Int
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Group {
            if side.isVertical { verticalTab } else { horizontalTab }
        }
        .onTapGesture(perform: action)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.14), value: hovering)
        .staged(index: stagingIndex, total: stagingIndex + 1, revealed: revealed, side: side)
        .help(title)
    }

    private var paperColor: Color {
        theme?.backgroundColor ?? Color(nsColor: .controlBackgroundColor)
    }

    /// Vertical tab (left/right edges): label turned on its side.
    private var verticalTab: some View {
        ZStack(alignment: .top) {
            tabShape(radius: 11)
                .fill(paperColor)
                .shadow(color: .black.opacity(hovering ? 0.32 : 0.22), radius: hovering ? 9 : 6, x: shadowX, y: 2)

            Text(title.uppercased())
                .font(.system(size: DeckGeom.labelFontSize, weight: .semibold))
                .tracking(DeckGeom.labelTracking)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(Color.primary.opacity(0.85))
                .frame(width: max(20, strip - DeckGeom.labelInset), height: DeckGeom.tabThick)
                .rotationEffect(.degrees(side == .right ? 90 : -90))
                .frame(width: DeckGeom.tabThick, height: strip)
                .offset(x: side == .right ? -DeckGeom.bleed / 2 : DeckGeom.bleed / 2)
        }
        .frame(width: DeckGeom.tabThick + DeckGeom.bleed, height: itemLength, alignment: .top)
        .rotationEffect(.degrees(leanDegrees), anchor: leanAnchor)
        .offset(x: side == .right ? DeckGeom.bleed : -DeckGeom.bleed)
        .frame(width: DeckGeom.tabThick)
        .contentShape(Rectangle())
    }

    /// Horizontal tab (bottom edge): label reads normally, leaning like the sides.
    private var horizontalTab: some View {
        ZStack(alignment: .leading) {
            tabShape(radius: 11)
                .fill(paperColor)
                .shadow(color: .black.opacity(hovering ? 0.32 : 0.22), radius: hovering ? 9 : 6, x: 2, y: -2)

            Text(title.uppercased())
                .font(.system(size: DeckGeom.labelFontSize, weight: .semibold))
                .tracking(DeckGeom.labelTracking)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(Color.primary.opacity(0.85))
                .frame(width: max(20, strip - DeckGeom.labelInset), height: DeckGeom.tabThick)
        }
        .frame(width: itemLength, height: DeckGeom.tabThick + DeckGeom.bleed, alignment: .leading)
        .rotationEffect(.degrees(3.0), anchor: .bottomLeading)
        .offset(y: -DeckGeom.bleed)
        .frame(height: DeckGeom.tabThick)
        .contentShape(Rectangle())
    }

    private var shadowX: CGFloat { side == .right ? -3 : 3 }
    private var leanDegrees: Double { side == .right ? -3.0 : 3.0 }
    private var leanAnchor: UnitPoint { side == .right ? .trailing : .leading }

    /// Rounded on the outward-facing side only, so the tab reads as docked to the edge.
    private func tabShape(radius r: CGFloat) -> UnevenRoundedRectangle {
        switch side {
        case .right:
            return UnevenRoundedRectangle(topLeadingRadius: r, bottomLeadingRadius: r, bottomTrailingRadius: 0, topTrailingRadius: 0, style: .continuous)
        case .left:
            return UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: r, topTrailingRadius: r, style: .continuous)
        case .bottom:
            return UnevenRoundedRectangle(topLeadingRadius: r, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: r, style: .continuous)
        }
    }
}

// MARK: - Staging (the 42 ms shingle)

private struct EdgeStaged: ViewModifier {
    let index: Int
    let totalCount: Int
    let revealed: Bool
    let side: DeckSide

    func body(content: Content) -> some View {
        let delay = revealed
            ? Double(index) * 0.042
            : Double(max(0, totalCount - 1 - index)) * 0.030
        let hiddenOffset = DeckGeom.tabThick + 24
        content
            .offset(
                x: side == .right ? (revealed ? 0 : hiddenOffset) : side == .left ? (revealed ? 0 : -hiddenOffset) : 0,
                y: side == .bottom ? (revealed ? 0 : hiddenOffset) : 0
            )
            .opacity(revealed ? 1 : 0)
            .animation(.spring(response: 0.34, dampingFraction: 0.84).delay(delay), value: revealed)
    }
}

private extension View {
    func staged(index: Int, total: Int, revealed: Bool, side: DeckSide) -> some View {
        modifier(EdgeStaged(index: index, totalCount: total, revealed: revealed, side: side))
    }
}

private struct EdgePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
