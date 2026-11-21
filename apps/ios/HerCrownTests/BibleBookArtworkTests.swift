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
}
