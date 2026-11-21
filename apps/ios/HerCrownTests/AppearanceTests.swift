import XCTest
import SwiftUI
@testable import HerCrown

@MainActor final class AppearanceTests: XCTestCase {
    func testPinkUsesOwnersPlumAccentAndPreservesDark() {
        let old = AppearancePalette.shared.selection
        defer { AppearancePalette.shared.selection = old }
        AppearancePalette.shared.selection = "pink"
        XCTAssertTrue(Theme.pink(.light))
        XCTAssertFalse(Theme.pink(.dark))
        assertColor(Theme.text(.light), 0x31222B)
        assertColor(Theme.canvas(.light), 0xFBF1F4)
        assertColor(Theme.surface(.light), 0xFFF9FB)
        assertColor(Theme.border(.light), 0xE0C4CF)
        assertColor(Theme.text(.dark), 0xF5F5F5)
        AppearancePalette.shared.selection = "light"
        assertColor(Theme.canvas(.light), 0xFFFFFF)
        assertColor(Theme.text(.light), 0x111111)
    }
    private func assertColor(_ color: Color, _ hex: UInt32, file: StaticString = #filePath, line: UInt = #line) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(r, CGFloat((hex >> 16) & 255) / 255, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(g, CGFloat((hex >> 8) & 255) / 255, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(b, CGFloat(hex & 255) / 255, accuracy: 0.001, file: file, line: line)
    }
}
