import Foundation
import Observation

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
    var saved: Set<String> = Set(UserDefaults.standard.stringArray(forKey: "hc.saved") ?? [])
    var onboardingCompleted = UserDefaults.standard.bool(forKey: "hc.onboardingCompleted")
    var offline = false
    /// A paywall request (placement name). Superwall presents it once integrated; until then RootView explains.
    var paywallPlacement: String?
    /// Another tab asked to show this one (e.g. Home → read a verse in The Bible).
    var requestedTab: AppTab?
    /// A topic Discover should open on (Home's "For the season you're in" cards).
    var discoverTopic: String?

    let api = APIClient.shared
    let bible = BibleStore.shared

    var displayName: String? { me?.profile.displayName }

    // MARK: Launch

    func start() async {
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
        await Analytics.shared.flush()
    }

    func signInAsGuest() async throws {
        let (_, response) = try await api.send("POST", "/api/auth/sign-in/anonymous", json: [String: Any]())
        guard let token = response.value(forHTTPHeaderField: "set-auth-token") else { throw APIError.offline }
        api.token = token
    }

    func refresh() async throws {
        let me: Me = try await api.get("/me")
        self.me = me
        preferences = me.preferences
        membership = me.membership
        onboardingCompleted = me.onboarding.completed || onboardingCompleted
        Self.cache(preferences)
        UserDefaults.standard.set(onboardingCompleted, forKey: "hc.onboardingCompleted")
        struct SavedList: Decodable { struct Item: Decodable { let ref: String }; let saved: [Item] }
        if let list: SavedList = try? await api.get("/me/saved") {
            saved = Set(list.saved.map(\.ref))
            UserDefaults.standard.set(Array(saved), forKey: "hc.saved")
        }
    }

    // MARK: Membership

    func presentPaywall(placement: String) {
        paywallPlacement = placement
        Task { await Analytics.shared.track("paywall_requested", ["placement": .string(placement)]) }
    }

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
        Task { _ = try? await api.send("PATCH", "/me/preferences", json: patch) }
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
