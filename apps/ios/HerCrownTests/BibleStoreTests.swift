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

    func testUnknownTranslationFallsBackToKJV() {
        XCTAssertEqual(store.chapter("niv", book: "JHN", chapter: 3)?.translation, "kjv")
    }
}
