import Foundation

// Shapes of the API responses the app uses (docs/api.md). Unknown fields are ignored.

struct Me: Decodable {
    struct User: Decodable { let id: String; let isAnonymous: Bool; let email: String? }
    struct Profile: Decodable { let displayName: String?; let bio: String?; let avatarUrl: String? }
    struct Onboarding: Decodable { let completed: Bool; let completedAt: Double?; let version: Int? }
    let user: User
    let profile: Profile
    let preferences: Preferences
    let onboarding: Onboarding
    let membership: Membership
}

struct Preferences: Codable, Equatable {
    var intention: String?
    var familiarity: String?
    var topics: [String]
    var routine: String?
    var remindersEnabled: Bool
    var reminderTime: String
    var timeZone: String?
    var appearance: String
    var fontSize: String
    var wordsOfJesusInRed: Bool
    var translation: String
    var widgetRef: String?

    static let defaults = Preferences(intention: nil, familiarity: nil, topics: [], routine: nil, remindersEnabled: false,
                                      reminderTime: "08:00", timeZone: nil, appearance: "dark", fontSize: "default",
                                      wordsOfJesusInRed: true, translation: "kjv", widgetRef: nil)
}

struct Membership: Decodable, Equatable {
    struct Trial: Decodable, Equatable { let endsAt: Double; let convertsToPaid: Bool; let remindFrom: Double; let manageUrl: String }
    struct Subscription: Decodable, Equatable {
        let status: String
        let productId: String?
        let expiresAt: Double?
        let willRenew: Bool
        let isTrial: Bool
        let trial: Trial?
    }
    let premium: Bool
    let subscription: Subscription?

    static let free = Membership(premium: false, subscription: nil)
}
