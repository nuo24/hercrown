import SwiftUI

/// Primary (filled) and secondary (outlined) capsule buttons in the neutral palette, never tinted green.
struct CapsuleButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary }
    var kind: Kind = .primary
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        let dark = scheme == .dark
        let fill: Color = kind == .primary ? (dark ? .white : Color(hex: 0x111111)) : (dark ? Color.white.opacity(0.08) : .white)
        let fg: Color = kind == .primary ? (dark ? Color(hex: 0x111111) : .white) : Theme.text(scheme)
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(fg)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Capsule().fill(fill))
            .overlay(Capsule().strokeBorder(kind == .secondary ? Theme.border(scheme) : .clear, lineWidth: 1))
            .shadow(color: .black.opacity(kind == .primary ? 0.14 : 0.05), radius: kind == .primary ? 10 : 6, y: 4)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Round outlined icon button used in headers and the reader toolbar.
struct IconButton: View {
    let systemName: String
    let label: String
    var filled = false
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Theme.text(scheme))
                .frame(width: 42, height: 42)
                .background(Circle().fill(filled ? Theme.supporting(scheme) : Theme.surface(scheme)))
                .overlay(Circle().strokeBorder(Theme.border(scheme), lineWidth: 0.8))
        }
        .accessibilityLabel(label)
    }
}

/// A raised neutral card (16pt continuous radius, layered soft shadow).
struct Card<Content: View>: View {
    var radius: CGFloat = Theme.Radius.card
    @ViewBuilder var content: Content
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        content
            .padding(Theme.Spacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(scheme == .dark ? Color.white.opacity(0.05) : .white))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(Theme.border(scheme).opacity(scheme == .dark ? 1 : 0.6), lineWidth: 0.6))
            .shadow(color: .black.opacity(scheme == .dark ? 0.35 : 0.06), radius: 14, y: 6)
    }
}

/// The reader's insights control: a magnifying lens with a small sparkle inside. No well, border or shadow.
struct InsightLens: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 24
        var p = Path()
        let o = CGPoint(x: rect.midX - 12 * s, y: rect.midY - 12 * s)
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: o.x + x * s, y: o.y + y * s) }
        p.addEllipse(in: CGRect(x: o.x + 3 * s, y: o.y + 3 * s, width: 15 * s, height: 15 * s))
        p.move(to: pt(16, 16)); p.addLine(to: pt(21, 21))
        // Four-point sparkle centred in the lens.
        p.move(to: pt(10.5, 6.8))
        p.addQuadCurve(to: pt(14.2, 10.5), control: pt(10.9, 10.1))
        p.addQuadCurve(to: pt(10.5, 14.2), control: pt(10.9, 10.9))
        p.addQuadCurve(to: pt(6.8, 10.5), control: pt(10.1, 10.9))
        p.addQuadCurve(to: pt(10.5, 6.8), control: pt(10.1, 10.1))
        return p
    }
}
