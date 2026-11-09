import XCTest
@testable import HerCrown

final class BibleStoreTests: XCTestCase {
    let store = BibleStore.shared

    func testReferencesRoundTrip() {
        XCTAssertEqual(VerseRef("JHN.3.16")?.description, "JHN.3.16")
        XCTAssertEqual(VerseRef("PSA.23.1-3")?.end, 3)
        XCTAssertNil(VerseRef("John 3:16"))
    }

    func testAllThreeBiblesAreBundledWithTheRightShape() throws {
        XCTAssertEqual(store.books.count, 66)
        XCTAssertEqual(store.books.reduce(0) { $0 + $1.chapterCount }, 1189)
        for t in ["kjv", "bsb", "web"] {
            let genesis = try XCTUnwrap(store.chapter(t, book: "GEN", chapter: 1), t)
            XCTAssertEqual(genesis.verses.count, 31, t)
        }
        XCTAssertEqual(store.text("kjv", VerseRef("PSA.23.1")!), "The LORD is my shepherd; I shall not want.")
    }

    func testTranslationsKeepTheirOwnVersification() throws {
        // BSB leaves out Matthew 17:21 (not in the earliest manuscripts); KJV has it.
        XCTAssertNil(store.text("bsb", VerseRef("MAT.17.21")!))
        XCTAssertNotNil(store.text("kjv", VerseRef("MAT.17.21")!))
        XCTAssertEqual(try XCTUnwrap(store.chapter("kjv", book: "PSA", chapter: 3)).title?.isEmpty, false) // psalm title kept apart
    }

    func testWordsOfJesusRangesFitTheirVerse() throws {
        let luke = try XCTUnwrap(store.chapter("kjv", book: "LUK", chapter: 23))
        let verse = try XCTUnwrap(luke.verses.first { $0.number == 34 })
        let range = try XCTUnwrap(verse.wordsOfJesus.first)
        XCTAssertTrue((verse.text as NSString).substring(with: range).hasPrefix("Father, forgive them"))
        for v in luke.verses { for r in v.wordsOfJesus { XCTAssertLessThanOrEqual(NSMaxRange(r), (v.text as NSString).length) } }
    }

    func testLicensedTranslationNeverSilentlyFallsBackAndPreservesBridges() throws {
        XCTAssertNil(store.chapter("nlt", book: "GEN", chapter: 49))
        let book = try XCTUnwrap(store.book("PSA"))
        store.cacheRemote(Chapter(translation: "msg", book: book, number: 23, title: nil,
            verses: [Verse(number: 1, text: "Provider fixture", wordsOfJesus: [], end: 3)], copyright: "Fixture credit"))
        XCTAssertEqual(store.text("msg", VerseRef("PSA.23.2")!), "Provider fixture")
        XCTAssertEqual(store.chapter("msg", book: "PSA", chapter: 23)?.verses.count, 1)
    }

    func testUnknownTranslationFallsBackToKJV() {
        XCTAssertEqual(store.chapter("niv", book: "JHN", chapter: 3)?.translation, "kjv")
    }
    func testReaderWindowPreservesPageIDsWhenCrossingBothDirections() throws {
        let chapter = try XCTUnwrap(store.chapter("kjv", book: "GEN", chapter: 2))
        var window = ReaderChapterWindow(chapter: chapter)
        let ids = { (window: ReaderChapterWindow) in window.chapters.flatMap { chapter in
            chapter.verses.map { "\(chapter.book.id).\(chapter.number).\($0.number)" }
        } }
        let original = ids(window)
        XCTAssertEqual(window.chapters.map(\.number), [1, 2, 3])
        window.extend(around: try XCTUnwrap(window.chapters.last))
        XCTAssertEqual(Array(ids(window).prefix(original.count)), original)
        XCTAssertEqual(Set(ids(window)).count, ids(window).count)
        XCTAssertEqual(window.chapters.last?.number, 4)
        let genesis1 = try XCTUnwrap(window.chapters.first)
        XCTAssertNil(ReaderChapterWindow.neighbour(of: genesis1, direction: -1))
        XCTAssertEqual(ReaderChapterWindow.neighbour(of: chapter, direction: -1)?.number, 1)
        var backwards = ReaderChapterWindow(chapter: try XCTUnwrap(store.chapter("kjv", book: "PSA", chapter: 3)))
        let previousIDs = ids(backwards)
        backwards.extend(around: try XCTUnwrap(backwards.chapters.first))
        XCTAssertEqual(backwards.chapters.first?.number, 1)
        XCTAssertEqual(Array(ids(backwards).suffix(previousIDs.count)), previousIDs)
    }

    func testReaderWindowCrossesBooksAndKeepsRealVerseNumbers() throws {
        let matthew = try XCTUnwrap(store.chapter("bsb", book: "MAT", chapter: 17))
        let window = ReaderChapterWindow(chapter: matthew)
        XCTAssertTrue(window.contains(VerseRef("MAT.17.22")!))
        XCTAssertFalse(matthew.verses.contains { $0.number == 21 })
        let malachi = try XCTUnwrap(store.chapter("kjv", book: "MAL", chapter: 4))
        let next = try XCTUnwrap(ReaderChapterWindow.neighbour(of: malachi, direction: 1))
        XCTAssertEqual(next.book.id, "MAT")
        XCTAssertEqual(next.number, 1)
        XCTAssertEqual(ReaderChapterWindow.neighbour(of: next, direction: -1)?.book.id, "MAL")
        let end = try XCTUnwrap(store.chapter("kjv", book: "REV", chapter: 22))
        XCTAssertNil(ReaderChapterWindow.neighbour(of: end, direction: 1))
    }

    func testOnlinePassageRetainsBridgeAndLabel() throws {
        let book = try XCTUnwrap(BibleStore.shared.book("PSA"))
        let chapter = Chapter(translation: "msg", book: book, number: 23, title: nil,
            verses: [Verse(number: 1, text: "Provider bridge fixture.", wordsOfJesus: [], end: 3), Verse(number: 4, text: "Next fixture.", wordsOfJesus: [])])
        let passage = try OnlineBible.passage(in: chapter, ref: VerseRef(book: "PSA", chapter: 23, verse: 2))
        XCTAssertEqual(passage.text, "Provider bridge fixture.")
        XCTAssertEqual(passage.label, "Psalm 23:1–3")
        XCTAssertEqual(passage.reference.description, "PSA.23.1-3")
    }

}
