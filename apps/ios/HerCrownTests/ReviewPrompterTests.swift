import XCTest
@testable import HerCrown

final class ReviewPrompterTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    func testReviewRequiresDifferentReadingDaysAndAnEstablishedHabit() {
        var history = ReviewHistory(firstUse: now.addingTimeInterval(-8 * 86_400))
        history.readingDays = ["2026-11-01", "2026-11-02"]
        XCTAssertFalse(history.canRequestReview(now: now, version: "1.1"))
        history.readingDays.insert("2026-11-03")
        XCTAssertTrue(history.canRequestReview(now: now, version: "1.1"))
        history.firstUse = now.addingTimeInterval(-86_400)
        XCTAssertFalse(history.canRequestReview(now: now, version: "1.1"))
    }

    func testSameVersionAndCooldownSuppressRepeatedRequests() {
        var history = ReviewHistory(firstUse: now.addingTimeInterval(-365 * 86_400),
            readingDays: ["one", "two", "three"], lastReview: now.addingTimeInterval(-121 * 86_400), reviewVersion: "1.0")
        XCTAssertFalse(history.canRequestReview(now: now, version: "1.0"))
        XCTAssertTrue(history.canRequestReview(now: now, version: "1.1"))
        history.lastReview = now.addingTimeInterval(-30 * 86_400)
        XCTAssertFalse(history.canRequestReview(now: now, version: "1.1"))
    }

    func testFeedbackDoesNotImmediatelyFollowReviewAndHasItsOwnCooldown() {
        var history = ReviewHistory(firstUse: now.addingTimeInterval(-20 * 86_400), readingDays: ["1", "2", "3", "4", "5"])
        XCTAssertTrue(history.canRequestFeedback(now: now))
        history.lastReview = now
        XCTAssertFalse(history.canRequestFeedback(now: now))
        history.lastReview = now.addingTimeInterval(-8 * 86_400)
        XCTAssertTrue(history.canRequestFeedback(now: now))
        history.lastFeedback = now
        XCTAssertFalse(history.canRequestFeedback(now: now))
    }

    @MainActor func testRepeatedReadingOnTheSameDayIsNotMultipleDaysAndSurvivesReopening() {
        let suite = "review-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let prompter = ReviewPrompter(defaults: defaults, now: now)
        prompter.recordReadingDay("2026-11-19")
        prompter.recordReadingDay("2026-11-19")
        XCTAssertEqual(prompter.history.readingDays.count, 1)
        XCTAssertEqual(ReviewPrompter(defaults: defaults, now: now).history.readingDays.count, 1)
    }
}
