import SwiftUI

/// One persistent segment per verse down the left edge. The active segment is brighter and labelled; drag or tap to
/// jump. It never hides, and the hit area stays wide even when segments are tiny. VoiceOver: an adjustable control.
struct VerseRail: View {
    let verses: [Int]
    @Binding var current: Int
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        GeometryReader { geo in
            let count = max(verses.count, 1)
            let gap: CGFloat = count > 60 ? 0.5 : 2
            let segment = max((geo.size.height - 20 - gap * CGFloat(count - 1)) / CGFloat(count), 0.6)
            let index = verses.firstIndex(of: current) ?? 0
            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: gap) {
                    ForEach(Array(verses.enumerated()), id: \.offset) { i, _ in
                        Capsule()
                            .fill(Theme.text(scheme).opacity(i == index ? 0.95 : 0.22))
                            .frame(width: i == index ? 5 : 3, height: i == index ? max(segment, 10) : segment)
                    }
                }
                Text("\(current)")
                    .font(.system(size: 10, weight: .semibold)).monospacedDigit()
                    .foregroundStyle(Theme.text(scheme))
                    .offset(x: 9, y: CGFloat(index) * (segment + gap) - 2)
                Text("\(verses.last ?? count)")
                    .font(.system(size: 10)).monospacedDigit()
                    .foregroundStyle(Theme.muted(scheme))
                    .offset(y: geo.size.height - 12)
            }
            .frame(width: 30, height: geo.size.height, alignment: .topLeading)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                let y = min(max(value.location.y, 0), geo.size.height - 20)
                let i = min(count - 1, Int(y / max(segment + gap, 0.1)))
                if verses.indices.contains(i), verses[i] != current { current = verses[i]; UISelectionFeedbackGenerator().selectionChanged() }
            })
        }
        .frame(width: 30)
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
