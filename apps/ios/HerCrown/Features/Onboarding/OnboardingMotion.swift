import SwiftUI
import UIKit

/// The entrance is scoped to a page. Selection changes leave the same task and layout in place.
@MainActor
struct OnboardingEntrance {
    private(set) var revealed: Int?
    private(set) var started = false
    let feedback = UISelectionFeedbackGenerator()
    let impact = UIImpactFeedbackGenerator(style: .light)

    mutating func begin() {
        revealed = 0
        started = true
        feedback.prepare()
    }

    mutating func reveal(_ count: Int) {
        revealed = count
        if count % 2 == 1 {
            feedback.selectionChanged()
            feedback.prepare()
        }
    }

    mutating func settle() { revealed = nil }

    func confirm() {
        impact.prepare()
        impact.impactOccurred()
    }
}

struct OnboardingCollage: View {
    let size: CGSize
    let animate: Bool
    // Normalized masks, offsets and pivots from the frozen onboarding motion stylesheet.
    private static let pieces: [Piece] = [
        .init(points: rect(0, 0, 0.4, 0.28), x: -18, y: -12, rotation: -4, pivot: .init(x: 0.15, y: 0.12)),
        .init(points: [.init(x: 0.4, y: 0), .init(x: 1, y: 0), .init(x: 1, y: 0.24), .init(x: 0.7, y: 0.24), .init(x: 0.7, y: 0.17), .init(x: 0.4, y: 0.17)], x: 18, y: -14, rotation: 4, pivot: .init(x: 0.8, y: 0.1)),
        .init(points: rect(0.4, 0.17, 0.7, 0.24), x: 0, y: 16, rotation: 8, pivot: .init(x: 0.6, y: 0.2)),
        .init(points: rect(0, 0.28, 0.4, 0.46), x: -18, y: 8, rotation: -5, pivot: .init(x: 0.1, y: 0.37)),
        .init(points: rect(0.6, 0.24, 1, 0.46), x: 18, y: 8, rotation: 4, pivot: .init(x: 0.9, y: 0.32)),
        .init(points: rect(0, 0.46, 0.5, 0.82), x: -16, y: 18, rotation: -3, pivot: .init(x: 0.15, y: 0.65)),
        .init(points: rect(0.5, 0.46, 1, 0.82), x: 18, y: 14, rotation: 3, pivot: .init(x: 0.85, y: 0.65)),
    ]

    var body: some View {
        ZStack {
            if animate {
                ForEach(Self.pieces.indices, id: \.self) { index in
                    let piece = Self.pieces[index]
                    art.clipShape(piece)
                        .modifier(OnboardingArtEntry(delay: Double(index) * 0.12, duration: 0.56,
                                                     x: piece.x, y: piece.y, rotation: piece.rotation, pivot: piece.pivot))
                }
            } else { art }
        }
        .frame(width: size.width / 1.04, height: size.height, alignment: .top)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private var art: some View {
        Image.illustration("onboarding-collage").resizable().frame(width: size.width, height: size.height)
    }

    private static func rect(_ left: CGFloat, _ top: CGFloat, _ right: CGFloat, _ bottom: CGFloat) -> [CGPoint] {
        [.init(x: left, y: top), .init(x: right, y: top), .init(x: right, y: bottom), .init(x: left, y: bottom)]
    }

    private struct Piece: Shape {
        let points: [CGPoint]
        let x: CGFloat
        let y: CGFloat
        let rotation: Double
        let pivot: UnitPoint

        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.addLines(points.map { CGPoint(x: $0.x * rect.width, y: $0.y * rect.height) })
            path.closeSubpath()
            return path
        }
    }
}

struct OnboardingArtEntry: ViewModifier {
    var delay = 0.0
    var duration = 0.64
    var x: CGFloat = 14
    var y: CGFloat = 12
    var rotation = 6.0
    var pivot: UnitPoint = .center
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var phase = 0
    @State private var completed = false

    func body(content: Content) -> some View {
        let stable = completed || reduceMotion
        content
            .opacity(stable || phase > 0 ? 1 : 0)
            .scaleEffect(stable || phase == 2 ? 1 : phase == 1 ? 1.012 : 0.94, anchor: pivot)
            .rotationEffect(.degrees(stable || phase > 0 ? 0 : rotation), anchor: pivot)
            .offset(x: stable || phase > 0 ? 0 : x, y: stable || phase == 2 ? 0 : phase == 1 ? -2 : y)
            .task(id: scenePhase == .active && !reduceMotion) {
                guard !completed else { return }
                guard !reduceMotion else { completed = true; return }
                guard scenePhase == .active else { return }
                do {
                    try await Task.sleep(for: .seconds(delay))
                    withAnimation(.easeOut(duration: duration * 0.75)) { phase = 1 }
                    try await Task.sleep(for: .seconds(duration * 0.75))
                    withAnimation(.easeOut(duration: duration * 0.25)) { phase = 2 }
                    completed = true
                } catch { }
            }
    }
}

struct OnboardingCopyEntry: ViewModifier {
    let delay: Double
    var duration = 0.24
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var entered = false

    func body(content: Content) -> some View {
        let visible = entered || reduceMotion || scenePhase != .active
        content
            .opacity(visible ? 1 : 0.15)
            .offset(y: visible ? 0 : 5)
            .task(id: scenePhase == .active && !reduceMotion) {
                guard !entered else { return }
                guard scenePhase == .active, !reduceMotion else { entered = true; return }
                do {
                    try await Task.sleep(for: .seconds(delay))
                    withAnimation(.easeOut(duration: duration)) { entered = true }
                } catch { }
            }
    }
}
