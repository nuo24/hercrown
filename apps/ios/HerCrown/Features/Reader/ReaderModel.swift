import Foundation
import Observation

/// What the reader is showing, where she left off, and the reading activity it reports (streak, Bible progress).
@MainActor
@Observable
final class ReaderModel {
    var translation: String
    var chapter: Chapter?
    var current: Int? = 1               // verse number in view
    private var versesSeen = Set<String>()
    private var completed = Set<String>()
    private var dayRecorded: String?
    private let app: AppModel

    init(app: AppModel) {
        self.app = app
        translation = BibleStore.offline[app.preferences.translation] == nil ? "kjv" : app.preferences.translation
        let saved = UserDefaults.standard.string(forKey: "hc.position").flatMap(VerseRef.init) ?? VerseRef(book: "GEN", chapter: 1, verse: 1)
        open(saved.book, saved.chapter, verse: saved.verse)
    }

    var verses: [Verse] { chapter?.verses ?? [] }
    var currentRef: VerseRef? { chapter.map { VerseRef(book: $0.book.id, chapter: $0.number, verse: current ?? 1) } }

    func open(_ book: String, _ number: Int, verse: Int = 1) {
        guard let next = BibleStore.shared.chapter(translation, book: book, chapter: number) else { return }
        chapter = next
        current = next.verses.contains { $0.number == verse } ? verse : next.verses.first?.number
        savePosition()
    }

    func setTranslation(_ id: String) {
        guard id != translation, let chapter else { return }
        translation = id
        open(chapter.book.id, chapter.number, verse: current ?? 1)
        app.updatePreferences(["translation": id]) { $0.translation = id }
        Task { await Analytics.shared.track("translation_changed", ["translation": .string(id)]) }
    }

    var nextChapter: (String, Int)? {
        guard let chapter else { return nil }
        if chapter.number < chapter.book.chapterCount { return (chapter.book.id, chapter.number + 1) }
        let books = BibleStore.shared.books
        guard let i = books.firstIndex(where: { $0.id == chapter.book.id }), i + 1 < books.count else { return nil }
        return (books[i + 1].id, 1)
    }

    /// Called as she scrolls. Seeing a few verses marks today as a reading day; reaching the last verse finishes the chapter.
    func didView(_ verse: Int?) {
        guard let verse, let chapter else { return }
        savePosition()
        versesSeen.insert("\(chapter.book.id).\(chapter.number).\(verse)")
        let today = AppModel.localDay()
        if versesSeen.count >= 3, dayRecorded != today {
            dayRecorded = today
            let ref = "\(chapter.book.id).\(chapter.number).\(verse)"
            Task {
                _ = try? await app.api.send("POST", "/me/reading-events", json: ["events": [[
                    "id": "read-\(today)-\(AppConfig.installID.prefix(8))", "localDay": today, "timeZone": TimeZone.current.identifier, "ref": ref,
                ]]])
            }
        }
        let key = "\(chapter.book.id).\(chapter.number)"
        if verse == chapter.verses.last?.number, !completed.contains(key) {
            completed.insert(key)
            Task {
                _ = try? await app.api.send("POST", "/me/chapters/\(chapter.book.id)/\(chapter.number)/complete",
                                            json: ["localDay": today, "timeZone": TimeZone.current.identifier])
            }
        }
    }

    private var positionTask: Task<Void, Never>?
    private func savePosition() {
        guard let ref = currentRef else { return }
        UserDefaults.standard.set(ref.description, forKey: "hc.position")
        positionTask?.cancel()
        positionTask = Task { [api = app.api] in
            try? await Task.sleep(for: .seconds(3)) // only where she settles
            guard !Task.isCancelled else { return }
            _ = try? await api.send("PUT", "/me/position", json: ["ref": ref.description, "at": Date().timeIntervalSince1970 * 1000])
        }
    }

    /// Contextual artwork (the mockup's readerArtwork): featured verses, else the chapter's first verse.
    func artwork(for verse: Verse) -> String? {
        guard let chapter else { return nil }
        let featured = ["PSA.23.1": "rest-stones", "PSA.119.105": "lantern", "PRO.31.25": "anchor", "MAT.11.28": "dove"]
        if let art = featured["\(chapter.book.id).\(chapter.number).\(verse.number)"] { return art }
        guard verse.number == chapter.verses.first?.number else { return nil }
        switch chapter.book.id {
        case "GEN": return "seedling"
        case "PSA": return "olive"
        case "PRO": return "wisdom-pearl"
        case "JHN": return "faith-hands"
        default: return "open-book"
        }
    }
}
