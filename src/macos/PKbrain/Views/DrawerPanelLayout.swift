import SwiftUI

/// Expand before painting the background. A minimum frame applied afterwards
/// leaves transparent margins around a shorter, centred stack (notably when
/// the strip is hidden), even though the NSPanel itself is correctly anchored.
struct DrawerPanelLayout: ViewModifier {
    let minimumWidth: CGFloat
    let minimumHeight: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(
                minWidth: minimumWidth, maxWidth: .infinity,
                minHeight: minimumHeight, maxHeight: .infinity,
                alignment: .top
            )
            .background(
                BottomRoundedRectangle(radius: 28)
                    .fill(Color(NSColor.windowBackgroundColor))
                    .overlay(
                        BottomRoundedRectangle(radius: 28)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 34, x: 0, y: 20)
            )
            .clipShape(BottomRoundedRectangle(radius: 28))
    }
}

private struct BottomRoundedRectangle: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let cornerRadius = min(radius, rect.width / 2, rect.height / 2)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - cornerRadius),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}
