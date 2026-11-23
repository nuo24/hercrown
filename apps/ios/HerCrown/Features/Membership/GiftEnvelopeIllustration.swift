import SwiftUI

/// Original envelope artwork, layered with a hinged paper flap. No regenerated illustration.
struct GiftEnvelopeIllustration: View {
    let opening: Bool
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            ZStack(alignment: .topLeading) {
                Image("gift-prayer-envelope").resizable().scaledToFit()
                    .opacity(opening ? 1 : 0)
                EnvelopeFlap()
                    .fill(LinearGradient(colors: [Color(hex: 0xF7F0E3), Color(hex: 0xE7DBC7)], startPoint: .top, endPoint: .bottom))
                    .overlay(EnvelopeFlap().stroke(Color(hex: 0xD6C9B5), lineWidth: 0.6))
                    .shadow(color: .black.opacity(0.10), radius: 1, y: 1)
                    .frame(width: size * 0.76, height: size * 0.34)
                    .rotation3DEffect(.degrees(opening ? -175 : 0), axis: (x: 1, y: 0, z: 0), anchor: .top, perspective: 0.5)
                    .opacity(opening ? 0 : 1)
                    .offset(x: size * 0.11, y: size * 0.40)
                Image("gift-prayer-envelope").resizable().scaledToFit()
                    .mask(EnvelopeBody())
            }
            .offset(y: opening ? 0 : -size * 0.14)
            .frame(width: size, height: size)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .accessibilityHidden(true)
    }
}

private struct EnvelopeFlap: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: 0, y: 0))
            p.addLine(to: CGPoint(x: rect.maxX, y: 0))
            p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.width * 0.72, y: rect.height * 0.55))
            p.addQuadCurve(to: .zero, control: CGPoint(x: rect.width * 0.28, y: rect.height * 0.55))
            p.closeSubpath()
        }
    }
}
private struct EnvelopeBody: Shape {
    func path(in rect: CGRect) -> Path {
        // Preserve front paper folds, ribbon, bow, original cutout and baked shadow.
        Path { p in
            p.move(to: CGPoint(x: 0, y: rect.height * 0.40))
            p.addLine(to: CGPoint(x: rect.width * 0.11, y: rect.height * 0.40))
            p.addLine(to: CGPoint(x: rect.width * 0.49, y: rect.height * 0.58))
            p.addLine(to: CGPoint(x: rect.width * 0.87, y: rect.height * 0.40))
            p.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.40))
            p.addLine(to: CGPoint(x: rect.width, y: rect.height))
            p.addLine(to: CGPoint(x: 0, y: rect.height))
            p.closeSubpath()
        }
    }
}
