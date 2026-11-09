import SwiftUI
import UIKit

/// Colours only verified, bundled UTF-16 red-letter ranges. Unmatched online text stays untouched.
struct ScriptureText: View {
    let text: String
    let reference: String
    let translation: String
    @Environment(AppModel.self) private var app
    @Environment(\.colorScheme) private var scheme

    var body: some View { Text(attributed) }

    private var attributed: AttributedString {
        let value = NSMutableAttributedString(string: text)
        guard app.preferences.wordsOfJesusInRed,
              BibleStore.offline[translation] != nil,
              let ref = VerseRef(reference),
              let chapter = BibleStore.shared.chapter(translation, book: ref.book, chapter: ref.chapter) else { return AttributedString(text) }
        let verses = chapter.verses.filter { $0.number >= ref.verse && $0.number <= (ref.end ?? ref.verse) }
        let passage = verses.map(\.text).joined(separator: " ")
        // Match the entire canonical passage, allowing only typographic quotation marks around it.
        guard text == passage || text == "“" + passage + "”" else { return AttributedString(text) }
        var offset = text == passage ? 0 : 1
        for verse in verses {
            for range in verse.wordsOfJesus where NSMaxRange(range) <= (verse.text as NSString).length {
                value.addAttribute(.foregroundColor, value: UIColor(scheme == .dark ? Theme.wordsOfJesusDark : Theme.wordsOfJesus), range: NSRange(location: offset + range.location, length: range.length))
            }
            offset += (verse.text as NSString).length + 1
        }
        return (try? AttributedString(value, including: \.uiKit)) ?? AttributedString(text)
    }
}

/// Explicit controls avoid the platform's automatic glass toolbar treatment.
struct SheetControls: View {
    let back: () -> Void
    let done: () -> Void
    var body: some View {
        HStack {
            Button(action: back) { Label("Back", systemImage: "arrow.left").font(.ui(12, weight: .medium)) }
            Spacer()
            Button("Done", action: done).font(.ui(12, weight: .medium))
        }
        .buttonStyle(.plain).foregroundStyle(.primary).frame(minHeight: 44)
    }
}

/// Quotation marks belong to the presentation; the source passage is never rewritten.
enum ScriptureQuotation {
    static func enclosing(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        if (text.hasPrefix("“") && text.hasSuffix("”")) || (text.hasPrefix("\"") && text.hasSuffix("\"")) { return text }
        return "“" + text + "”"
    }
}
