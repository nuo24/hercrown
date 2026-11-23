import XCTest
import SwiftUI
@testable import HerCrown

final class OnboardingCardTests: XCTestCase {
    @MainActor func testReminderFitsLockScreenHeightAtPhoneAndTabletWidths() throws {
        for width in [298.0, 358.0, 500.0] {
            let renderer = ImageRenderer(content: OnboardingActivityCard(completedSteps: 3, totalSteps: 15).frame(width: width))
            let image = try XCTUnwrap(renderer.uiImage)
            XCTAssertLessThanOrEqual(image.size.height, 160, "Live Activity may be truncated at width \(width)")
            XCTAssertGreaterThan(image.size.height, 100)
            XCTAssertEqual(image.size.width, width, accuracy: 0.5)
        }
    }
}
