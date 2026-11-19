import Foundation

/// Device-level cooldown survives relaunches; signing in or having Plus always suppresses automatic prompts.
struct GuestPaywallHistory {
    var lastRequest: Date?
    func canRequest(isGuest: Bool, premium: Bool, now: Date = .now) -> Bool {
        isGuest && !premium && (lastRequest.map { now.timeIntervalSince($0) >= 24 * 3600 } ?? true)
    }
}

@MainActor
final class GuestPaywallPrompter {
    static let shared = GuestPaywallPrompter()
    private let defaults: UserDefaults
    private let key = "hc.lastGuestPaywallRequest"
    init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    func canRequest(isGuest: Bool, premium: Bool, now: Date = .now) -> Bool {
        GuestPaywallHistory(lastRequest: defaults.object(forKey: key) as? Date)
            .canRequest(isGuest: isGuest, premium: premium, now: now)
    }
    func requested(now: Date = .now) { defaults.set(now, forKey: key) }
}

/// Offer at the next chapter boundary, after she has seen the ending and several distinct verses.
/// Jumping straight to a final verse, translating the same chapter or revisiting a verse isn't completion.
struct GuestChapterProgress {
    private var chapter: String?
    private var seen: Set<Int> = []
    private var count = 0
    private var last = 0

    mutating func record(chapter key: String, verse: Int, verseCount: Int, lastVerse: Int) -> Bool {
        let crossedCompletedChapter = chapter != nil && chapter != key
            && seen.contains(last) && seen.count >= min(3, count) && count > 0
        if chapter != key { chapter = key; seen.removeAll(); count = verseCount; last = lastVerse }
        seen.insert(verse)
        return crossedCompletedChapter
    }
}
