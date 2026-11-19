import XCTest
@testable import HerCrown

final class GuestPaywallTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    func testFirstGuestOfferHasNo24HourWaitButSignedInAndPlusAreExcluded() {
        let history = GuestPaywallHistory()
        XCTAssertTrue(history.canRequest(isGuest: true, premium: false, now: now))
        XCTAssertFalse(history.canRequest(isGuest: false, premium: false, now: now))
        XCTAssertFalse(history.canRequest(isGuest: true, premium: true, now: now))
    }

    func testRolling24HourCooldownAndFutureClockAreRespected() {
        let history = GuestPaywallHistory(lastRequest: now)
        XCTAssertFalse(history.canRequest(isGuest: true, premium: false, now: now.addingTimeInterval(23 * 3600)))
        XCTAssertTrue(history.canRequest(isGuest: true, premium: false, now: now.addingTimeInterval(24 * 3600)))
        XCTAssertFalse(history.canRequest(isGuest: true, premium: false, now: now.addingTimeInterval(-3600)))
    }

    func testOfferWaitsUntilLeavingACompletedChapterAndDoesNotRepeatInsideNextChapter() {
        var progress = GuestChapterProgress()
        for v in [1, 2, 3, 31] {
            XCTAssertFalse(progress.record(chapter: "GEN.1", verse: v, verseCount: 31, lastVerse: 31))
        }
        XCTAssertTrue(progress.record(chapter: "GEN.2", verse: 1, verseCount: 25, lastVerse: 25))
        XCTAssertFalse(progress.record(chapter: "GEN.2", verse: 2, verseCount: 25, lastVerse: 25))
    }

    func testJumpToEndAndRepeatedVerseCannotTriggerButAWholeShortChapterCan() {
        var progress = GuestChapterProgress()
        for _ in 0..<4 { _ = progress.record(chapter: "GEN.1", verse: 31, verseCount: 31, lastVerse: 31) }
        XCTAssertFalse(progress.record(chapter: "PSA.117", verse: 1, verseCount: 2, lastVerse: 2))
        XCTAssertFalse(progress.record(chapter: "PSA.117", verse: 2, verseCount: 2, lastVerse: 2))
        XCTAssertTrue(progress.record(chapter: "PSA.118", verse: 1, verseCount: 29, lastVerse: 29))
    }

    @MainActor func testCooldownSurvivesRelaunch() {
        let suite = "guest-paywall-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        GuestPaywallPrompter(defaults: defaults).requested(now: now)
        let reopened = GuestPaywallPrompter(defaults: defaults)
        XCTAssertFalse(reopened.canRequest(isGuest: true, premium: false, now: now.addingTimeInterval(60)))
        XCTAssertTrue(reopened.canRequest(isGuest: true, premium: false, now: now.addingTimeInterval(86_400)))
    }
}
