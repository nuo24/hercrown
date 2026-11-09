import Foundation

/// Licensed Scripture is fetched through the Worker, retained only in a small in-memory reader window.
enum OnlineBible {
    struct Response: Decodable {
        struct Item: Decodable { let verse: Int; let end: Int?; let text: String }
        let verses: [Item]
        let title: String?
        let copyright: String?
    }
    static func chapter(_ translation: String, book: String, number: Int) async throws -> Chapter {
        if let cached = BibleStore.shared.chapter(translation, book: book, chapter: number) { return cached }
        let response: Response = try await APIClient.shared.get("/scripture/\(translation)/\(book)/\(number)")
        guard let bibleBook = BibleStore.shared.book(book), !response.verses.isEmpty else { throw APIError.offline }
        let chapter = Chapter(translation: translation, book: bibleBook, number: number, title: response.title,
                              verses: response.verses.map { Verse(number: $0.verse, text: $0.text, wordsOfJesus: [], end: $0.end) }, copyright: response.copyright)
        BibleStore.shared.cacheRemote(chapter)
        return chapter
    }
}
