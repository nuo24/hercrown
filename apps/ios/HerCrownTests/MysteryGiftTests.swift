import XCTest
@testable import HerCrown

final class MysteryGiftTests: XCTestCase {
    func testRoundedQuarterDiscountIsAccepted() {
        XCTAssertTrue(GiftOfferRules.isQuarterOff(firstYear: Decimal(string: "29.99")!, regular: Decimal(string: "39.99")!, renewal: Decimal(string: "39.99")!))
        XCTAssertTrue(GiftOfferRules.isQuarterOff(firstYear: 30, regular: 40, renewal: 40))
    }
    func testOld1999OfferAndDifferentRenewalCannotBePresentedAs25PercentOff() {
        XCTAssertFalse(GiftOfferRules.isQuarterOff(firstYear: Decimal(string: "19.99")!, regular: Decimal(string: "39.99")!, renewal: Decimal(string: "39.99")!))
        XCTAssertFalse(GiftOfferRules.isQuarterOff(firstYear: 30, regular: 40, renewal: 30))
        XCTAssertFalse(GiftOfferRules.isQuarterOff(firstYear: 40, regular: 40, renewal: 40))
        XCTAssertFalse(GiftOfferRules.isQuarterOff(firstYear: 0, regular: 40, renewal: 40))
        XCTAssertFalse(GiftOfferRules.isQuarterOff(firstYear: -30, regular: 40, renewal: 40))
    }
}
