import SwiftUI
import CoreText
import Observation

/// Design tokens: the final computed values of the reference mockup (reference-web/dist, light and dark), measured at
/// iPhone width. Neutral palette; Baskerville for Scripture and editorial accents; the system sans for UI.
@Observable final class AppearancePalette {
    static let shared = AppearancePalette(preview: launchPreview)
    var selection = "light"
    private var preview: String?

    init(preview: String? = nil) {
        self.preview = preview.flatMap { ["light", "dark", "pink", "system"].contains($0) ? $0 : nil }
    }

    var resolvedSelection: String { preview ?? selection }
    var pink: Bool { resolvedSelection == "pink" }

    /// A deliberate Settings choice takes precedence over screenshot-only launch arguments.
    func choose(_ appearance: String) {
        preview = nil
        selection = appearance
    }

    private static var launchPreview: String? {
        #if DEBUG
        UserDefaults.standard.string(forKey: "hcPreviewAppearance")
        #else
        nil
        #endif
    }
}

enum Theme {
    static func pink(_ scheme: ColorScheme) -> Bool { scheme == .light && AppearancePalette.shared.pink }
    static func feature(_ scheme: ColorScheme) -> Color { pink(scheme) ? Color(hex: 0xF3DFE7) : supporting(scheme) }
    static func accent(_ scheme: ColorScheme) -> Color { pink(scheme) ? Color(hex: 0x31222B) : text(scheme) }
    static func onAccent(_ scheme: ColorScheme) -> Color { pink(scheme) ? Color(hex: 0xFFF9FB) : canvas(scheme) }

    static func canvas(_ scheme: ColorScheme) -> Color { pink(scheme) ? Color(hex: 0xFBF1F4) : scheme == .dark ? .black : .white }
    enum Spacing { static let xs: CGFloat = 4, s: CGFloat = 8, m: CGFloat = 12, l: CGFloat = 16, xl: CGFloat = 20, gutter: CGFloat = 20, xxl: CGFloat = 32 }
    enum Radius { static let card: CGFloat = 16, group: CGFloat = 18, feature: CGFloat = 20, badge: CGFloat = 6, field: CGFloat = 8 }

    /// --text-primary: #111 / #f5f5f5
    static func text(_ scheme: ColorScheme) -> Color { pink(scheme) ? Color(hex: 0x31222B) : scheme == .dark ? Color(hex: 0xF5F5F5) : Color(hex: 0x111111) }
    /// --text-muted: #717177 / #acacb2
    static func muted(_ scheme: ColorScheme) -> Color { pink(scheme) ? Color(hex: 0x654F5B) : scheme == .dark ? Color(hex: 0xB1B1B1) : Color(hex: 0x656565) }
    /// --surface-primary: #fff / #141416
    static func surface(_ scheme: ColorScheme) -> Color { pink(scheme) ? Color(hex: 0xFFF9FB) : scheme == .dark ? Color(hex: 0x131313) : .white }
    /// --surface-secondary: #f2f2f4 / #1d1d20
    static func supporting(_ scheme: ColorScheme) -> Color { pink(scheme) ? Color(hex: 0xF3DFE7) : scheme == .dark ? Color(hex: 0x242424) : Color(hex: 0xF2F2F4) }
    /// --border-subtle: #e5e5e8 / #2e2e32
    static func border(_ scheme: ColorScheme) -> Color { pink(scheme) ? Color(hex: 0xE0C4CF) : scheme == .dark ? Color(hex: 0x303030) : Color(hex: 0xE5E5E5) }
    /// Streak accent (flame and count): #745634 / #e3be87
    static func streak(_ scheme: ColorScheme) -> Color { scheme == .dark ? Color(hex: 0xE3BE87) : Color(hex: 0x745634) }
    /// A read day in the streak week: #344a40
    static let readDay = Color(hex: 0x344A40)
    static let wordsOfJesus = Color(red: 0.78, green: 0.16, blue: 0.16)
    static let wordsOfJesusDark = Color(red: 1.0, green: 0.48, blue: 0.45)
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB, red: Double(hex >> 16 & 0xFF) / 255, green: Double(hex >> 8 & 0xFF) / 255, blue: Double(hex & 0xFF) / 255, opacity: opacity)
    }
}

enum AppFonts {
    static let register: Void = {
        for name in ["dm-sans-400", "dm-sans-500"] {
            if let url = Bundle.main.url(forResource: name, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }()
}

extension Font {
    static func ui(_ size: CGFloat, weight: Font.Weight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
        _ = AppFonts.register
        let name = weight == .regular ? "DMSans-Regular" : "DMSans-Medium"
        return .custom(name, size: size, relativeTo: style)
    }

    /// Baskerville (regular / italic), scaled with Dynamic Type relative to `style`.
    static func serif(_ size: CGFloat, italic: Bool = false, weight: Font.Weight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
        let heavy = weight == .semibold || weight == .bold
        let name = italic ? (heavy ? "Baskerville-SemiBoldItalic" : "Baskerville-Italic") : (heavy ? "Baskerville-SemiBold" : "Baskerville")
        return .custom(name, size: size, relativeTo: style)
    }

}

/// Reader text sizes for Settings → Font size.
enum ReaderFontSize: String, CaseIterable {
    case `default`, large, larger, largest
    var points: CGFloat { switch self { case .default: 28; case .large: 34; case .larger: 38; case .largest: 43 } }
    var title: String { switch self { case .default: "Default"; case .large: "Large"; case .larger: "Larger"; case .largest: "Largest" } }
}
