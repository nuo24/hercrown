import SwiftUI
import UIKit

/// A hinged envelope with a paper sheet that lifts out and becomes the offer surface.
struct GiftEnvelopeIllustration: View, Animatable {
    var progress: Double
    var letterLift: Double
    let paperInFlight: Bool
    let foldedAspect: Double
    let offerSnapshot: UIImage?
    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(progress, letterLift) }
        set { progress = newValue.first; letterLift = newValue.second }
    }
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            ZStack(alignment: .topLeading) {
                // This same sheet lifts out and becomes the full-screen offer surface.
                GiftLetterPaper(offerSnapshot: offerSnapshot)
                    .frame(width: size * 0.52, height: size * 0.52 * foldedAspect)
                    .anchorPreference(key: GiftLetterBounds.self, value: .bounds) { $0 }
                    .opacity(paperInFlight ? 0 : 1)
                    .offset(x: size * 0.225, y: size * (0.34 + 0.085 * (1 - progress) - 0.38 * letterLift))
                    .zIndex(1)
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
/// One folded panel has the same material and proportions as the sheet it opens into.
struct GiftLetterPaper: View {
    let offerSnapshot: UIImage?
    var body: some View {
        GiftPaperMaterial()
            .overlay {
                if let offerSnapshot {
                    // The middle third is the outside panel of the folded offer sheet.
                    GeometryReader { geometry in
                        Image(uiImage: offerSnapshot).resizable()
                            .frame(width: geometry.size.width, height: geometry.size.height * 3)
                            .offset(y: -geometry.size.height)
                    }.clipped()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 1.5))
            .overlay(RoundedRectangle(cornerRadius: 1.5).stroke(Color(hex: 0xD8CDBA), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.09), radius: 2, y: 1)
    }
}

struct GiftLetterBounds: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? { nil }
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue() ?? value
    }
}

/// Tile a clean paper patch at fixed scale. Grain never stretches when a fold opens.
struct GiftPaperMaterial: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        Color(hex: scheme == .dark ? 0x111010 : 0xFEFCF8)
            .overlay {
                Rectangle().fill(ImagePaint(image: Image("gift-prayer-envelope"),
                    sourceRect: CGRect(x: 0.36, y: 0.36, width: 0.26, height: 0.12), scale: 0.32))
                    .opacity(scheme == .dark ? 0.025 : 0.07)
            }
    }
}

/// Three rigid panels, joined at real hinges; only the camera scale changes during flight.
struct GiftUnfoldingSheet<Content: View>: View, Animatable {
    let source: CGRect
    let target: CGSize
    var flight: Double
    var unfolding: Double
    var settled: Double
    @ViewBuilder let content: () -> Content
    var animatableData: AnimatablePair<AnimatablePair<Double, Double>, Double> {
        get { .init(.init(flight, unfolding), settled) }
        set { flight = newValue.first.first; unfolding = newValue.first.second
            settled = newValue.second }
    }
    var body: some View {
        let panelHeight = target.height / 3
        let top = min(1, max(0, unfolding / 0.85))
        let bottom = min(1, max(0, (unfolding - 0.12) / 0.88))
        let angle = 7.0 * Double.pi / 180
        let sourceWidth = source.width / (cos(angle) + panelHeight / target.width * sin(angle))
        let scale = sourceWidth / target.width + (1 - sourceWidth / target.width) * flight
        ZStack(alignment: .top) {
            panel(1).offset(y: panelHeight).zIndex(1)
            panel(2, showsInk: bottom >= 0.5)
                .overlay(Color.black.opacity(0.10 * sin(.pi * bottom)))
                .shadow(color: .black.opacity(0.12 * (1 - bottom)), radius: 5, y: -2)
                .rotation3DEffect(.degrees(180 * (1 - bottom)), axis: (x: 1, y: 0, z: 0), anchor: .top, perspective: 0.18)
                .offset(y: 2 * panelHeight)
                .zIndex(bottom < 0.5 ? 0 : 2)
            panel(0, showsInk: top >= 0.5)
                .overlay(Color.black.opacity(0.12 * sin(.pi * top)))
                .shadow(color: .black.opacity(0.14 * (1 - top)), radius: 5, y: 2)
                .rotation3DEffect(.degrees(-180 * (1 - top)), axis: (x: 1, y: 0, z: 0), anchor: .bottom, perspective: 0.18)
                .zIndex(top < 0.5 ? 0 : 3)
        }
        .frame(width: target.width, height: target.height, alignment: .top)
        .rotationEffect(.degrees(-7 * (1 - flight)))
        .scaleEffect(scale)
        .position(x: source.midX + (target.width / 2 - source.midX) * flight,
                  y: source.midY + (target.height / 2 - source.midY) * flight)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
    private func panel(_ index: Int, showsInk: Bool = true) -> some View {
        ZStack(alignment: .top) {
            GiftPaperMaterial()
            content().frame(width: target.width, height: target.height)
                .offset(y: -Double(index) * target.height / 3)
                .opacity(showsInk ? 1 : 0)
        }
        .frame(width: target.width, height: target.height / 3, alignment: .top)
        .clipped()
        .overlay(alignment: index == 0 ? .bottom : .top) {
            Rectangle().fill(Color.black.opacity(0.07 * (1 - settled))).frame(height: 0.5)
        }
    }
}
