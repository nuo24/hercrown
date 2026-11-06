import Foundation
import StoreKit
import SuperwallKit
import UIKit
import UserNotifications

/// Superwall: paywalls and purchases (decision 0003). Paywall designs, prices and the decline offer live in the Superwall
/// dashboard; the app only registers placements. Plus is decided by the server (`entitlements`, written from verified
/// webhooks), so after a purchase the app asks the server to verify it with Apple at once instead of waiting.
@MainActor
final class Billing: NSObject {
    static let shared = Billing()
    static let publicKey = "pk_SGw2nWg_kT_6jdODgrXcl" // public SDK key (safe in the app)

    private weak var app: AppModel?

    private(set) var configured = false
    private var presentingPlacement: UUID?
    var isPaywallBusy: Bool {
        configured && (presentingPlacement != nil || Superwall.shared.isPaywallPresented)
    }

    static func isSandbox() async -> Bool {
        guard case .verified(let transaction) = try? await AppTransaction.shared else { return false }
        return transaction.environment == .sandbox
    }

    func configure(app: AppModel) {
        self.app = app
        #if DEBUG
        // Review switch: `-hcSkipBilling YES` (simulator screenshots without App Store prompts).
        if UserDefaults.standard.bool(forKey: "hcSkipBilling") { return }
        #endif
        configured = true
        let options = SuperwallOptions()
        #if HC_STAGING_TESTFLIGHT
        options.testModeBehavior = .never
        #elseif DEBUG
        if UserDefaults.standard.bool(forKey: "hcPaywallDiagnostics") {
            // Exercise the Apple sandbox payment sheet during this diagnostic run.
            options.testModeBehavior = .never
        }
        #endif
        Superwall.configure(apiKey: Self.publicKey, options: options)
        Superwall.shared.delegate = self
    }

    /// Same user id as our server, so Superwall's webhooks name the right account.
    func identify(userId: String, onboarding: Preferences) {
        guard configured else { return }
        Superwall.shared.identify(userId: userId)
        var attributes: [String: Any] = ["translation": onboarding.translation, "topics": onboarding.topics.joined(separator: ",")]
        if let intention = onboarding.intention { attributes["intention"] = intention }
        if let familiarity = onboarding.familiarity { attributes["familiarity"] = familiarity }
        Superwall.shared.setUserAttributes(attributes)
    }

    /// Shows the paywall campaign for this placement (onboarding_complete, study_explain, plan_start, settings…).
    func present(placement: String) {
        guard configured, !isPaywallBusy else { return }
        let style: InterfaceStyle?
        switch placement == "onboarding_complete" ? "light" : app?.preferences.appearance {
        case "light": style = .light
        case "dark": style = .dark
        default: style = nil
        }
        Superwall.shared.setInterfaceStyle(to: style)
        let requestID = UUID()
        let userID = app?.me?.user.id
        presentingPlacement = requestID
        let handler = PaywallPresentationHandler()
        handler.onDismiss { [weak self] _, result in
            Task { @MainActor in
                guard let self, self.presentingPlacement == requestID else { return }
                self.presentingPlacement = nil
                switch result {
                case .purchased, .restored: await self.syncPurchase()
                case .declined:
                    if let userID { await self.scheduleReturnOffer(for: userID) }
                }
            }
        }
        handler.onError { [weak self] error in
            let message = error.localizedDescription
            Task { @MainActor in
                if self?.presentingPlacement == requestID { self?.presentingPlacement = nil }
                await Analytics.shared.track("paywall_error", ["placement": .string(placement), "message": .string(message)])
                #if DEBUG
                await self?.reportPaywallDiagnostic(placement: placement, reason: message)
                #endif
            }
        }
        handler.onSkip { [weak self] (reason: PaywallSkippedReason) in
            Task { @MainActor in
                if self?.presentingPlacement == requestID { self?.presentingPlacement = nil }
                await Analytics.shared.track("paywall_skipped", ["placement": .string(placement), "reason": .string(reason.description)])
                #if DEBUG
                await self?.reportPaywallDiagnostic(placement: placement, reason: reason.description)
                #endif
            }
        }
        Superwall.shared.register(placement: placement, handler: handler)
    }

