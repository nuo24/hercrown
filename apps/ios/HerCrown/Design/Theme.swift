import SwiftUI

/// Design tokens from specs/CURRENT-DESIGN.md: neutral palette, Baskerville for Scripture and editorial accents,
/// the system sans for UI, spacing 4–48, continuous radii.
enum Theme {
    enum Spacing { static let xs: CGFloat = 4, s: CGFloat = 8, m: CGFloat = 12, l: CGFloat = 16, xl: CGFloat = 20, gutter: CGFloat = 24, xxl: CGFloat = 32 }
    enum Radius { static let card: CGFloat = 16, group: CGFloat = 18, feature: CGFloat = 20 }

    static func text(_ scheme: ColorScheme) -> Color { scheme == .dark ? .white : Color(hex: 0x111111) }
    static func muted(_ scheme: ColorScheme) -> Color { scheme == .dark ? Color.white.opacity(0.62) : Color(hex: 0x717177) }
    static func surface(_ scheme: ColorScheme) -> Color { scheme == .dark ? Color.white.opacity(0.06) : .white }
    static func supporting(_ scheme: ColorScheme) -> Color { scheme == .dark ? Color.white.opacity(0.10) : Color(hex: 0xF2F2F4) }
    static func border(_ scheme: ColorScheme) -> Color { scheme == .dark ? Color.white.opacity(0.12) : Color(hex: 0xE5E5E8) }
    static let wordsOfJesus = Color(red: 0.78, green: 0.16, blue: 0.16)
    static let wordsOfJesusDark = Color(red: 1.0, green: 0.48, blue: 0.45)
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB, red: Double(hex >> 16 & 0xFF) / 255, green: Double(hex >> 8 & 0xFF) / 255, blue: Double(hex & 0xFF) / 255, opacity: opacity)
    }
}

extension Font {
    /// Baskerville (regular / italic), scaled with Dynamic Type relative to `style`.
    static func serif(_ size: CGFloat, italic: Bool = false, weight: Font.Weight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(italic ? "Baskerville-Italic" : (weight == .semibold || weight == .bold ? "Baskerville-SemiBold" : "Baskerville"), size: size, relativeTo: style)
    }
}

/// Reader text sizes for Settings → Font size.
enum ReaderFontSize: String, CaseIterable {
    case `default`, large, larger, largest
    var points: CGFloat { switch self { case .default: 31; case .large: 35; case .larger: 39; case .largest: 44 } }
    var title: String { switch self { case .default: "Default"; case .large: "Large"; case .larger: "Larger"; case .largest: "Largest" } }
}
