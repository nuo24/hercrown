import Foundation
import StoreKit
import UIKit

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
        guard AppConfig.mysteryGiftsEnabled, let user = app.me?.user.id,
              !app.membership.premium, preparedUser != user else { return }
        loading?.cancel(); preparedUser = user
        loading = Task { await Self.resolve(userID: user) }
    }
    func afterDecline(app: AppModel, userID: String) async {
        guard AppConfig.mysteryGiftsEnabled, app.me?.user.id == userID, !app.membership.premium else { return }
        UserDefaults.standard.set(true, forKey: "hc.mysteryGiftPending.\(userID)")
        await syncPending(app: app, userID: userID)
        // Scheduling never presents an offer in the same session.
    }
    private func syncPending(app: AppModel, userID: String) async {
        let key = "hc.mysteryGiftPending.\(userID)"
        guard UserDefaults.standard.bool(forKey: key), app.me?.user.id == userID else { return }
        do {
            try await app.api.send("POST", "/me/gift-offer/decline", json: [String: String]())
            UserDefaults.standard.removeObject(forKey: key)
        } catch { /* Retry at the next foreground session for this same account. */ }
    }
    private static var presentationIsClear: Bool {
        let window = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows).first { $0.isKeyWindow }
        guard let controller = window?.rootViewController else { return false }
        return controller.presentedViewController == nil
    }
    func onNextOpen(app: AppModel, canPresent: @escaping @MainActor () -> Bool) async {
        guard AppConfig.mysteryGiftsEnabled, !showing, let userID = app.me?.user.id,
              app.onboardingCompleted, !app.membership.premium, app.mysteryGift == nil, Self.presentationIsClear, canPresent() else { return }
        showing = true
        defer { showing = false }
        await syncPending(app: app, userID: userID)
        struct Status: Decodable { let due: Bool }
        guard let status: Status = try? await app.api.get("/me/gift-offer"), status.due,
              !Task.isCancelled, app.me?.user.id == userID, canPresent() else { return }
        // Re-resolve current StoreKit eligibility and price; do not use yesterday's preload.
        guard let offer = await Self.resolve(userID: userID), !Task.isCancelled,
              app.me?.user.id == userID, !app.membership.premium,
              !Billing.shared.isPaywallBusy, app.mysteryGift == nil, Self.presentationIsClear, canPresent() else { return }
        struct Claim: Decodable { let available: Bool }
        guard let response = try? await app.api.send("POST", "/me/gift-offer/claim", json: [String: String]()),
              let claim = try? JSONDecoder().decode(Claim.self, from: response.0), claim.available, !Task.isCancelled, app.me?.user.id == userID,
              !app.membership.premium, Self.presentationIsClear, canPresent() else { return }
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
