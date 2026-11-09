import XCTest
import SwiftUI
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
    func testTwoParagraphFormattingPreservesEveryWord() {
        let text = "Dear God, thank You for today. Give me peace and wisdom. Hold those I love close. Guide my steps gently. Amen."
        let formatted = PrayerParagraphs.two(text)
        XCTAssertEqual(formatted.components(separatedBy: "\n\n").count, 2)
        XCTAssertEqual(formatted.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }, text.split(separator: " ").map(String.init))
        XCTAssertEqual(PrayerParagraphs.two(formatted), formatted)
    }
    @MainActor func testBundledOnboardingRecordingActuallyAdvances() async throws {
        let playback = DemoPlayback()
        XCTAssertNil(playback.error)
        playback.setActive(true, autoplay: true)
        try await Task.sleep(for: .seconds(3))
        XCTAssertGreaterThan(playback.player.currentTime().seconds, 0.2)
        playback.pause()
        XCTAssertFalse(playback.playing)
    }
    @MainActor func testSnapshotProducesTheRequestedImageSizesFromBundledScripture() throws {
        let chapter = try XCTUnwrap(BibleStore.shared.chapter("kjv", book: "PSA", chapter: 23))
        let verse = try XCTUnwrap(chapter.verses.first)
        for (format, height) in [("Portrait", 1440), ("Square", 1080), ("Story", 1920)] {
            var design = SnapshotDesign(); design.format = format
            let image = try XCTUnwrap(SnapshotRenderer.render(text: verse.text, reference: "Psalm 23:1", translation: "King James Version", design: design, photo: nil, watermark: true)?.cgImage)
            XCTAssertEqual(image.width, 1080)
            XCTAssertEqual(image.height, height)
        }
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
