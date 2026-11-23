import XCTest
import UIKit
@testable import HerCrown

final class BibleBookArtworkTests: XCTestCase {
    func testAll66CanonicalBooksHaveLoadableOriginalArtwork() {
        XCTAssertEqual(BibleBookArtwork.names.count, 66)
        for book in BibleStore.shared.books {
            guard let name = BibleBookArtwork.names[book.id] else { XCTFail("Missing art for \(book.id)"); continue }
            XCTAssertNotNil(UIImage(named: name), "Missing image for \(book.id)")
        }
    }
    @MainActor func testReaderUsesEachBookArtworkAtItsOpeningOnly() throws {
        let app = AppModel()
        app.offline = true
        app.preferences.translation = "kjv"
        let reader = ReaderModel(app: app)
        for book in BibleStore.shared.books {
            let first = try XCTUnwrap(BibleStore.shared.chapter("kjv", book: book.id, chapter: 1))
            let verse = try XCTUnwrap(first.verses.first)
            XCTAssertEqual(reader.artwork(for: verse, in: first), BibleBookArtwork.names[book.id], book.id)
            if let secondVerse = first.verses.first(where: { $0.number == 2 }) {
                XCTAssertNil(reader.artwork(for: secondVerse, in: first), book.id)
            }
            if book.chapterCount > 1 {
                let second = try XCTUnwrap(BibleStore.shared.chapter("kjv", book: book.id, chapter: 2))
                XCTAssertNil(reader.artwork(for: try XCTUnwrap(second.verses.first), in: second), book.id)
            }
        }
        let psalm = try XCTUnwrap(BibleStore.shared.chapter("kjv", book: "PSA", chapter: 23))
        XCTAssertEqual(reader.artwork(for: try XCTUnwrap(psalm.verses.first), in: psalm), "rest-stones")
        XCTAssertEqual(BibleBookArtwork.opening(bookID: "EZR", chapter: 1, verse: 1), "bible-book-ezr")
    }

}
