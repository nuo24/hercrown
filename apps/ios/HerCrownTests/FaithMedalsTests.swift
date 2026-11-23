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
        XCTAssertTrue(FaithMedal.all.allSatisfy { $0.days >= 14 && $0.targetCount > 0 })
        XCTAssertEqual(FaithMedal.items(.fruit).last?.days, 365)
        XCTAssertTrue(FaithMedal.all.allSatisfy { !$0.earned(.empty) })
    }

    func testGeneralReadingDoesNotGrantThemedMedals() {
        var progress = MedalProgress.empty
        progress.daysRead.total = 365
        progress.bible.chaptersRead = 1189
        XCTAssertFalse(FaithMedal.items(.fruit)[2].earned(progress))
        for medal in FaithMedal.all where medal.journey != nil {
            XCTAssertFalse(medal.earned(progress), medal.id)
            XCTAssertEqual(medal.counts(progress).units, 0)
        }
    }
    func testEachJourneyRequiresItsOwnExactChaptersAndDays() {
        for medal in FaithMedal.all where medal.journey != nil {
            var progress = MedalProgress.empty
            if medal.index > 0 { continue } // Legacy totals must not unlock later stages.
            progress.daysRead.total = medal.days
            progress.bible.completedChapterRefs = Array(medal.requiredChapterRefs.dropLast())
            XCTAssertFalse(medal.earned(progress), medal.id)
            progress.bible.completedChapterRefs = medal.requiredChapterRefs + medal.requiredChapterRefs
            XCTAssertTrue(medal.earned(progress), medal.id)
            XCTAssertEqual(medal.counts(progress).units, medal.chapters)
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
    func testArmorRequiresWholeDistinctCanonicalBooksAndReadingDays() {
        let belt = FaithMedal.items(.armor)[0]
        var progress = MedalProgress.empty
        progress.daysRead.total = 365
        progress.bible.chaptersRead = 1189
        XCTAssertFalse(belt.earned(progress))
        progress.bible.books = [.init(id: "RUT", chapters: 4, chaptersRead: 3),
            .init(id: "unknown", chapters: 1, chaptersRead: 1), .init(id: "GEN", chapters: 0, chaptersRead: 50)]
        XCTAssertEqual(belt.counts(progress).units, 0)
        progress.bible.books = [.init(id: "RUT", chapters: 4, chaptersRead: 4)]
        XCTAssertTrue(belt.earned(progress))
        progress.daysRead.total = belt.days - 1
        XCTAssertFalse(belt.earned(progress))
        let breastplate = FaithMedal.items(.armor)[1]
        progress.daysRead.total = 365
        progress.bible.books += progress.bible.books + progress.bible.books
        XCTAssertEqual(breastplate.counts(progress).units, 0)
        XCTAssertFalse(breastplate.earned(progress))
        progress.bible.books += [.init(id: "EST", chapters: 10, chaptersRead: 10), .init(id: "JUD", chapters: 1, chaptersRead: 1)]
        XCTAssertFalse(breastplate.earned(progress))
    }
    func testArmorKeepsArtAndVersesWithoutMandatoryChapterJourneys() throws {
        XCTAssertEqual(FaithMedal.items(.armor).compactMap(\.completedBooks), [1,3,5,10,20,40])
        for medal in FaithMedal.items(.armor) {
            XCTAssertNil(medal.journey)
            XCTAssertTrue(medal.requiredChapterRefs.isEmpty)
            XCTAssertFalse(medal.requirement.contains("journey"))
            XCTAssertTrue(medal.progressLabel(.empty).contains("books"))
            XCTAssertTrue(medal.reference.hasPrefix("Ephesians 6:"))
            XCTAssertFalse(medal.artwork.isEmpty)
            let number = try XCTUnwrap(Int(medal.reference.split(separator: ":").last!))
            let ref = try XCTUnwrap(VerseRef("EPH.6.\(number)"))
            XCTAssertFalse(try XCTUnwrap(BibleStore.shared.text("kjv", ref)).isEmpty)
        }
    }
    @MainActor func testRuleChangeRetainsUnchangedAwardDatesOnly() {
        let dates = ["fruit-0": Date(timeIntervalSince1970: 100), "armor-1": Date(), "promises-0": Date(), "women-0": Date()]
        for version in [nil, 2, 3] as [Int?] {
            XCTAssertTrue(FaithMedalsModel.retainedDates(dates, rulesVersion: version).isEmpty)
        }
        XCTAssertEqual(FaithMedalsModel.retainedDates(dates, rulesVersion: 4), dates)
    }
    func testSequentialStageCountsDoNotUseLifetimeTotals() {
        var progress = MedalProgress(daysRead: .init(total: 1000), bible: .init(chaptersRead: 1189, books: []))
        progress.medalStages = [.init(id: "fruit-0", days: 14, units: 14, completedChapterRefs: [], earned: true),
                                .init(id: "fruit-1", days: 1, units: 1, completedChapterRefs: ["PSA.1"], earned: false)]
        let fruits = FaithMedal.items(.fruit)
        XCTAssertTrue(fruits[0].earned(progress))
        XCTAssertTrue(fruits[1].isAvailable(progress))
        XCTAssertEqual(fruits[1].counts(progress).days, 1)
        XCTAssertEqual(fruits[1].counts(progress).units, 1)
        XCTAssertFalse(fruits[2].isAvailable(progress))
        XCTAssertEqual(fruits[2].fraction(progress), 0)
        XCTAssertEqual(fruits.filter { !$0.earned(progress) && $0.isAvailable(progress) }.count, 1)
        XCTAssertEqual(fruits[1].completedRefs(progress), ["PSA.1"])
        XCTAssertTrue(fruits[2].completedRefs(progress).isEmpty)
    }
}
