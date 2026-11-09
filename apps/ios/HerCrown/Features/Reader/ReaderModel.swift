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
    var loading = false
    var failure: String?
    private var loadTask: Task<Void, Never>?
    private var pending = VerseRef(book: "GEN", chapter: 1, verse: 1)
    private let app: AppModel

    init(app: AppModel) {
        self.app = app
        translation = BibleStore.names[app.preferences.translation] == nil ? "kjv" : app.preferences.translation
        #if DEBUG
        if let preview = UserDefaults.standard.string(forKey: "hcPreviewTranslation"), BibleStore.names[preview] != nil { translation = preview }
        #endif
        let saved = UserDefaults.standard.string(forKey: "hc.position").flatMap(VerseRef.init) ?? VerseRef(book: "GEN", chapter: 1, verse: 1)
        open(saved.book, saved.chapter, verse: saved.verse)
    }

    var verses: [Verse] { chapter?.verses ?? [] }
    var currentRef: VerseRef? { chapter.map { VerseRef(book: $0.book.id, chapter: $0.number, verse: current ?? 1, end: $0.verses.first { $0.number == current }?.end) } }

    func open(_ book: String, _ number: Int, verse: Int = 1) {
        pending = VerseRef(book: book, chapter: number, verse: verse)
        loadTask?.cancel()
        if let next = BibleStore.shared.chapter(translation, book: book, chapter: number) {
            apply(next, verse: verse); return
        }
        guard BibleStore.online[translation] != nil else { return }
        loading = true; failure = nil
        let requested = translation
        loadTask = Task {
            do {
                let next = try await OnlineBible.chapter(requested, book: book, number: number)
                guard !Task.isCancelled, translation == requested else { return }
                apply(next, verse: verse)
            } catch {
                guard !Task.isCancelled else { return }
                loading = false; failure = "This translation needs a connection. \(error.localizedDescription)"
            }
        }
    }
    func retry() { open(pending.book, pending.chapter, verse: pending.verse) }
    private func apply(_ next: Chapter, verse: Int) {
        chapter = next; loading = false; failure = nil
        current = next.verses.first { $0.number <= verse && ($0.end ?? $0.number) >= verse }?.number ?? next.verses.first?.number
        savePosition()
    }
    func prepareNeighbours() async {
        guard BibleStore.online[translation] != nil, let chapter else { return }
        for direction in [-1, 1] {
            guard !Task.isCancelled, let ref = ReaderChapterWindow.neighbourReference(of: chapter, direction: direction) else { continue }
            _ = try? await OnlineBible.chapter(chapter.translation, book: ref.book, number: ref.chapter)
        }
    }

    func setTranslation(_ id: String) {
        guard id != translation else { return }
        let destination = currentRef ?? pending
        translation = id
        open(destination.book, destination.chapter, verse: destination.verse)
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
    func artwork(for verse: Verse, in pageChapter: Chapter? = nil) -> String? {
        guard let chapter = pageChapter ?? chapter else { return nil }
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

/// A stable scroll feed. Neighbours are inserted before the reader reaches a boundary;
/// existing verse IDs and views stay in place instead of replacing the ScrollView.
struct ReaderChapterWindow {
    private(set) var chapters: [Chapter]

    init(chapter: Chapter) {
        chapters = [Self.neighbour(of: chapter, direction: -1), chapter,
                    Self.neighbour(of: chapter, direction: 1)].compactMap { $0 }
    }

    mutating func extend(around chapter: Chapter) {
        if chapters.first?.book.id == chapter.book.id, chapters.first?.number == chapter.number,
           let previous = Self.neighbour(of: chapter, direction: -1) { chapters.insert(previous, at: 0) }
        if chapters.last?.book.id == chapter.book.id, chapters.last?.number == chapter.number,
           let next = Self.neighbour(of: chapter, direction: 1) { chapters.append(next) }
    }

    func contains(_ ref: VerseRef) -> Bool {
        chapters.contains { $0.book.id == ref.book && $0.number == ref.chapter }
    }

    static func neighbourReference(of chapter: Chapter, direction: Int) -> VerseRef? {
        let number = chapter.number + direction
        if (1...chapter.book.chapterCount).contains(number) { return VerseRef(book: chapter.book.id, chapter: number, verse: 1) }
        let books = BibleStore.shared.books
        guard let index = books.firstIndex(where: { $0.id == chapter.book.id }), books.indices.contains(index + direction) else { return nil }
        let book = books[index + direction]
        return VerseRef(book: book.id, chapter: direction > 0 ? 1 : book.chapterCount, verse: 1)
    }

    static func neighbour(of chapter: Chapter, direction: Int) -> Chapter? {
        let store = BibleStore.shared
        let number = chapter.number + direction
        if (1...chapter.book.chapterCount).contains(number) {
            return store.chapter(chapter.translation, book: chapter.book.id, chapter: number)
        }
        let books = store.books
        guard let index = books.firstIndex(where: { $0.id == chapter.book.id }),
              books.indices.contains(index + direction) else { return nil }
        let book = books[index + direction]
        return store.chapter(chapter.translation, book: book.id, chapter: direction > 0 ? 1 : book.chapterCount)
    }
}
