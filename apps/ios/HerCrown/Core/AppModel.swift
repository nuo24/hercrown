import Foundation
import Observation
import StoreKit
import UserNotifications

/// App-wide state: the session, her preferences and membership, saved verses. Reading works offline from the bundled
/// Bibles; anything that needs the server is retried when the connection returns.
@MainActor
@Observable
final class AppModel {
    enum Phase: Equatable { case launching, ready }

    var phase: Phase = .launching
    var me: Me?
    var preferences: Preferences = AppModel.cachedPreferences ?? .defaults
    var membership: Membership = .free
    var showExistingAppleSubscription = false
    private var checkingPaywall = false
    var saved: Set<String> = Set(UserDefaults.standard.stringArray(forKey: "hc.saved") ?? [])
    private var bookmarksByAccount = UserDefaults.standard.dictionary(forKey: "hc.readerBookmarks") as? [String: [String]] ?? [:]

    private var bookmarkAccount: String {
        me?.user.id ?? "offline"
    }

    var readerBookmarks: [String] { bookmarksByAccount[bookmarkAccount] ?? [] }

    func toggleBookmark(_ ref: String) {
        let account = bookmarkAccount
        var refs = readerBookmarks
        if let index = refs.firstIndex(of: ref) { refs.remove(at: index) }
        else { refs.insert(ref, at: 0) }
        bookmarksByAccount[account] = refs
        UserDefaults.standard.set(bookmarksByAccount, forKey: "hc.readerBookmarks")
    }

    var onboardingCompleted = UserDefaults.standard.bool(forKey: "hc.onboardingCompleted")
    var offline = false
    /// Another tab asked to show this one (e.g. Home → read a verse in The Bible).
    var requestedTab: AppTab?
    /// A topic Discover should open on (Home's "For the season you're in" cards).
    var discoverTopic: String?

    let api = APIClient.shared
    let bible = BibleStore.shared

    var displayName: String? { me?.profile.displayName }

    #if DEBUG
    var paywallDiagnostic: String?
    #endif

    // MARK: Launch

    func start() async {
        #if DEBUG
        // Review switch: `-hcFreshStart YES` forgets this phone's session and local state, so the app starts as a new
        // guest at the first onboarding screen. (Deleting the app isn't enough: the Keychain keeps the session.)
        if UserDefaults.standard.bool(forKey: "hcFreshStart") {
            api.token = nil
            Billing.shared.logOut()
            for key in ["hc.saved", "hc.preferences", "hc.streak", "hc.position", "hc.onboardingCompleted"] { UserDefaults.standard.removeObject(forKey: key) }
            saved = []; preferences = .defaults; membership = .free; me = nil; onboardingCompleted = false
        }
        #endif
        await Analytics.shared.track("app_opened")
        do {
            if api.token == nil { try await signInAsGuest() }
            try await refresh()
            offline = false
            _ = try? await api.send("POST", "/me/opened", json: ["localDay": Self.localDay()])
        } catch let error as APIError where error.status == 401 {
            api.token = nil // session gone (e.g. account deleted elsewhere): start fresh as a guest
            try? await signInAsGuest()
            try? await refresh()
        } catch {
            offline = true
        }
        phase = .ready
        await WidgetBridge.refresh(translation: preferences.translation)
        await Analytics.shared.flush()
    }

    func signInAsGuest() async throws {
        api.token = try await guestSessionToken()
    }

    private func guestSessionToken() async throws -> String {
        let (_, response) = try await api.send("POST", "/api/auth/sign-in/anonymous", json: [String: Any](), authentication: .anonymous)
        guard let token = response.value(forHTTPHeaderField: "set-auth-token") else { throw APIError.offline }
        return token
    }

