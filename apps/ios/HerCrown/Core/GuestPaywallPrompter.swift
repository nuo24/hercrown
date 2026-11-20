import Foundation

/// Device-level cooldown survives relaunches; signing in or having Plus always suppresses automatic prompts.
struct GuestPaywallHistory {
    var lastPresentation: Date?
    func canRequest(isGuest: Bool, premium: Bool, now: Date = .now) -> Bool {
        isGuest && !premium && (lastPresentation.map { now.timeIntervalSince($0) >= 24 * 3600 } ?? true)
    }
}

@MainActor
final class GuestPaywallPrompter {
    static let shared = GuestPaywallPrompter()
    private let defaults: UserDefaults
    private var lastAttempt: Date?
    private let key = "hc.lastGuestPaywallShown"
    init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    func canRequest(isGuest: Bool, premium: Bool, now: Date = .now) -> Bool {
        (lastAttempt.map { now.timeIntervalSince($0) >= 5 * 60 } ?? true)
            && GuestPaywallHistory(lastPresentation: defaults.object(forKey: key) as? Date)
            .canRequest(isGuest: isGuest, premium: premium, now: now)
    }
    func attempted(now: Date = .now) { lastAttempt = now }
    func presented(now: Date = .now) { defaults.set(now, forKey: key) }
}

/// Offer at the next chapter boundary, after she has seen the ending and several distinct verses.
/// Jumping straight to a final verse, translating the same chapter or revisiting a verse isn't completion.
struct GuestChapterProgress {
    private struct Progress {
        var seen: Set<Int> = []
        var count = 0
        var last = 0
        var isComplete: Bool { count > 0 && seen.contains(last) && seen.count >= min(3, count) }
    }
    private var activeChapter: String?
    private var chapters: [String: Progress] = [:]
    private var order: [String] = []
    private var offered: Set<String> = []

    mutating func record(chapter key: String, verse: Int, verseCount: Int, lastVerse: Int) -> Bool {
        var crossedCompletedChapter = false
        if let previous = activeChapter, previous != key, chapters[previous]?.isComplete == true {
            crossedCompletedChapter = offered.insert(previous).inserted
        }
        activeChapter = key
        var progress = chapters[key] ?? Progress()
        progress.seen.insert(verse); progress.count = verseCount; progress.last = lastVerse
        chapters[key] = progress
        order.removeAll { $0 == key }; order.append(key)
        // Preserve recent reading across jumps/scroll callbacks without retaining every visited verse forever.
        if order.count > 32 { chapters.removeValue(forKey: order.removeFirst()) }
        return crossedCompletedChapter
    }
}
