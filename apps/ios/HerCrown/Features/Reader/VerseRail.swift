import SwiftUI

/// One persistent segment per verse down the left edge. The active segment is brighter and labelled; drag or tap to
/// jump. It never hides, and the hit area stays wide even when segments are tiny. VoiceOver: an adjustable control.
struct VerseRail: View {
    let verses: [Int]
    @Binding var current: Int
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        GeometryReader { geo in
            // .verse-rail: 4 pt bars filling the track (~4.5 pt apart), #d8d8de / active ink; the verse number sits 7 pt to
            // the right of the active bar; the chapter total 12 pt below the track.
            let count = max(verses.count, 1)
            let track = geo.size.height - 22
            let gap: CGFloat = count > 60 ? 1 : 4.5
            let segment = max((track - gap * CGFloat(count - 1)) / CGFloat(count), 0.6)
            let index = verses.firstIndex(of: current) ?? 0
            let dark = scheme == .dark
            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: gap) {
                    ForEach(Array(verses.enumerated()), id: \.offset) { i, _ in
                        RoundedRectangle(cornerRadius: 5)
                            .fill(i == index ? (dark ? Color(hex: 0xF5F5F5) : Color(hex: 0x111111)) : (dark ? Color(hex: 0x39393E) : Color(hex: 0xD8D8DE)))
                            .frame(width: 4, height: segment)
                    }
                }
                Text("\(current)")
                    .font(.system(size: 10, weight: .semibold)).monospacedDigit()
                    .foregroundStyle(dark ? Color(hex: 0xF5F5F5) : Color(hex: 0x263B32))
                    .offset(x: 11, y: CGFloat(index) * (segment + gap) + 2)
                Text("\(verses.last ?? count)")
                    .font(.system(size: 10)).monospacedDigit()
                    .foregroundStyle(Color(hex: 0x707B77))
                    .offset(y: track + 12)
            }
            .frame(width: 24, height: geo.size.height, alignment: .topLeading)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                let y = min(max(value.location.y, 0), track)
                let i = min(count - 1, Int(y / max(segment + gap, 0.1)))
                if verses.indices.contains(i), verses[i] != current { current = verses[i]; UISelectionFeedbackGenerator().selectionChanged() }
            })
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
