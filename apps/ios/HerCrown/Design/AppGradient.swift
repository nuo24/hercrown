import SwiftUI

/// The shared sage/sky background (reference-web/dist/gradient-theme.js), used by every screen, Settings and the paywall.
/// Each colour is a CSS `radial-gradient(ellipse at X Y, color 0%, transparent reach%)` with the default
/// farthest-corner size, drawn over a linear base at `angle` degrees.
struct GradientSettings: Codable, Equatable {
    var colors: [UInt32] = [0xE4EDDF, 0xE0EDF5, 0xEADFF0]
    var third = false
    var intensity: Double = 100   // %
    var reach: Double = 49        // % of the ellipse radius where the colour fades out
    var angle: Double = 165       // CSS degrees: 0 = to top, 90 = to right

    static let shipped = GradientSettings()
}

struct AppGradient: View {
    var settings: GradientSettings = .shipped
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Canvas { context, size in
            let dark = scheme == .dark
            let rect = CGRect(origin: .zero, size: size)
            // Base: linear gradient along the CSS angle, spanning the box's projection on that direction.
            let radians = settings.angle * .pi / 180
            let direction = CGVector(dx: sin(radians), dy: -cos(radians))
            let half = (abs(size.width * direction.dx) + abs(size.height * direction.dy)) / 2
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let start = CGPoint(x: center.x - direction.dx * half, y: center.y - direction.dy * half)
            let end = CGPoint(x: center.x + direction.dx * half, y: center.y + direction.dy * half)
            let base = dark ? [Color(hex: 0x101314), Color(hex: 0x121619)] : [Color.white, Color(hex: 0xF5F8F7)]
            context.fill(Path(rect), with: .linearGradient(Gradient(colors: base), startPoint: start, endPoint: end))

            let alpha = settings.intensity / 100 * (dark ? 0.20 : 1)
            var spots: [(CGPoint, UInt32, Double)] = [
                (CGPoint(x: 0, y: 0.14), settings.colors[0], alpha),
                (CGPoint(x: 1, y: 0.74), settings.colors[1], alpha),
            ]
            if settings.third { spots.append((CGPoint(x: 0.52, y: 1), settings.colors[2], alpha * 0.8)) }
            // CSS paints the first layer on top, so draw in reverse.
            for (point, hex, a) in spots.reversed() {
                let c = CGPoint(x: point.x * size.width, y: point.y * size.height)
                // farthest-corner ellipse: farthest-side radii scaled by √2.
                let rx = max(c.x, size.width - c.x) * 2.squareRoot()
                let ry = max(c.y, size.height - c.y) * 2.squareRoot()
                var layer = context
                layer.translateBy(x: c.x, y: c.y)
                layer.scaleBy(x: rx, y: ry)
                let color = Color(hex: hex, opacity: a)
                layer.fill(Path(ellipseIn: CGRect(x: -1, y: -1, width: 2, height: 2)),
                           with: .radialGradient(Gradient(stops: [.init(color: color, location: 0), .init(color: color.opacity(0), location: settings.reach / 100)]),
                                                 center: .zero, startRadius: 0, endRadius: 1))
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// The soft cloud bank behind onboarding and the paywall: low on the screen, behind legible content. It fills its
/// own frame and is clipped, so it never widens the layout around it.
struct CloudAtmosphere: View {
    var body: some View {
        GeometryReader { geo in
            Image("cloud-bank")
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height * 0.5)
                .clipped()
                .opacity(0.6)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
