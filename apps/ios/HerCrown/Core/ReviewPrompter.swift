import Foundation
import Observation

/// Usage-based eligibility only. Ratings and private feedback never depend on a user's sentiment or membership.
struct ReviewHistory: Codable {
    var firstUse: Date
    var readingDays: Set<String> = []
    var lastReview: Date?
    var reviewVersion: String?
    var lastFeedback: Date?

    func canRequestReview(now: Date, version: String) -> Bool {
        readingDays.count >= 3 && now.timeIntervalSince(firstUse) >= 7 * 86_400
            && reviewVersion != version
            && (lastReview.map { now.timeIntervalSince($0) >= 120 * 86_400 } ?? true)
    }

    func canRequestFeedback(now: Date) -> Bool {
        readingDays.count >= 5 && now.timeIntervalSince(firstUse) >= 14 * 86_400
            && (lastReview.map { now.timeIntervalSince($0) >= 7 * 86_400 } ?? true)
            && (lastFeedback.map { now.timeIntervalSince($0) >= 90 * 86_400 } ?? true)
    }
}

@MainActor @Observable
final class ReviewPrompter {
    static let shared = ReviewPrompter()
    private let defaults: UserDefaults
    private let key = "hc.reviewHistory"
    private(set) var history: ReviewHistory
    private(set) var revision = 0

    init(defaults: UserDefaults = .standard, now: Date = .now) {
        self.defaults = defaults
        history = defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(ReviewHistory.self, from: $0) }
            ?? ReviewHistory(firstUse: now)
        save()
    }

    func recordReadingDay(_ day: String) {
        guard history.readingDays.insert(day).inserted else { return }
        save(); revision += 1
    }

    func requestedReview(now: Date = .now, version: String) {
        history.lastReview = now; history.reviewVersion = version; save()
    }

    func requestedFeedback(now: Date = .now) { history.lastFeedback = now; save() }

    private func save() { if let data = try? JSONEncoder().encode(history) { defaults.set(data, forKey: key) } }
}
