import SwiftUI

/// A hinged envelope with a paper sheet that lifts out and becomes the offer surface.
struct GiftEnvelopeIllustration: View, Animatable {
    var progress: Double
    var letterLift: Double
    let paperExpanded: Bool
    let paperNamespace: Namespace.ID
    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(progress, letterLift) }
        set { progress = newValue.first; letterLift = newValue.second }
    }
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            ZStack(alignment: .topLeading) {
                // This same sheet lifts out and becomes the full-screen offer surface.
                if !paperExpanded {
                    GiftLetterPaper()
                        .frame(width: size * 0.52, height: size * 0.34)
                        .matchedGeometryEffect(id: "gift-offer-paper", in: paperNamespace)
                        .offset(x: size * 0.225, y: size * (0.34 + 0.085 * (1 - progress) - 0.38 * letterLift))
                        .zIndex(1)
                }
                EnvelopePaper()
                    .overlay {
                        EnvelopeFlap().fill(LinearGradient(
                            colors: [.white.opacity(0.12), .brown.opacity(0.07 + 0.12 * sin(.pi * progress))],
                            startPoint: .top, endPoint: .bottom))
                    }
                    .clipShape(EnvelopeFlap())
                    .overlay(EnvelopeFlap().stroke(Color(hex: 0xCFC1AC).opacity(0.65), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.06 + 0.12 * sin(.pi * progress)), radius: 0.8 + 2 * sin(.pi * progress), y: 0.8)
                    .frame(width: size * 0.74, height: size * 0.34)
                    .rotation3DEffect(.degrees(-180 * progress), axis: (x: 1, y: 0, z: 0), anchor: .top, perspective: 0.22)
                    .offset(x: size * 0.11, y: size * 0.415)
                    .zIndex(progress < 0.5 ? 2 : 0)
                Image("gift-prayer-envelope").resizable().scaledToFit()
                    .mask(EnvelopeFront())
                    .zIndex(3)
            }
            .scaleEffect(1 + 0.035 * progress, anchor: .center)
            .frame(width: size, height: size)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .accessibilityHidden(true)
    }
}

/// Use the original letter's paper grain for both sides of the flap, not a flat substitute.
private struct EnvelopePaper: View {
    var body: some View {
        GeometryReader { geometry in
            Image("gift-prayer-envelope").resizable()
                .frame(width: geometry.size.width / 0.38, height: geometry.size.height / 0.17)
                .offset(x: -geometry.size.width * 0.27 / 0.38, y: -geometry.size.height * 0.38 / 0.17)
        }.clipped()
    }
}

private struct EnvelopeFlap: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: .zero)
            p.addLine(to: CGPoint(x: rect.maxX, y: 0))
            p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.width * 0.72, y: rect.height * 0.55))
            p.addQuadCurve(to: .zero, control: CGPoint(x: rect.width * 0.28, y: rect.height * 0.55))
            p.closeSubpath()
        }
    }
}
private struct EnvelopeFront: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: 0, y: rect.height * 0.405))
            p.addLine(to: CGPoint(x: rect.width * 0.11, y: rect.height * 0.405))
            p.addLine(to: CGPoint(x: rect.width * 0.49, y: rect.height * 0.626))
            p.addLine(to: CGPoint(x: rect.width * 0.87, y: rect.height * 0.405))
            p.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.405))
            p.addLine(to: CGPoint(x: rect.width, y: rect.height))
            p.addLine(to: CGPoint(x: 0, y: rect.height))
            p.closeSubpath()
        }
    }
}
/// A real sheet of paper, retained as the offer background through matched geometry.
struct GiftLetterPaper: View {
    var body: some View {
        EnvelopePaper()
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color(hex: 0xD8CDBA), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.09), radius: 2, y: 1)
    }
}
