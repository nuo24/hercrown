import Foundation

/// Licensed Scripture is fetched through the Worker, retained only in a small in-memory reader window.
enum OnlineBible {
    struct Response: Decodable {
        struct Item: Decodable { let verse: Int; let end: Int?; let text: String }
        let verses: [Item]
        let title: String?
        let copyright: String?
    }
    struct Passage {
        let text: String
        let reference: VerseRef
        var translation: String = "kjv"
        var label: String { BibleStore.shared.label(reference, translation: translation) }
    }
    static func passage(_ translation: String, ref: VerseRef) async throws -> Passage {
        let c = try await chapter(translation, book: ref.book, number: ref.chapter)
        return try passage(in: c, ref: ref)
    }
    static func passage(in chapter: Chapter, ref: VerseRef) throws -> Passage {
        let selected = chapter.verses.filter { $0.number <= (ref.end ?? ref.verse) && ($0.end ?? $0.number) >= ref.verse }
        guard let first = selected.first, let last = selected.last else { throw APIError(status: 404, code: "not_in_translation", message: "This verse isn’t included in this translation.") }
        let end = last.end ?? last.number
        return Passage(text: selected.map(\.text).joined(separator: " "), reference: VerseRef(book: ref.book, chapter: ref.chapter, verse: first.number, end: end > first.number ? end : nil), translation: chapter.translation)
    }
    private static let requests = ChapterRequests()
    static func chapter(_ translation: String, book: String, number: Int) async throws -> Chapter {
        if let cached = BibleStore.shared.chapter(translation, book: book, chapter: number) { return cached }
        return try await requests.load(translation, book: book, number: number)
    }
    private actor ChapterRequests {
        private var pending: [String: Task<Chapter, Error>] = [:]
        func load(_ translation: String, book: String, number: Int) async throws -> Chapter {
            let key = "\(translation).\(book).\(number)"
            if let task = pending[key] { return try await task.value }
            let task = Task { try await OnlineBible.fetchChapter(translation, book: book, number: number) }
            pending[key] = task
            defer { pending[key] = nil }
            return try await task.value
        }
    }
    private static func fetchChapter(_ translation: String, book: String, number: Int) async throws -> Chapter {
        if let cached = BibleStore.shared.chapter(translation, book: book, chapter: number) { return cached }
        let response: Response = try await APIClient.shared.get("/scripture/\(translation)/\(book)/\(number)")
        guard let bibleBook = BibleStore.shared.book(book), !response.verses.isEmpty else { throw APIError.offline }
        let chapter = Chapter(translation: translation, book: bibleBook, number: number, title: response.title,
                              verses: response.verses.map { Verse(number: $0.verse, text: $0.text, wordsOfJesus: [], end: $0.end) }, copyright: response.copyright)
        BibleStore.shared.cacheRemote(chapter)
        return chapter
    }
}
