import XCTest
import UIKit
@testable import HerCrown

final class WholeWordHeadingTests: XCTestCase {
    func testUnderstandingFitsNarrowColumnsAtNormalAndAccessibilitySizes() {
        for width: CGFloat in [110, 138, 165, 190, 240] {
            for size: CGFloat in [22, 34, 68, 102] {
                let font = WholeWordHeadingMetrics.font(text: "A peace beyond understanding", width: width, pointSize: size, tracking: -0.6)
                let word = NSAttributedString(string: "understanding", attributes: [.font: font, .kern: -0.6])
                XCTAssertLessThanOrEqual(word.size().width, width - 0.9)
                XCTAssertLessThanOrEqual(font.pointSize, size)
            }
        }
    }
    func testShortTitlesKeepTheirDesignedSize() {
        let font = WholeWordHeadingMetrics.font(text: "Rest for a restless heart.", width: 240, pointSize: 34, tracking: -0.6)
        XCTAssertEqual(font.pointSize, 34)
    }
    func testEveryRenderedLineEndsAtAWordBoundary() {
        let text = "A peace beyond understanding"
        let width: CGFloat = 138
        let font = WholeWordHeadingMetrics.font(text: text, width: width, pointSize: 34, tracking: -0.6)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.hyphenationFactor = 0
        let storage = NSTextStorage(string: text, attributes: [.font: font, .kern: -0.6, .paragraphStyle: paragraph])
        let layout = NSLayoutManager()
        let container = NSTextContainer(size: CGSize(width: width, height: 1000))
        container.lineFragmentPadding = 0
        layout.addTextContainer(container); storage.addLayoutManager(layout)
        layout.ensureLayout(for: container)
        let string = text as NSString
        layout.enumerateLineFragments(forGlyphRange: layout.glyphRange(for: container)) { _, _, _, glyphs, _ in
            let range = layout.characterRange(forGlyphRange: glyphs, actualGlyphRange: nil)
            let end = NSMaxRange(range)
            if end < string.length {
                let before = string.substring(with: NSRange(location: end - 1, length: 1))
                let after = string.substring(with: NSRange(location: end, length: 1))
                XCTAssertTrue(before.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || after.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
