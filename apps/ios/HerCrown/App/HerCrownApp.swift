import StoreKit
import SwiftUI

@main
struct HerCrownApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var app = AppModel()
    @State private var returnProduct: Product?
    @State private var showingReturnOffer = false
    @State private var returnOfferMessage: String?
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            appContent.alert("Paywall test result", isPresented: Binding(
                get: { app.paywallDiagnostic != nil },
                set: { if !$0 { app.paywallDiagnostic = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: { Text(app.paywallDiagnostic ?? "") }
            #else
            appContent
            #endif
        }
    }

    private var appContent: some View {
        RootView()
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
            .task(id: scenePhase == .active && app.phase == .ready) {
                if scenePhase == .active && app.phase == .ready { await checkReturnOffer() }
            }
            .task(id: scenePhase == .active && app.phase == .ready) {
                guard scenePhase == .active && app.phase == .ready else { return }
                await app.refreshMembership()
            }
            .task(id: app.membership) {
                guard app.membership.premium, let trial = app.membership.subscription?.trial else { return }
                let delay = max(0, trial.endsAt / 1000 - Date().timeIntervalSince1970)
                guard delay > 0 else { return }
                try? await Task.sleep(for: .seconds(delay))
                if !Task.isCancelled { await app.refreshMembership() }
            }
            .alert("Save $10 on your first year", isPresented: $showingReturnOffer) {
                Button("Claim my first year") { Task { await purchaseReturnOffer() } }
                Button("Maybe later", role: .cancel) {}
            } message: {
                Text("$19.99 for your first year of Her Crown Plus, then $29.99 per year. Auto-renews until canceled.")
            }
            .alert("Her Crown Plus", isPresented: Binding(
                get: { returnOfferMessage != nil },
                set: { if !$0 { returnOfferMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: { Text(returnOfferMessage ?? "") }
            .onChange(of: scenePhase) { _, phase in
                if phase == .background { Task { await Analytics.shared.flush() } }
            }
    }

    private let returnOfferID = "trial_return_1999"

    private func checkReturnOffer() async {
        guard #available(iOS 17.2, *), let user = app.me?.user, app.onboardingCompleted else { return }
        let key = "hc.trialReturnShown.\(user.id)"
        let defaults = UserDefaults.standard
        let day = AppModel.localDay()
        guard defaults.string(forKey: key) != day,
              await Storefront.current?.countryCode == "USA",
              let product = try? await Product.products(for: ["hercrown.plus.yearly"]).first,
              product.price == Decimal(string: "29.99"),
              let subscription = product.subscription,
              subscription.promotionalOffers.contains(where: {
                  $0.id == returnOfferID && $0.price == Decimal(string: "19.99") && $0.paymentMode == .payUpFront
              }),
              let statuses = try? await subscription.status else { return }
        let eligible = statuses.contains { status in
            guard status.state == .subscribed,
                  case .verified(let tx) = status.transaction,
                  case .verified(let renewal) = status.renewalInfo else { return false }
            return tx.environment == .sandbox && tx.productID == product.id &&
                tx.offer?.type == .introductory && tx.offer?.paymentMode == .freeTrial &&
                (tx.expirationDate ?? .distantPast) > Date() && !renewal.willAutoRenew
        }
        guard eligible, !Task.isCancelled, app.me?.user.id == user.id,
              scenePhase == .active, defaults.string(forKey: key) != day else { return }
        defaults.set(day, forKey: key)
        returnProduct = product
        showingReturnOffer = true
    }

    private func purchaseReturnOffer() async {
        guard let product = returnProduct else { return }
        returnProduct = nil
        struct SignedOffer: Decodable { let token: String }
        do {
            let offer: SignedOffer = try await app.api.call("POST", "/me/trial-return-offer", json: [String: String]())
            let options = Product.PurchaseOption.promotionalOffer(returnOfferID, compactJWS: offer.token)
            switch try await product.purchase(options: Set(options)) {
            case .success(.verified(let transaction)):
                returnOfferMessage = await app.verifyPurchases()
                await transaction.finish()
            case .pending:
                returnOfferMessage = "Your purchase is pending approval."
            case .userCancelled:
                break
            default:
                returnOfferMessage = "We couldn’t verify the purchase."
            }
        } catch {
            returnOfferMessage = "The offer couldn’t be applied. Please try again later."
        }
    }

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
