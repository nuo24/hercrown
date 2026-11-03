import Foundation

/// A canonical reference: USFM book id, chapter, verse range ("JHN.3.16", "PSA.23.1-3").
struct VerseRef: Hashable, Codable, CustomStringConvertible {
    let book: String
    let chapter: Int
    let verse: Int
    var end: Int? = nil

    var description: String { end.map { "\(book).\(chapter).\(verse)-\($0)" } ?? "\(book).\(chapter).\(verse)" }

    init(book: String, chapter: Int, verse: Int, end: Int? = nil) {
        self.book = book; self.chapter = chapter; self.verse = verse; self.end = end
    }

    init?(_ string: String) {
        let parts = string.split(separator: ".")
        guard parts.count == 3, let chapter = Int(parts[1]) else { return nil }
        let verses = parts[2].split(separator: "-")
        guard let start = Int(verses[0]) else { return nil }
        self.init(book: String(parts[0]), chapter: chapter, verse: start, end: verses.count > 1 ? Int(verses[1]) : nil)
    }
}

struct Verse: Identifiable, Hashable {
    let number: Int
    let text: String
    /// Words of Jesus as UTF-16 ranges (NSRange), for red letters.
    let wordsOfJesus: [NSRange]
    var id: Int { number }
}

struct Chapter {
    let translation: String
    let book: BibleBook
    let number: Int
    let title: String?        // psalm superscription, kept apart from verse 1
    let verses: [Verse]
    var label: String { "\(book.displayName) \(number)" }
}

struct BibleBook: Identifiable, Hashable {
    let id: String
    let name: String
    let testament: String
    let chapterCount: Int
    var displayName: String { name == "Psalms" ? "Psalm" : name }
}

/// The three offline Bibles (KJV, BSB, WEB), bundled from the verified seeds. Each loads once, on first use.
final class BibleStore: @unchecked Sendable {
    static let shared = BibleStore()
    static let offline = ["kjv": "KJV", "bsb": "BSB", "web": "WEB"]

    private struct File: Decodable {
        struct Translation: Decodable { let id: String; let name: String }
        struct Book: Decodable { let id: String; let name: String; let testament: String; let chapters: [ChapterData] }
        struct ChapterData: Decodable { let title: String?; let verses: [VerseData] }
        struct VerseData: Decodable { let n: Int; let t: String; let wj: [[Int]]? }
        let translation: Translation
        let books: [Book]
    }

    private var files: [String: File] = [:]
    private let lock = NSLock()

    private func file(_ translation: String) -> File? {
        lock.lock(); defer { lock.unlock() }
        if let file = files[translation] { return file }
        guard let url = Bundle.main.url(forResource: translation, withExtension: "json"),
              let data = try? Data(contentsOf: url, options: .mappedIfSafe),
              let file = try? JSONDecoder().decode(File.self, from: data) else { return nil }
        files[translation] = file
        return file
    }

    /// Loads a translation ahead of time (off the main thread at launch).
    func preload(_ translation: String) { _ = file(translation) }

    var books: [BibleBook] {
        guard let file = file("kjv") else { return [] }
        return file.books.map { BibleBook(id: $0.id, name: $0.name, testament: $0.testament, chapterCount: $0.chapters.count) }
    }

    func book(_ id: String) -> BibleBook? { books.first { $0.id == id } }

    func chapter(_ translation: String, book: String, chapter number: Int) -> Chapter? {
        let translation = Self.offline[translation] == nil ? "kjv" : translation
        guard let file = file(translation), let b = file.books.first(where: { $0.id == book }),
              number >= 1, number <= b.chapters.count else { return nil }
        let data = b.chapters[number - 1]
        return Chapter(
            translation: translation,
            book: BibleBook(id: b.id, name: b.name, testament: b.testament, chapterCount: b.chapters.count),
            number: number,
            title: data.title,
            verses: data.verses.map { v in
                Verse(number: v.n, text: v.t, wordsOfJesus: (v.wj ?? []).compactMap { $0.count == 2 ? NSRange(location: $0[0], length: $0[1]) : nil })
            }
        )
    }

    func text(_ translation: String, _ ref: VerseRef) -> String? {
        guard let chapter = chapter(translation, book: ref.book, chapter: ref.chapter) else { return nil }
        let verses = chapter.verses.filter { $0.number >= ref.verse && $0.number <= (ref.end ?? ref.verse) }
        return verses.isEmpty ? nil : verses.map(\.text).joined(separator: " ")
    }

    func label(_ ref: VerseRef) -> String {
        let name = book(ref.book)?.displayName ?? ref.book
        return "\(name) \(ref.chapter):\(ref.verse)\(ref.end.map { "–\($0)" } ?? "")"
    }
}
