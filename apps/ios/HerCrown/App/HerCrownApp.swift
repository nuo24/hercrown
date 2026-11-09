import StoreKit
import SwiftUI

@main
struct HerCrownApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var app = AppModel()
    @State private var returnOffer: ReturnOffer?
    @State private var checkingOnNextOpen = true
    @State private var purchasingReturnOffer = false
    @State private var returnOfferMessage: String?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var coldLaunch = UserDefaults.standard.bool(forKey: "hc.onboardingCompleted")

    private var showColdLaunch: Bool {
        coldLaunch && !appDelegate.openedExternally && !reduceMotion
    }

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--preview-onboarding") {
                OnboardingView().environment(app).task { await app.start() }
            } else if ProcessInfo.processInfo.arguments.contains("--preview-return-offer") {
                ReturnOfferView(firstYear: "$19.99", renewal: "$29.99", onClaim: {}, onClose: {}, onRestore: {})
                    .preferredColorScheme(colorScheme)
            } else if ProcessInfo.processInfo.arguments.contains("--preview-snapshot"),
                      let chapter = BibleStore.shared.chapter("kjv", book: "PSA", chapter: 23),
                      let verse = chapter.verses.first {
                VerseSnapshotView(text: verse.text, reference: "\(chapter.book.displayName) 23:\(verse.number)",
                                  translation: "King James Version")
                    .environment(app).preferredColorScheme(colorScheme)
            } else {
                appContent.alert("Paywall test result", isPresented: Binding(
                    get: { app.paywallDiagnostic != nil },
                    set: { if !$0 { app.paywallDiagnostic = nil } }
                )) {
                    Button("OK", role: .cancel) {}
                } message: { Text(app.paywallDiagnostic ?? "") }
            }
            #else
            appContent
            #endif
        }
    }

    private var appContent: some View {
        ZStack {
            RootView()
                .accessibilityHidden(showColdLaunch)
                .allowsHitTesting(!showColdLaunch)
            if showColdLaunch {
                ColdLaunchView { coldLaunch = false }
            }
        }
            .environment(app)
            .preferredColorScheme(colorScheme)
            .task {
                // Load her translation off the main thread, then sign in / sync.
                let translation = app.preferences.translation
                await Task.detached(priority: .userInitiated) { BibleStore.shared.preload(translation) }.value
                Billing.shared.configure(app: app)
                await app.start()
                await Push.registerIfAllowed()
            }
            .task(id: scenePhase == .active && app.phase == .ready && !showColdLaunch) {
                guard scenePhase == .active, app.phase == .ready, !showColdLaunch else { return }
                await app.refreshMembership()
                guard !Task.isCancelled, checkingOnNextOpen else { return }
                if showColdLaunch { return }
                checkingOnNextOpen = false
                await checkReturnOffer()
            }
            .task(id: app.membership) {
                guard app.membership.premium, let trial = app.membership.subscription?.trial else { return }
                let delay = max(0, trial.endsAt / 1000 - Date().timeIntervalSince1970)
                guard delay > 0 else { return }
                try? await Task.sleep(for: .seconds(delay))
                if !Task.isCancelled { await app.refreshMembership() }
            }
            .sheet(item: $returnOffer) { offer in
                ReturnOfferView(firstYear: offer.firstYear, renewal: offer.product.displayPrice, busy: purchasingReturnOffer) {
                    Task { await purchaseReturnOffer(offer) }
                } onClose: {
                    returnOffer = nil
                    Task { await Analytics.shared.track("return_offer_dismissed", ["kind": .string(offer.kind.rawValue)]) }
                } onRestore: {
                    returnOffer = nil
                    Task { returnOfferMessage = await app.restorePurchases() }
                }
                .presentationDetents([.large])
                .interactiveDismissDisabled()
                .preferredColorScheme(colorScheme)
            }
            .alert("Apple subscription found", isPresented: $app.showExistingAppleSubscription) {
                Button("Restore Purchases") {
                    Task { returnOfferMessage = await app.restorePurchases() }
                }
                Button("Keep reading", role: .cancel) {}
            } message: {
                Text("This Apple account already has Her Crown Plus. Restoring connects it to your current Her Crown account and may move Plus access from another account.")
            }
            .alert("Her Crown Plus", isPresented: Binding(
                get: { returnOfferMessage != nil },
                set: { if !$0 { returnOfferMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: { Text(returnOfferMessage ?? "") }
            .onOpenURL { _ in coldLaunch = false }
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { _ in coldLaunch = false }
            .onReceive(NotificationCenter.default.publisher(for: AppDelegate.externalOpen)) { _ in coldLaunch = false }
            .onChange(of: reduceMotion) { _, reduced in if reduced { coldLaunch = false } }
            .onChange(of: app.requestedTab) { _, tab in if tab != nil { coldLaunch = false } }
            .onChange(of: scenePhase) { previous, phase in
                if previous == .active, phase != .active { coldLaunch = false }
                if phase == .background {
                    checkingOnNextOpen = true
                    Task { await Analytics.shared.flush() }
                }
            }
    }

    private let returnOfferID = "trial_return_1999"

    private struct ReturnOffer: Identifiable {
        enum Kind: String { case trial, decline }
        let id = UUID()
        let userID: String
        let kind: Kind
        let product: Product
        let firstYear: String
    }

    private func canShowOffer(for userID: String) -> Bool {
        !Task.isCancelled && scenePhase == .active && app.me?.user.id == userID &&
            returnOffer == nil && !purchasingReturnOffer && !Billing.shared.isPaywallBusy
    }

    private func checkReturnOffer() async {
        guard AppConfig.returnOffersEnabled, AppConfig.isStaging, Billing.shared.configured, #available(iOS 17.2, *), let user = app.me?.user, app.onboardingCompleted,
              canShowOffer(for: user.id), await Billing.isSandbox(),
              await Storefront.current?.countryCode == "USA" else { return }
        await Billing.shared.syncPendingDecline(for: user.id)
        let products = (try? await Product.products(for: ["hercrown.plus.yearly", "hercrown.plus.yearly.offer"])) ?? []
        let candidate: ReturnOffer
        if let yearly = products.first(where: { $0.id == "hercrown.plus.yearly" }),
           let subscription = yearly.subscription,
           subscription.subscriptionPeriod.unit == .year, subscription.subscriptionPeriod.value == 1,
           let promo = subscription.promotionalOffers.first(where: { $0.id == returnOfferID && isFirstYear($0) }),
           let statuses = try? await subscription.status,
           statuses.contains(where: { status in
               guard case .verified(let tx) = status.transaction,
                     case .verified(let renewal) = status.renewalInfo else { return false }
               guard tx.environment == .sandbox, AppModel.plusProducts.contains(tx.productID),
                     tx.revocationDate == nil, tx.offer?.id != returnOfferID, !renewal.willAutoRenew else { return false }
               return (status.state == .subscribed && (tx.expirationDate ?? .distantPast) > Date()) ||
                   (status.state == .expired && renewal.expirationReason == .autoRenewDisabled)
           }) {
            candidate = ReturnOffer(userID: user.id, kind: .trial, product: yearly, firstYear: promo.displayPrice)
        } else {
            guard !app.membership.premium,
                  let yearly = products.first(where: { $0.id == "hercrown.plus.yearly.offer" }),
                  yearly.price == Decimal(string: "29.99"), let subscription = yearly.subscription,
                  subscription.subscriptionPeriod.unit == .year, subscription.subscriptionPeriod.value == 1,
                  let intro = subscription.introductoryOffer, isFirstYear(intro),
                  await subscription.isEligibleForIntroOffer else { return }
            for await result in Transaction.currentEntitlements {
                switch result {
                case .verified(let tx), .unverified(let tx, _):
                    if AppModel.plusProducts.contains(tx.productID) { return }
                }
            }
            candidate = ReturnOffer(userID: user.id, kind: .decline, product: yearly, firstYear: intro.displayPrice)
        }

        guard canShowOffer(for: user.id) else { return }
        struct Reservation: Decodable { let available: Bool }
        let reservation: Reservation? = try? await app.api.call(
            "POST", "/me/return-offer/impression", json: ["kind": candidate.kind.rawValue]
        )
        guard reservation?.available == true, canShowOffer(for: user.id) else { return }
        returnOffer = candidate
        await Analytics.shared.track("return_offer_viewed", ["kind": .string(candidate.kind.rawValue)])
    }

    private func isFirstYear(_ offer: Product.SubscriptionOffer) -> Bool {
        let period = offer.period
        let oneYear = (period.unit == .year && period.value == 1) || (period.unit == .month && period.value == 12)
        return offer.price == Decimal(string: "19.99") && offer.paymentMode == .payUpFront &&
            oneYear && offer.periodCount == 1
    }

    private func purchaseReturnOffer(_ offer: ReturnOffer) async {
        guard !purchasingReturnOffer, returnOffer?.id == offer.id, app.me?.user.id == offer.userID else { return }
        purchasingReturnOffer = true
        defer { purchasingReturnOffer = false }
        var message: String?
        await Analytics.shared.track("purchase_started", ["product_id": .string(offer.product.id)])
        do {
            var options = Set<Product.PurchaseOption>()
            if offer.kind == .trial {
                struct SignedOffer: Decodable { let token: String }
                let signed: SignedOffer = try await app.api.call("POST", "/me/trial-return-offer", json: [String: String]())
                options.formUnion(Product.PurchaseOption.promotionalOffer(returnOfferID, compactJWS: signed.token))
            } else if await offer.product.subscription?.isEligibleForIntroOffer != true {
                throw OfferUnavailable()
            }
            guard app.me?.user.id == offer.userID else { return }
            switch try await offer.product.purchase(options: options) {
            case .success(.verified(let transaction)) where transaction.environment == .sandbox:
                guard app.me?.user.id == offer.userID else { return }
                message = await app.verifyPurchases(transactionID: String(transaction.originalID))
                await transaction.finish()
            case .pending:
                message = "Your purchase is pending approval."
            case .userCancelled:
                await Analytics.shared.track("purchase_abandoned")
                return
            default:
                message = "We couldn’t verify the purchase."
            }
        } catch {
            await Analytics.shared.track("purchase_failed", ["product_id": .string(offer.product.id)])
            message = "The offer couldn’t be applied. Please try again later."
        }
        returnOffer = nil
        returnOfferMessage = message
    }

    private struct OfferUnavailable: Error {}

    private var colorScheme: ColorScheme? {
        #if DEBUG
        let appearance = UserDefaults.standard.string(forKey: "hcPreviewAppearance") ?? app.preferences.appearance
        #else
        let appearance = app.preferences.appearance
        #endif
        return switch appearance {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }
}
