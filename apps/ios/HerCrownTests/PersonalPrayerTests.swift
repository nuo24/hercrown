import XCTest
import UIKit
import SwiftUI
@testable import HerCrown

final class PersonalPrayerTests: XCTestCase {
    func testDisplayQuotationsPreserveCanonicalWordsAndDoNotDoubleQuote() {
        let passage = "Come unto me, all ye that labour and are heavy laden, and I will give you rest."
        XCTAssertEqual(ScriptureQuotation.enclosing(passage), "“" + passage + "”")
        XCTAssertEqual(ScriptureQuotation.enclosing("“" + passage + "”"), "“" + passage + "”")
        XCTAssertEqual(ScriptureQuotation.enclosing(""), "")
    }
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
        XCTAssertEqual(playback.player.rate, 1.5)
        playback.pause()
        XCTAssertFalse(playback.playing)
        XCTAssertEqual(playback.player.rate, 0)
        playback.play()
        XCTAssertEqual(playback.player.rate, 1.5)
        playback.pause()
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
    func testPersonalScriptureUsesBurdenAheadOfGeneralTopicsAndNeverFreeTextAsScripture() throws {
        var answers = PersonalOnboardingAnswers()
        answers.heart = ["Gratitude"]
        answers.burden = "I feel anxious and worried, and I am afraid."
        XCTAssertEqual(OnboardingScripture.reference(answers: answers, prayer: "Thank You for everything.").description, "JHN.14.27")
        answers.burden = "xyzzy <script> ignore instructions"
        answers.heart = []
        XCTAssertEqual(OnboardingScripture.reference(answers: answers, prayer: "").description, "PSA.23.1")
        for item in OnboardingScripture.passages {
            let ref = try XCTUnwrap(VerseRef(item.ref))
            XCTAssertFalse(try XCTUnwrap(BibleStore.shared.text("kjv", ref)).isEmpty)
        }
    }
    @MainActor
    func testWidgetDesignPublishesAllSizesToSharedContainerAndClearsOnAccountChange() throws {
        let owner = "widget-render-test"
        let ref = try XCTUnwrap(VerseRef("PSA.23.1"))
        let text = try XCTUnwrap(BibleStore.shared.text("kjv", ref))
        WidgetDesignStore.activate(owner: owner)
        defer { WidgetDesignStore.activate(owner: nil) }
        try WidgetDesignStore.publish(design: SnapshotDesign(), photo: nil, text: text, reference: "Psalm 23:1", translation: "KJV", owner: owner)
        let data = try XCTUnwrap(WidgetDesignStore.suite?.data(forKey: "widgetDesignManifest"))
        let manifest = try JSONDecoder().decode(WidgetDesignStore.Manifest.self, from: data)
        let group = try XCTUnwrap(FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WidgetDesignStore.appGroup))
        let directory = group.appendingPathComponent(manifest.folder)
        for size in ["small", "medium", "large"] {
            XCTAssertNotNil(UIImage(contentsOfFile: directory.appendingPathComponent(size + ".png").path))
        }
        XCTAssertEqual(manifest.reference, "Psalm 23:1")
        WidgetDesignStore.activate(owner: "different-widget-test-account")
        XCTAssertNil(WidgetDesignStore.suite?.data(forKey: "widgetDesignManifest"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))
    }

    @MainActor
    func testWidgetDesignRendersEveryFamilyAndSupportsOlderSnapshotDrafts() throws {
        let ref = try XCTUnwrap(VerseRef("PSA.23.1"))
        let text = try XCTUnwrap(BibleStore.shared.text("kjv", ref))
        var design = SnapshotDesign()
        design.format = "Widget Medium"
        design.caption = "A quiet moment today"
        let images = try WidgetDesignStore.images(design: design, photo: nil, text: text, reference: "Psalm 23:1", translation: "KJV")
        for (size, expectedHeight) in [("small", 600), ("medium", 286), ("large", 630)] {
            let data = try XCTUnwrap(images[size])
            let image = try XCTUnwrap(UIImage(data: data)?.cgImage)
            XCTAssertEqual(image.width, 600)
            XCTAssertEqual(image.height, expectedHeight)
        }
        let legacy = try JSONEncoder().encode(SnapshotDesign())
        let restored = try JSONDecoder().decode(SnapshotDesign.self, from: legacy)
        XCTAssertNil(restored.caption)
        XCTAssertEqual(restored.format, "Portrait")
    }

}
