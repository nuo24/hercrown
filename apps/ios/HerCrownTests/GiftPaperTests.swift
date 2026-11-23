import XCTest
import SwiftUI
import UIKit
@testable import HerCrown

final class GiftPaperTests: XCTestCase {
    @MainActor func testOpenedSheetPreservesAllThreeContentPanels() throws {
        let sheet = GiftUnfoldingSheet(source: CGRect(x: 100, y: 100, width: 100, height: 67),
            target: CGSize(width: 300, height: 600), flight: 1, unfolding: 1, settled: 1) {
                VStack(spacing: 0) {
                    Color(red: 1, green: 0, blue: 0)
                    Color(red: 0, green: 1, blue: 0)
                    Color(red: 0, green: 0, blue: 1)
                }
            }
        let renderer = ImageRenderer(content: sheet)
        let image = try XCTUnwrap(renderer.uiImage?.cgImage)
        XCTAssertEqual(image.width, 300)
        XCTAssertEqual(image.height, 600)
        let colors = try pixels(image, ys: [100, 300, 500])
        XCTAssertGreaterThan(colors[0][0], 240)
        XCTAssertLessThan(colors[0][1], 15)
        XCTAssertGreaterThan(colors[1][1], 240)
        XCTAssertLessThan(colors[1][2], 15)
        XCTAssertGreaterThan(colors[2][2], 240)
        XCTAssertLessThan(colors[2][0], 15)
    }
    @MainActor func testFoldedSheetDoesNotAlreadyFillTheOfferPage() throws {
        let renderer = ImageRenderer(content: GiftUnfoldingSheet(
            source: CGRect(x: 0, y: 200, width: 300, height: 200), target: CGSize(width: 300, height: 600),
            flight: 1, unfolding: 0, settled: 0) { Color.clear })
        let image = try XCTUnwrap(renderer.uiImage?.cgImage)
        let colors = try pixels(image, ys: [40, 300, 560])
        XCTAssertEqual(colors[0][3], 0)
        XCTAssertGreaterThan(colors[1][3], 240)
        XCTAssertEqual(colors[2][3], 0)
    }
    @MainActor func testOfferSnapshotContainsPrintedContentBeforeAnimationStarts() throws {
        let view = MysteryGiftView(terms: .init(original: "$39.99", firstYear: "$29.99", renewal: "$39.99", saving: "$10.00"),
            isPreview: true, onPurchase: { nil }, onRestore: { nil }, onClose: {})
        let image = try XCTUnwrap(view.renderOfferSnapshot(size: CGSize(width: 390, height: 740))?.cgImage)
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        try bytes.withUnsafeMutableBytes { buffer in
            let context = try XCTUnwrap(CGContext(data: buffer.baseAddress, width: image.width, height: image.height,
                bitsPerComponent: 8, bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        }
        // A blank GeometryReader/ScrollView capture contains only pale paper. Each panel must carry ink.
        for third in 0..<3 {
            let start = third * image.height / 3
            let end = (third + 1) * image.height / 3
            var printed = 0
            for y in start..<end {
                for x in 0..<image.width {
                    let i = (y * image.width + x) * 4
                    if bytes[i] < 130 && bytes[i + 1] < 130 && bytes[i + 2] < 130 && bytes[i + 3] > 240 { printed += 1 }
                }
            }
            XCTAssertGreaterThan(printed, 200, "Offer panel \(third) must not be blank")
        }
    }
    private func pixels(_ image: CGImage, ys: [Int]) throws -> [[UInt8]] {
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        try bytes.withUnsafeMutableBytes { buffer in
            let context = try XCTUnwrap(CGContext(data: buffer.baseAddress, width: image.width, height: image.height,
                bitsPerComponent: 8, bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        }
        return ys.map { y in
            let offset = (y * image.width + image.width / 2) * 4
            return Array(bytes[offset..<(offset + 4)])
        }
    }
}
