import XCTest
import SwiftUI
@testable import HerCrown

@MainActor final class AppearanceTests: XCTestCase {
    func testSettingsChoiceOverridesPreviewAndDoesNotRevertOnPreferenceRefresh() {
        let palette = AppearancePalette(preview: "dark")
        palette.selection = "light"
        XCTAssertEqual(palette.resolvedSelection, "dark")
        palette.choose("pink")
        XCTAssertEqual(palette.resolvedSelection, "pink")
        XCTAssertTrue(palette.pink)
        palette.selection = "pink" // The saved preference arrives from the API.
        XCTAssertEqual(palette.resolvedSelection, "pink")
        palette.choose("light")
        XCTAssertFalse(palette.pink)
        palette.choose("system")
        XCTAssertEqual(palette.resolvedSelection, "system")
    }

    func testPinkUsesOwnersPlumAccentAndPreservesDark() {
        let old = AppearancePalette.shared.selection
        defer { AppearancePalette.shared.selection = old }
        AppearancePalette.shared.selection = "pink"
        XCTAssertTrue(Theme.pink(.light))
        XCTAssertFalse(Theme.pink(.dark))
        assertColor(Theme.text(.light), 0x31222B)
        assertColor(Theme.accent(.light), 0x82435F)
        assertColor(Theme.canvas(.light), 0xFBF1F4)
        assertColor(Theme.surface(.light), 0xFFF9FB)
        assertColor(Theme.border(.light), 0xE0C4CF)
        assertColor(Theme.text(.dark), 0xF5F5F5)
        assertColor(Theme.accent(.dark), 0xF5F5F5)
        AppearancePalette.shared.selection = "light"
        assertColor(Theme.canvas(.light), 0xFFFFFF)
        assertColor(Theme.text(.light), 0x111111)
        assertColor(Theme.accent(.light), 0x111111)
    }
    func testHomeVerseUsesWidthBeforeModestReductionAndPreservesAccessibility() {
        let short = "The LORD is my shepherd; I shall not want."
        XCTAssertEqual(HomeVerseTypography.pointSize(text: short, width: 330, preferred: 28, accessibility: false), 28)
        let long = String(repeating: "A longer passage needs room to remain readable. ", count: 10)
        let narrow = HomeVerseTypography.pointSize(text: long, width: 265, preferred: 28, accessibility: false)
        let wide = HomeVerseTypography.pointSize(text: long, width: 330, preferred: 28, accessibility: false)
        XCTAssertGreaterThanOrEqual(wide, narrow)
        XCTAssertGreaterThanOrEqual(wide, 22)
        XCTAssertLessThan(wide, 28)
        XCTAssertEqual(HomeVerseTypography.pointSize(text: long, width: 330, preferred: 48, accessibility: true), 48)
        XCTAssertEqual(HomeVerseTypography.pointSize(text: long, width: 0, preferred: 28, accessibility: false), 28)
    }
    private func assertColor(_ color: Color, _ hex: UInt32, file: StaticString = #filePath, line: UInt = #line) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(r, CGFloat((hex >> 16) & 255) / 255, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(g, CGFloat((hex >> 8) & 255) / 255, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(b, CGFloat(hex & 255) / 255, accuracy: 0.001, file: file, line: line)
    }
}
