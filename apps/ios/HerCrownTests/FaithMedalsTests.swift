import XCTest
@testable import HerCrown

final class FaithMedalsTests: XCTestCase {
    func testMedalsRequireBothDaysAndDistinctChapters() {
        let love = FaithMedal.items(.fruit)[0]
        var progress = MedalProgress.empty
        progress.daysRead.total = 100
        XCTAssertFalse(love.earned(progress))
        progress.bible.chaptersRead = 13
        XCTAssertFalse(love.earned(progress))
        progress.bible.chaptersRead = 14
        XCTAssertTrue(love.earned(progress))
        progress.daysRead.total = 13
        XCTAssertFalse(love.earned(progress))
    }
    func testBookMedalsCannotBeEarnedByOtherBooks() {
        let ruth = FaithMedal.items(.women)[0]
        var progress = MedalProgress(daysRead: .init(total: 365), bible: .init(chaptersRead: 1000, books: []))
        XCTAssertFalse(ruth.earned(progress))
        progress.bible.books = [.init(id: "RUT", chapters: 4, chaptersRead: 3)]
        XCTAssertFalse(ruth.earned(progress))
        progress.bible.books = [.init(id: "RUT", chapters: 4, chaptersRead: 4)]
        XCTAssertTrue(ruth.earned(progress))
    }
    func testCatalogHasUniqueIDsAndSustainedNonzeroRequirements() {
        XCTAssertEqual(FaithMedal.all.count, 24)
        XCTAssertEqual(Set(FaithMedal.all.map(\.id)).count, FaithMedal.all.count)
        XCTAssertTrue(FaithMedal.all.allSatisfy { $0.days >= 14 && $0.chapters >= 4 })
        XCTAssertEqual(FaithMedal.items(.fruit).last?.days, 365)
        XCTAssertTrue(FaithMedal.all.allSatisfy { !$0.earned(.empty) })
    }
}