    func refresh() async throws {
        let token = api.token
        let me: Me = try await api.get("/me")
        guard api.token == token else { return }
        applySession(me)
        struct SavedList: Decodable { struct Item: Decodable { let ref: String }; let saved: [Item] }
        if let list: SavedList = try? await api.get("/me/saved"), api.token == token {
            saved = Set(list.saved.map(\.ref))
            UserDefaults.standard.set(Array(saved), forKey: "hc.saved")
        }
    }

    private func applySession(_ me: Me) {
        if self.me?.user.id != me.user.id { Billing.shared.identify(userId: me.user.id, onboarding: me.preferences) }
        self.me = me
        preferences = me.preferences
        membership = me.membership
        onboardingCompleted = me.onboarding.completed || onboardingCompleted
        Self.cache(preferences)
        UserDefaults.standard.set(onboardingCompleted, forKey: "hc.onboardingCompleted")
    }

    // MARK: Sandbox testing

    private static let testBackupToken = "test-session-original-token"
    private static let testBackupDefaults = "hc.testSessionBackup"
    private static let sessionDefaults = [
        "hc.saved", "hc.preferences", "hc.streak", "hc.position", "hc.onboardingCompleted",
        "hcOnboardingStep",
    ]

    var hasTestSessionBackup: Bool { Keychain.read(Self.testBackupToken) != nil }

    static func allowsTestSessions() async -> Bool {
        guard AppConfig.isStaging else { return false }
        #if DEBUG
        return true
        #else
        return await Billing.isSandbox()
        #endif
    }

    func startTestSession() async throws {
        guard await Self.allowsTestSessions(), !hasTestSessionBackup, let original = api.token else { throw APIError.offline }
        let candidate = try await guestSessionToken()
        let guest: Me = try await api.get("/me", authentication: .bearer(candidate))
        guard api.token == original, guest.user.isAnonymous, guest.user.id != me?.user.id,
              !guest.onboarding.completed, !guest.membership.premium else { throw APIError.offline }
        await Analytics.shared.flush()
        guard api.token == original else { throw APIError.offline }

        let defaults = UserDefaults.standard
        var backup: [String: Any] = [:]
        for key in Self.sessionDefaults { backup[key] = defaults.object(forKey: key) }
        defaults.set(backup, forKey: Self.testBackupDefaults)
        Keychain.write(original, for: Self.testBackupToken)
        guard hasTestSessionBackup else { throw APIError.offline }
        switchTestSession(to: guest, token: candidate, localState: [:])
    }

    func restoreTestSession() async throws {
        guard await Self.allowsTestSessions(), let original = Keychain.read(Self.testBackupToken) else { throw APIError.offline }
        let account: Me = try await api.get("/me", authentication: .bearer(original))
        await Analytics.shared.flush()
        let defaults = UserDefaults.standard
        switchTestSession(to: account, token: original, localState: defaults.dictionary(forKey: Self.testBackupDefaults) ?? [:])
        Keychain.delete(Self.testBackupToken)
        defaults.removeObject(forKey: Self.testBackupDefaults)
    }

    private func switchTestSession(to account: Me, token: String, localState: [String: Any]) {
        api.token = token
        Billing.shared.logOut()
        me = nil
        let defaults = UserDefaults.standard
        for key in Self.sessionDefaults { defaults.set(localState[key], forKey: key) }
        saved = Set(defaults.stringArray(forKey: "hc.saved") ?? [])
        onboardingCompleted = defaults.bool(forKey: "hc.onboardingCompleted")
        requestedTab = nil
        discoverTopic = nil
        offline = false
        applySession(account)
        if preferences.remindersEnabled { DailyReminder.schedule(at: DailyReminder.time(from: preferences.reminderTime)) }
        else { DailyReminder.cancel() }
        Task { await WidgetBridge.refresh(translation: account.preferences.translation) }
    }

    // MARK: Membership

