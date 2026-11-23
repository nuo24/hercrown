import SwiftUI

/// One stationary envelope. Only its hinged flap moves; the front and bow never jump.
struct GiftEnvelopeIllustration: View, Animatable {
    var progress: Double
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            ZStack(alignment: .topLeading) {
                // The letter is revealed behind the opening flap, never swapped with a second envelope.
                Image("gift-prayer-envelope").resizable().scaledToFit()
                    .mask(EnvelopeLetter())
                    .opacity(min(1, max(0, (progress - 0.5) * 3)))
                EnvelopeFlap()
                    .fill(LinearGradient(colors: [Color(hex: 0xF7F0E3), Color(hex: 0xE7DBC7)], startPoint: .top, endPoint: .bottom))
                    .overlay(EnvelopeFlap().stroke(Color(hex: 0xD6C9B5), lineWidth: 0.6))
                    .overlay {
                        Canvas { context, canvas in
                            // Subtle paper fibres, stable throughout the hinge movement.
                            for i in 0..<450 {
                                let x = Double((i * 73) % 449) / 449 * canvas.width
                                let y = Double((i * 131) % 443) / 443 * canvas.height
                                var fibre = Path()
                                fibre.move(to: CGPoint(x: x, y: y))
                                fibre.addLine(to: CGPoint(x: x + 1.5, y: y + 0.3))
                                context.stroke(fibre, with: .color(.brown.opacity(0.08)), lineWidth: 0.4)
                            }
                        }.clipShape(EnvelopeFlap())
                    }
                    .shadow(color: .black.opacity(0.10), radius: 1.2, y: 1)
                    .frame(width: size * 0.74, height: size * 0.34)
                    .rotation3DEffect(.degrees(-180 * progress), axis: (x: 1, y: 0, z: 0), anchor: .top, perspective: 0.22)
                    .offset(x: size * 0.11, y: size * 0.415)
                Image("gift-prayer-envelope").resizable().scaledToFit()
                    .mask(EnvelopeFront())
            }
            .frame(width: size, height: size)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .accessibilityHidden(true)
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
private struct EnvelopeLetter: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.width * 0.225, y: rect.height * 0.342))
            p.addLine(to: CGPoint(x: rect.width * 0.745, y: rect.height * 0.322))
            p.addLine(to: CGPoint(x: rect.width * 0.745, y: rect.height * 0.63))
            p.addLine(to: CGPoint(x: rect.width * 0.225, y: rect.height * 0.63))
            p.closeSubpath()
        }
    }
}
