import SwiftUI

/// Buttons from the mockup's cascade. Primary: ink fill, 48 tall, 14 pt. Secondary: surface fill with a 1 pt ink ring,
/// 40 tall, 13 pt. Both fully rounded and never tinted.
struct CapsuleButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary }
    var kind: Kind = .primary
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        let primary = kind == .primary
        let fill: Color = primary ? Theme.text(scheme) : Theme.surface(scheme)
        let fg: Color = primary ? (scheme == .dark ? Color(hex: 0x080809) : Color(hex: 0xF7F7F9)) : Theme.text(scheme)
        configuration.label
            .font(.system(size: primary ? 14 : 13))
            .foregroundStyle(fg)
            .frame(maxWidth: .infinity, minHeight: primary ? 48 : 40)
            .padding(.horizontal, primary ? 20 : 6)
            .background(Capsule().fill(fill))
            .overlay(Capsule().strokeBorder(primary ? .clear : Theme.text(scheme), lineWidth: 1))
            .shadow(color: .black.opacity(primary ? 0.07 : 0.03), radius: 1, y: 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// .iconbtn: 44 pt surface circle with a hairline ring and a soft lift.
struct IconButton: View {
    let systemName: String
    let label: String
    var filled = false
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Theme.text(scheme))
                .frame(width: 44, height: 44)
                .iconSurface(Circle())
        }
        .accessibilityLabel(label)
    }
}

extension View {
    /// The icon-button surface (.iconbtn): fill, inset hairline, small two-layer shadow.
    func iconSurface<S: InsettableShape>(_ shape: S) -> some View { modifier(IconSurface(shape: shape)) }
}

private struct IconSurface<S: InsettableShape>: ViewModifier {
    let shape: S
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        let dark = scheme == .dark
        content
            .background(shape.fill(Theme.surface(scheme)))
            .overlay(shape.strokeBorder(dark ? Color.white.opacity(0.125) : Color.black.opacity(0.06), lineWidth: 1))
            .shadow(color: .black.opacity(dark ? 0.267 : 0.03), radius: 2, y: 2)
            .shadow(color: .black.opacity(dark ? 0 : 0.04), radius: 1, y: 1)
    }
}

/// .surface card: 16 pt continuous radius, hairline ring, layered soft shadow (light and dark values from the mockup).
struct Card<Content: View>: View {
    var radius: CGFloat = Theme.Radius.card
    var padding: EdgeInsets = EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
    @ViewBuilder var content: Content
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .surfaceCard(radius: radius)
    }
}

extension View {
    /// The mockup's .surface: fill, 1 pt ring, two soft shadows.
    func surfaceCard(radius: CGFloat = Theme.Radius.card, fill: AnyShapeStyle? = nil) -> some View { modifier(SurfaceCard(radius: radius, fill: fill)) }
}

private struct SurfaceCard: ViewModifier {
    let radius: CGFloat
    let fill: AnyShapeStyle?
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        let dark = scheme == .dark
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .background(shape.fill(fill ?? AnyShapeStyle(Theme.surface(scheme))))
            .overlay(shape.strokeBorder(dark ? Color.white.opacity(0.07) : Color(red: 21 / 255, green: 21 / 255, blue: 27 / 255, opacity: 0.047), lineWidth: 1))
            .shadow(color: .black.opacity(dark ? 0.267 : 0.03), radius: 2, y: 2)
            .shadow(color: .black.opacity(dark ? 0.4 : 0.04), radius: 6, y: 6)
    }
}

/// .version-badge: small rounded label (translation, topic).
struct Badge: View {
    let text: String
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        Text(text).font(.system(size: 11)).tracking(0.3)
            .foregroundStyle(Theme.muted(scheme))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.badge).fill(Theme.supporting(scheme)))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.badge).strokeBorder(Theme.border(scheme), lineWidth: 1))
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
