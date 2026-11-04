import Foundation
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

    func configure(app: AppModel) {
        self.app = app
        #if DEBUG
        // Review switch: `-hcSkipBilling YES` (simulator screenshots without App Store prompts).
        if UserDefaults.standard.bool(forKey: "hcSkipBilling") { return }
        #endif
        configured = true
        Superwall.configure(apiKey: Self.publicKey)
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
        guard configured else { return }
        let handler = PaywallPresentationHandler()
        handler.onDismiss { [weak self] _, result in
            Task { @MainActor in
                switch result {
                case .purchased, .restored: await self?.syncPurchase()
                case .declined: break // the dashboard's paywall_decline campaign shows the one-time yearly offer
                }
            }
        }
        handler.onError { error in
            Task { await Analytics.shared.track("paywall_error", ["placement": .string(placement), "message": .string(error.localizedDescription)]) }
        }
        Superwall.shared.register(placement: placement, handler: handler)
    }

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
        let environment = AppConfig.buildChannel == "appstore" ? "production" : "sandbox"
        #endif
        Task { _ = try? await APIClient.shared.send("PUT", "/me/devices", json: ["token": token, "environment": environment, "timeZone": TimeZone.current.identifier]) }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task { @MainActor in Push.didRegister(deviceToken) }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Task { await Analytics.shared.track("push_register_failed") }
    }
}
