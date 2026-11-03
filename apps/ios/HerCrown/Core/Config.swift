import Foundation

/// Build-time configuration. Secrets never live in the app: the server holds every key.
enum AppConfig {
    /// The API. Debug and TestFlight builds use staging until production is deployed (humans only).
    static let apiBaseURL = URL(string: "https://bible-scroll-api-staging.bible-scroll-api.workers.dev")!

    /// Sent as `X-Build`: purchases and events from non-App Store builds are marked sandbox in analytics.
    static var buildChannel: String {
        #if DEBUG
        return "debug"
        #else
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" ? "testflight" : "appstore"
        #endif
    }

    static var appVersion: String {
        let info = Bundle.main.infoDictionary
        return "\(info?["CFBundleShortVersionString"] as? String ?? "0") (\(info?["CFBundleVersion"] as? String ?? "0"))"
    }

    /// One id per install (UserDefaults, not the Keychain, so a reinstall counts as a new install).
    static var installID: String {
        let key = "hc.installID"
        if let id = UserDefaults.standard.string(forKey: key) { return id }
        let id = UUID().uuidString.lowercased()
        UserDefaults.standard.set(id, forKey: key)
        return id
    }
}
