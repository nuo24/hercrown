import Foundation

/// Answers remain in the device Keychain while setup is unfinished, not in analytics or the Lock Screen card.
struct OnboardingDraft: Codable {
    var step: Int
    var answers: PersonalOnboardingAnswers
    var reminders: Bool
    var reminderTime: Date
    private static let key = "onboarding-draft"

    static func load() -> Self? {
        guard !UserDefaults.standard.bool(forKey: "hc.onboardingCompleted"),
              let raw = Keychain.read(key), let data = raw.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(Self.self, from: data)
    }

    func save() {
        guard !UserDefaults.standard.bool(forKey: "hc.onboardingCompleted"),
              let data = try? JSONEncoder().encode(self), let raw = String(data: data, encoding: .utf8) else { return }
        Keychain.write(raw, for: Self.key)
    }
    static func clear() { Keychain.delete(key) }
}