    func refreshMembership() async {
        guard let userID = me?.user.id else { return }
        let updated: Membership? = try? await api.get("/me/entitlements")
        guard !Task.isCancelled, me?.user.id == userID else { return }
        if let updated { membership = updated }
        else if membership.subscription?.isTrial == true,
                let expires = membership.subscription?.expiresAt,
                expires <= Date().timeIntervalSince1970 * 1000 {
            membership = .free
        }
    }

    /// StoreKit knows what the device's Apple account already bought, even when the current app account is Free.
    func activeAppleSubscription() async -> Transaction? {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, Self.plusProducts.contains(transaction.productID) {
                return transaction
            }
        }
        return nil
    }

    func presentPaywall(placement: String, onExistingSubscription: (() -> Void)? = nil) {
        guard !checkingPaywall, !membership.premium else { return }
        checkingPaywall = true
        let userID = me?.user.id
        Task {
            defer { checkingPaywall = false }
            // A fresh staging guest can exercise onboarding even if the tester's Apple account has Plus.
            let isFreshTestOnboarding: Bool
            if placement == "onboarding_complete", hasTestSessionBackup {
                isFreshTestOnboarding = await Self.allowsTestSessions()
            } else {
                isFreshTestOnboarding = false
            }
            let existing = isFreshTestOnboarding ? nil : await activeAppleSubscription()
            guard me?.user.id == userID, !membership.premium else { return }
            if existing != nil {
                if let onExistingSubscription { onExistingSubscription() }
                else { showExistingAppleSubscription = true }
                return
            }
            Billing.shared.present(placement: placement)
            await Analytics.shared.track("paywall_requested", ["placement": .string(placement)])
        }
    }

    // MARK: Account

    var isGuest: Bool { me?.user.isAnonymous ?? true }

    /// Sign in with Apple: links this guest's data to her Apple account (decision 0002), then refreshes.
    func signInWithApple(identityToken: String) async throws {
        let (_, response) = try await api.send("POST", "/api/auth/sign-in/social", json: ["provider": "apple", "idToken": ["token": identityToken]])
        if let token = response.value(forHTTPHeaderField: "set-auth-token") { api.token = token }
        try await refresh()
        await Analytics.shared.track("signed_in", ["method": "apple"])
    }

    func updateProfile(displayName: String, bio: String) async throws {
        try await api.send("PATCH", "/me/profile", json: ["displayName": displayName, "bio": bio])
        try await refresh()
        await Analytics.shared.track("profile_updated")
    }

    func uploadAvatar(_ jpeg: Data) async throws {
        try await api.upload("PUT", "/me/avatar", data: jpeg, contentType: "image/jpeg")
        try await refresh()
        await Analytics.shared.track("avatar_updated")
    }

    func removeAvatar() async throws {
        try await api.send("DELETE", "/me/avatar")
        try await refresh()
    }

    /// Deletes the account and everything in it on the server, then starts over as a new guest on this phone.
    /// Onboarding stays complete (Settings never sends her back through it).
    func deleteAccount() async throws {
        await Analytics.shared.track("account_deleted")
        await Analytics.shared.flush()
        let deletedAccount = bookmarkAccount
        try await api.send("POST", "/api/auth/delete-user", json: [String: Any]())
        bookmarksByAccount.removeValue(forKey: deletedAccount)
        UserDefaults.standard.set(bookmarksByAccount, forKey: "hc.readerBookmarks")
        api.token = nil
        for key in ["hc.saved", "hc.preferences", "hc.streak", "hc.position"] { UserDefaults.standard.removeObject(forKey: key) }
        saved = []
        preferences = .defaults
        membership = .free
        me = nil
        DailyReminder.cancel()
        Billing.shared.logOut()
        try await signInAsGuest()
        try await refresh()
    }

    // MARK: Restore purchases

    /// Restore (docs/restore-purchases.md): sync with the App Store, then have the server verify the Plus transaction
    /// with Apple. Returns what to tell her.
    func restorePurchases() async -> String {
        await Analytics.shared.track("restore_tapped")
        try? await AppStore.sync()
        return await verifyPurchases()
    }

    func verifyPurchases(transactionID verifiedID: String? = nil) async -> String {
        var transactionId = verifiedID
        if transactionId == nil {
            if let active = await activeAppleSubscription() { transactionId = String(active.originalID) }
        }
        if transactionId == nil {
            for await result in Transaction.all {
                if case .verified(let tx) = result, Self.plusProducts.contains(tx.productID) { transactionId = String(tx.originalID) }
            }
        }
        guard let transactionId else { return "We couldn’t find a Her Crown Plus purchase for this Apple ID." }
        struct Outcome: Decodable { let restored: Bool; let reason: String?; let alreadyActive: Bool? }
        do {
            let outcome: Outcome = try await api.call("POST", "/me/restore", json: ["transactionId": transactionId])
            try? await refresh()
            if outcome.restored { return outcome.alreadyActive == true ? "Plus is already active on this account." : "Welcome back to Plus." }
            switch outcome.reason {
            case "expired": return "Your Plus subscription has ended. You can subscribe again any time."
            case "billing_retry": return "Apple couldn’t renew your subscription. Update your payment method in iPhone Settings."
            case "revoked": return "This purchase was refunded, so Plus isn’t active."
            default: return "We couldn’t find a Her Crown Plus purchase for this Apple ID."
            }
        } catch let error as APIError {
            return error.status == 503 ? "The App Store isn’t answering right now. Please try again in a moment." : error.message
        } catch {
            return APIError.offline.message
        }
    }

    static let plusProducts: Set<String> = ["hercrown.plus.yearly", "hercrown.plus.monthly", "hercrown.plus.weekly", "hercrown.plus.yearly.offer"]

    // MARK: Navigation

    /// Opens The Bible at this verse: the reader starts from the saved position, so set it, then switch tabs.
    func openInReader(_ ref: VerseRef) {
        UserDefaults.standard.set(ref.description, forKey: "hc.position")
        requestedTab = .bible
    }

    // MARK: Onboarding

    /// Marks onboarding complete locally at once (so it never shows again) and on the server (first completion counts).
    func completeOnboarding() async {
        onboardingCompleted = true
        UserDefaults.standard.set(true, forKey: "hc.onboardingCompleted")
        if api.token == nil { try? await signInAsGuest() }
        _ = try? await api.send("POST", "/me/onboarding/complete")
    }

    // MARK: Saved verses

    func isSaved(_ ref: String) -> Bool { saved.contains(ref) }

    func toggleSave(_ ref: String) {
        let saving = !saved.contains(ref)
        if saving { saved.insert(ref) } else { saved.remove(ref) }
        UserDefaults.standard.set(Array(saved), forKey: "hc.saved")
        Task {
            do {
                try await api.send(saving ? "PUT" : "DELETE", "/me/saved/\(ref)")
            } catch {
                offline = true // kept locally; synced on the next successful refresh
            }
        }
    }

    // MARK: Preferences

    /// Updates locally at once, then on the server. Never touches onboarding completion.
    func updatePreferences(_ patch: [String: Any], apply: (inout Preferences) -> Void) {
        apply(&preferences)
        Self.cache(preferences)
        let translation = preferences.translation
        Task {
            _ = try? await api.send("PATCH", "/me/preferences", json: patch)
            if patch["widgetRef"] != nil || patch["translation"] != nil { await WidgetBridge.refresh(translation: translation) }
        }
    }

    // MARK: Helpers

    static func localDay(_ date: Date = Date()) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private static var cachedPreferences: Preferences? {
        guard let data = UserDefaults.standard.data(forKey: "hc.preferences") else { return nil }
        return try? JSONDecoder().decode(Preferences.self, from: data)
    }

    private static func cache(_ p: Preferences) {
        UserDefaults.standard.set(try? JSONEncoder().encode(p), forKey: "hc.preferences")
    }
}
