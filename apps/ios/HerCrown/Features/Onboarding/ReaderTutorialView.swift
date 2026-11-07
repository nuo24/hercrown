import SwiftUI

/// A short, skippable guide before first reading; replayable without resetting the account.
struct ReaderTutorialView: View {
    let entryPoint: String
    let onFinish: (_ skipped: Bool) -> Void
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @State private var finished = false

    init(entryPoint: String, onFinish: @escaping (Bool) -> Void) {
        self.entryPoint = entryPoint
        self.onFinish = onFinish
        #if DEBUG
        _page = State(initialValue: min(max(UserDefaults.standard.integer(forKey: "hcTutorialPage"), 0), 3))
        #endif
    }

    private let titles = ["One verse. A little space.", "Keep the words you love.", "Go a little deeper.", "Find your everyday rhythm."]
    private let artwork = ["open-book", "bookmark", "magnifier", "lantern"]
    private let copy = [
        "Swipe up for the next verse. Keep swiping into the next chapter, or swipe down to go back. Tap the chapter name to jump to another book.",
        "Tap the heart to save a passage. Use the bookmark to keep your place, and the note button to write a thought, prayer or question.",
        "Tap the magnifying glass for Explain Easier, Deeper Study, Original Language and Related Verses. These are Plus tools; Bible reading stays free.",
        "Discover helps you find passages for the season you’re in. Home keeps your daily verse, reading rhythm, notes and plans close at hand."
    ]

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                if page > 0 { Button("Back") { move(to: page - 1) } }
                Spacer()
                Button("Skip tour") { finish(skipped: true) }
            }
            .font(.ui(13, weight: .medium)).buttonStyle(.plain).frame(minHeight: 44)
            TabView(selection: $page) {
                ForEach(0..<titles.count, id: \.self) { index in
                    ScrollView {
                        VStack(spacing: 24) {
                            Image.illustration(artwork[index]).resizable().scaledToFit()
                                .frame(width: 100, height: 100).accessibilityHidden(true)
                            Text(titles[index]).font(.serif(32, relativeTo: .largeTitle))
                                .accessibilityAddTraits(.isHeader)
                            Text(copy[index]).font(.ui(15)).lineSpacing(5)
                                .foregroundStyle(Theme.muted(scheme))
                            example(index)
                        }
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity).padding(.vertical, 28)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            HStack(spacing: 8) {
                ForEach(0..<titles.count, id: \.self) { index in
                    Circle().fill(index == page ? Theme.text(scheme) : Theme.border(scheme))
                        .frame(width: 6, height: 6)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Tour page \(page + 1) of \(titles.count)")
            Button(page == titles.count - 1 ? "Start reading" : "Continue") {
                if page == titles.count - 1 { finish(skipped: false) }
                else { move(to: page + 1) }
            }
            .buttonStyle(CapsuleButtonStyle())
        }
        .padding(.horizontal, 24).padding(.bottom, 24)
        .foregroundStyle(Theme.text(scheme)).background(Theme.canvas(scheme))
        .task(id: page) {
            await Analytics.shared.track("tutorial_step", ["index": .number(Double(page)), "entrypoint": .string(entryPoint)])
        }
        .interactiveDismissDisabled()
    }

    @ViewBuilder private func example(_ index: Int) -> some View {
        if index == 0, let ref = VerseRef("PSA.23.1"),
           let text = BibleStore.shared.text("kjv", ref) {
            VStack(spacing: 14) {
                Image(systemName: "arrow.up").font(.system(size: 16))
                Text(text).font(.serif(23, relativeTo: .title2))
                Text("Psalm 23:1 · KJV").font(.ui(11)).foregroundStyle(Theme.muted(scheme))
                Image(systemName: "arrow.down").font(.system(size: 16))
            }
            .frame(maxWidth: .infinity).padding(24)
            .background(Theme.supporting(scheme), in: RoundedRectangle(cornerRadius: 18))
        } else {
            HStack(spacing: 24) {
                ForEach(index == 1 ? ["heart", "bookmark", "message"] : index == 2 ? ["insights", "book"] : ["discover", "home"], id: \.self) { icon in
                    // The supplied glyphs are the same controls she will find in the app.
                    Image.glyph(icon).frame(width: 26, height: 26)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(Theme.supporting(scheme), in: RoundedRectangle(cornerRadius: 18))
            .accessibilityHidden(true)
        }
    }

    private func move(to next: Int) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { page = next }
    }

    private func finish(skipped: Bool) {
        guard !finished else { return }
        finished = true
        Task { await Analytics.shared.track("tutorial_finished", ["skipped": .bool(skipped), "entrypoint": .string(entryPoint)]) }
        onFinish(skipped)
    }
}