    func scheduleReturnOffer(for userID: String) async {
        guard AppConfig.isStaging, configured, let app, app.me?.user.id == userID,
              !app.membership.premium else { return }
        UserDefaults.standard.set(true, forKey: pendingDeclineKey(userID))
        await syncPendingDecline(for: userID)
    }

    private func pendingDeclineKey(_ userID: String) -> String { "hc.pendingPaywallDecline.\(userID)" }

    func syncPendingDecline(for userID: String) async {
        let key = pendingDeclineKey(userID)
        guard UserDefaults.standard.bool(forKey: key), let app, app.me?.user.id == userID,
              let token = app.api.token, await Self.isSandbox() else { return }
        do {
            _ = try await app.api.send("POST", "/me/return-offer/decline", authentication: .bearer(token))
            UserDefaults.standard.removeObject(forKey: key)
        } catch {
            // Keep the decline for the next foreground check if this request was interrupted.
        }
    }

    #if DEBUG
    private func reportPaywallDiagnostic(placement: String, reason: String) async {
        guard UserDefaults.standard.bool(forKey: "hcPaywallDiagnostics"), let app else { return }
        let serverStatus = app.me == nil ? "Unavailable" : (app.membership.premium ? "Plus" : "Free")
        let superwallStatus = switch Superwall.shared.subscriptionStatus {
        case .active: "Active"
        case .inactive: "Inactive"
        case .unknown: "Unknown"
        }
        var appleStatus = "No verified Her Crown subscription"
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, AppModel.plusProducts.contains(transaction.productID) {
                appleStatus = "Active (\(transaction.environment.rawValue))"
                break
            }
        }
        app.paywallDiagnostic = """
        \(placement)
        \(reason)

        Her Crown: \(serverStatus)
        Superwall: \(superwallStatus)
        Apple: \(appleStatus)
        """
    }
    #endif

    func logOut() { if configured { Superwall.shared.reset() } }

    /// After a purchase or restore: the server verifies the transaction with Apple and grants Plus, then the app refreshes.
    /// If she just started a free trial, offer the trial-ending reminder (docs/trial-reminder.md).
    func syncPurchase() async {
        guard let app else { return }
        _ = await app.restorePurchases()
        if app.membership.subscription?.isTrial == true { await Push.offerTrialReminder() }
    }
}

extension Billing: SuperwallDelegate {
    /// Superwall's events into our analytics (purchases themselves are counted only from verified webhooks).
    nonisolated func handleSuperwallEvent(withInfo eventInfo: SuperwallEventInfo) {
        let name: String? = switch eventInfo.event {
        case .paywallOpen: "paywall_viewed"
        case .paywallClose: "paywall_closed"
        case .paywallDecline: "paywall_declined"
        case .transactionStart: "purchase_started"
        case .transactionAbandon: "purchase_abandoned"
        case .transactionFail: "purchase_failed"
        case .transactionComplete: "purchase_completed_client"
        case .freeTrialStart: "trial_started_client"
        default: nil
        }
        guard let name else { return }
        Task { await Analytics.shared.track(name) }
    }
}

/// Remote notifications: the server sends the trial-ending reminder through APNs.
@MainActor
enum Push {
    /// Asks once, right after a trial starts, then registers the device.
    static func offerTrialReminder() async {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        await Analytics.shared.track("push_permission", ["granted": .bool(granted), "placement": "trial_started"])
        if granted { UIApplication.shared.registerForRemoteNotifications() }
    }

    /// On launch: if she already allowed notifications, refresh the token (tokens change).
    static func registerIfAllowed() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        if settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    static func didRegister(_ deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        #if DEBUG
        let environment = "sandbox"
        #else
        let environment = "production"
        #endif
        Task { _ = try? await APIClient.shared.send("PUT", "/me/devices", json: ["token": token, "environment": environment, "timeZone": TimeZone.current.identifier]) }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    static let externalOpen = Notification.Name("hercrown.externalOpen")
    private(set) var openedExternally = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        openedExternally = options?[.url] != nil || options?[.remoteNotification] != nil || options?[.userActivityDictionary] != nil
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        await MainActor.run {
            openedExternally = true
            NotificationCenter.default.post(name: Self.externalOpen, object: nil)
        }
    }


    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task { @MainActor in Push.didRegister(deviceToken) }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Task { await Analytics.shared.track("push_register_failed") }
    }
}
