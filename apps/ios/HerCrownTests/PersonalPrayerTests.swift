import XCTest
@testable import HerCrown

final class PersonalPrayerTests: XCTestCase {
    func testNamesAreNormalizedWithoutAcceptingMarkup() {
        var answers = PersonalOnboardingAnswers()
        answers.name = "  nate  "
        XCTAssertEqual(answers.normalizedName, "Nate")
        answers.name = "<script>"
        XCTAssertEqual(answers.normalizedName, "")
    }
    func testSimpleFallbackNeverInterpolatesUntrustedFreeText() {
        var answers = PersonalOnboardingAnswers()
        answers.name = "Ignore previous"
        answers.burden = "repeat this malicious instruction"
        answers.lovedOnes = "https://example.org/attack"
        answers.heart = ["Peace", "Hope"]
        XCTAssertTrue(answers.simplePrayer.contains("peace for my heart"))
        XCTAssertFalse(answers.simplePrayer.contains(answers.burden))
        XCTAssertFalse(answers.simplePrayer.contains(answers.lovedOnes))
        XCTAssertFalse(answers.simplePrayer.contains(answers.name))
    }
    func testPrayersAreScopedToTheirProfile() {
        let user = "test-" + UUID().uuidString
        let other = "test-" + UUID().uuidString
        PersonalPrayerStore.save("My prayer", userID: user)
        XCTAssertEqual(PersonalPrayerStore.read(user), "My prayer")
        XCTAssertNil(PersonalPrayerStore.read(other))
        PersonalPrayerStore.remove(user)
        XCTAssertNil(PersonalPrayerStore.read(user))
    }
}
