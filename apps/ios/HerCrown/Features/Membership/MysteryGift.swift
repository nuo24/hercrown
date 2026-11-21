import Foundation
import StoreKit

/// No assumptions about USD, free trials or a remote paywall's displayed price.
enum GiftOfferRules {
    static func isQuarterOff(firstYear: Decimal, regular: Decimal, renewal: Decimal) -> Bool {
        guard firstYear > 0, regular > firstYear, renewal == regular else { return false }
        // Apple's price tiers may differ by a cent from exactly 75% (e.g. 39.99 → 29.99).
        let ratio = NSDecimalNumber(decimal: firstYear / regular).doubleValue
        return abs(ratio - 0.75) <= 0.001
    }
}

struct MysteryGiftTerms: Equatable {
    let original: String
    let firstYear: String
    let renewal: String
    let saving: String
}

struct MysteryGiftOffer: Identifiable {
    let id = UUID()
    let userID: String
    let product: Product
    let terms: MysteryGiftTerms
}

@MainActor final class MysteryGiftCoordinator {
    static let shared = MysteryGiftCoordinator()
    private var loading: Task<MysteryGiftOffer?, Never>?
    private var preparedUser: String?
    private var showing = false
    func reset() { loading?.cancel(); loading = nil; preparedUser = nil; showing = false }
    func prepare(app: AppModel) {
        guard let user = app.me?.user.id, !app.membership.premium, preparedUser != user else { return }
        loading?.cancel(); preparedUser = user
        loading = Task { await Self.resolve(userID: user) }
    }
    func afterDecline(app: AppModel, userID: String) async {
        guard !showing, app.me?.user.id == userID, !app.membership.premium,
              app.mysteryGift == nil, !UserDefaults.standard.bool(forKey: "hc.mysteryGiftSeen.\(userID)") else { return }
        showing = true
        defer { showing = false }
        prepare(app: app)
        guard let offer = await loading?.value, !Task.isCancelled, app.me?.user.id == userID,
              !app.membership.premium, !Billing.shared.isPaywallBusy else { return }
        UserDefaults.standard.set(true, forKey: "hc.mysteryGiftSeen.\(userID)")
        app.mysteryGift = offer
        await Analytics.shared.track("mystery_gift_viewed")
    }
    static func resolve(userID: String) async -> MysteryGiftOffer? {
        // A separate introductory annual product must renew at the same annual price.
        // Existing disabled $19.99 offers do not qualify and are never enabled here.
        guard let products = try? await Product.products(for: ["hercrown.plus.yearly", "hercrown.plus.yearly.offer"]),
              let regular = products.first(where: { $0.id == "hercrown.plus.yearly" }),
              let offer = products.first(where: { $0.id == "hercrown.plus.yearly.offer" }),
              let normalSub = regular.subscription, let sub = offer.subscription,
              normalSub.subscriptionPeriod.unit == .year, normalSub.subscriptionPeriod.value == 1,
              sub.subscriptionPeriod.unit == .year, sub.subscriptionPeriod.value == 1,
              normalSub.subscriptionGroupID == sub.subscriptionGroupID,
              let intro = sub.introductoryOffer, intro.paymentMode == .payUpFront,
              intro.period.unit == .year, intro.period.value == 1, intro.periodCount == 1,
              await sub.isEligibleForIntroOffer,
              GiftOfferRules.isQuarterOff(firstYear: intro.price, regular: regular.price, renewal: offer.price) else { return nil }
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction), .unverified(let transaction, _):
                if AppModel.plusProducts.contains(transaction.productID) { return nil }
            }
        }
        guard !Task.isCancelled else { return nil }
        let terms = MysteryGiftTerms(original: regular.displayPrice, firstYear: intro.displayPrice,
                                     renewal: offer.displayPrice, saving: (regular.price - intro.price).formatted(regular.priceFormatStyle))
        return MysteryGiftOffer(userID: userID, product: offer, terms: terms)
    }
}
