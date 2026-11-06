import SwiftUI

/// One persistent segment per verse down the left edge. The active segment is brighter and labelled; drag or tap to
/// jump. It never hides, and the hit area stays wide even when segments are tiny. VoiceOver: an adjustable control.
struct VerseRail: View {
    let verses: [Int]
    @Binding var current: Int
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var focus: CGFloat?
    @State private var feedback = UISelectionFeedbackGenerator()

    var body: some View {
        GeometryReader { geo in
            // .verse-rail: 4 pt bars filling the track (~4.5 pt apart), #d8d8de / active ink; the verse number sits 7 pt to
            // the right of the active bar; the chapter total 12 pt below the track.
            let count = max(verses.count, 1)
            let track = max(0, geo.size.height - 22)
            let gap = count == 1 ? 0 : min(5, track / (CGFloat(count) * 4))
            let segment = max((track - gap * CGFloat(count - 1)) / CGFloat(count), 0)
            let index = verses.firstIndex(of: current) ?? 0
            let dark = scheme == .dark
            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: gap) {
                    ForEach(Array(verses.enumerated()), id: \.offset) { i, _ in
                        let distance = (CGFloat(i) - (focus ?? CGFloat(index))) / 1.1
                        let scale = reduceMotion ? 1 : 1 + 0.8 * exp(-0.5 * distance * distance)
                        RoundedRectangle(cornerRadius: 5)
                            .fill(i == index ? Theme.text(scheme) : (dark ? Color(hex: 0x4D4D4D) : Color(hex: 0xD8D8DE)))
                            .frame(width: 4, height: segment)
                            .scaleEffect(x: scale, y: 1 + (scale - 1) * 0.16, anchor: .leading)
                            .animation(reduceMotion ? nil : .easeOut(duration: 0.14), value: scale)
                    }
                }
                Text("\(current)")
                    .font(.ui(10, weight: .medium)).monospacedDigit()
                    .foregroundStyle(dark ? Color(hex: 0xF5F5F5) : Theme.text(scheme))
                    .offset(x: 10, y: CGFloat(index) * (segment + gap) + segment / 2 - 6)
                Text("\(verses.last ?? count)")
                    .font(.ui(10)).monospacedDigit()
                    .foregroundStyle(Theme.muted(scheme))
                    .offset(y: track + 12)
            }
            .frame(width: 24, height: geo.size.height, alignment: .topLeading)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                let y = min(max(value.location.y, 0), track)
                let i = min(count - 1, Int(y / max(segment + gap, 0.1)))
                focus = y / max(segment + gap, 0.1) - 0.5
                if verses.indices.contains(i), verses[i] != current {
                    current = verses[i]
                    feedback.selectionChanged()
                    feedback.prepare()
                }
            }.onEnded { _ in focus = nil })
        }
        .frame(width: 24)
        .accessibilityElement()
        .accessibilityLabel("Verse")
        .accessibilityValue("\(current) of \(verses.last ?? 0)")
        .accessibilityAdjustableAction { direction in
            guard let i = verses.firstIndex(of: current) else { return }
            switch direction {
            case .increment: if i + 1 < verses.count { current = verses[i + 1] }
            case .decrement: if i > 0 { current = verses[i - 1] }
            @unknown default: break
            }
        }
    }
}
