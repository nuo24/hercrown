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

    func testGeneralReadingDoesNotGrantThemedMedals() {
        var progress = MedalProgress.empty
        progress.daysRead.total = 365
        progress.bible.chaptersRead = 1189
        XCTAssertTrue(FaithMedal.items(.fruit)[2].earned(progress))
        for medal in FaithMedal.all where medal.journey != nil {
            XCTAssertFalse(medal.earned(progress), medal.id)
            XCTAssertEqual(medal.counts(progress).chapters, 0)
        }
    }
    func testEachJourneyRequiresItsOwnExactChaptersAndDays() {
        for medal in FaithMedal.all where medal.journey != nil {
            var progress = MedalProgress.empty
            progress.daysRead.total = medal.days
            progress.bible.completedChapterRefs = Array(medal.requiredChapterRefs.dropLast())
            XCTAssertFalse(medal.earned(progress), medal.id)
            progress.bible.completedChapterRefs = medal.requiredChapterRefs + medal.requiredChapterRefs
            XCTAssertTrue(medal.earned(progress), medal.id)
            XCTAssertEqual(medal.counts(progress).chapters, medal.chapters)
            for other in FaithMedal.all where other.journey != nil && other.id != medal.id {
                progress.daysRead.total = 1000
                XCTAssertFalse(other.earned(progress), "\(medal.id) must not grant \(other.id)")
            }
            progress.daysRead.total = medal.days - 1
            XCTAssertFalse(medal.earned(progress), medal.id)
        }
    }
    func testJourneysHaveDistinctValidChapterLists() {
        let books = Dictionary(uniqueKeysWithValues: BibleStore.shared.books.map { ($0.id, $0.chapterCount) })
        var fingerprints = Set<String>()
        for medal in FaithMedal.all where medal.journey != nil {
            XCTAssertEqual(medal.requiredChapterRefs.count, medal.chapters)
            XCTAssertEqual(Set(medal.requiredChapterRefs).count, medal.chapters)
            XCTAssertTrue(fingerprints.insert(medal.requiredChapterRefs.sorted().joined(separator: ",")).inserted)
            for chapter in medal.requiredChapterRefs {
                guard let ref = VerseRef(chapter + ".1"), let total = books[ref.book] else {
                    XCTFail("Unknown chapter \(chapter)"); continue
                }
                XCTAssertTrue((1...total).contains(ref.chapter), chapter)
            }
        }
    }
    func testOldProgressPayloadDoesNotInventJourneyCompletion() throws {
        let data = Data(#"{"daysRead":{"total":365},"bible":{"chaptersRead":1189,"books":[]}}"#.utf8)
        let progress = try JSONDecoder().decode(MedalProgress.self, from: data)
        XCTAssertNil(progress.bible.completedChapterRefs)
        XCTAssertFalse(FaithMedal.items(.armor)[1].earned(progress))
    }
    @MainActor func testRuleChangeRetainsUnchangedAwardDatesOnly() {
        let dates = ["fruit-0": Date(timeIntervalSince1970: 100), "armor-1": Date(), "promises-0": Date(), "women-0": Date()]
        let migrated = FaithMedalsModel.retainedDates(dates, rulesVersion: nil)
        XCTAssertEqual(Set(migrated.keys), ["fruit-0", "women-0"])
        XCTAssertEqual(FaithMedalsModel.retainedDates(dates, rulesVersion: 2), dates)
    }
}
