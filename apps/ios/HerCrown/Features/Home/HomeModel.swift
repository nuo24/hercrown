import Foundation
import Observation

// Home's server data (docs/api.md): today's verse and devotional for her local day, her streak and progress, plans.

struct DayVerse: Decodable, Equatable {
    let date: String
    let ref: String
    let label: String
    let text: String?
    let translation: String
    let theme: String?
    let reflection: String?
    let saved: Bool
}

struct Devotional: Decodable, Equatable, Identifiable {
    let id: String
    let title: String
    let ref: String
    let label: String
    let passage: String?
    let translation: String
    let tag: String?
    let minutes: Int?
    let body: String
    let reflection: String?
    let origin: String?
    let sources: [String]
    let readAt: Double?
}

struct Streak: Decodable, Equatable {
    struct Day: Decodable, Equatable { let day: String; let read: Bool }
    let current: Int
    let best: Int
    let readToday: Bool
    let week: [Day]
    let milestone: Int?

    static let empty = Streak(current: 0, best: 0, readToday: false, week: [], milestone: nil)
}

struct ReadingProgress: Decodable, Equatable {
    struct Bible: Decodable, Equatable { let chaptersRead: Int; let totalChapters: Int; let percent: Double }
    struct Days: Decodable, Equatable { let total: Int; let current: Int; let best: Int }
    let bible: Bible
    let daysOpened: Days
    let daysRead: Days
    let daysThisYear: Int
    let weeksInARow: Int
    let devotionalsRead: Int
    let versesStudied: Int
}

struct ReadingPlan: Decodable, Equatable, Identifiable {
    struct Step: Decodable, Equatable, Identifiable { let position: Int; let ref: String; let completedAt: Double?; var id: Int { position } }
    struct Progress: Decodable, Equatable { let startedAt: Double; let nextPosition: Int?; let completedSteps: Int; let completedAt: Double? }
    let id: String
    let title: String
    let description: String
    let topic: String?
    let tone: String?
    let days: Int
    let steps: [Step]
    let progress: Progress?
}

struct PlanList: Decodable, Equatable {
    let plans: [ReadingPlan]
    let activePlanId: String?
    let locked: Bool
}

@MainActor
@Observable
final class HomeModel {
    var verse: DayVerse?
    var devotional: Devotional?
    var streak: Streak = HomeModel.cached("hc.streak") ?? .empty
    var progress: ReadingProgress?
    var plans: PlanList?
    var loaded = false

    private let api = APIClient.shared

    /// The plan Today's Reading shows: the one she's in, else the first.
    var todaysPlan: ReadingPlan? {
        guard let plans else { return nil }
        return plans.plans.first { $0.id == plans.activePlanId } ?? plans.plans.first
    }

    func load(translation: String) async {
        let day = AppModel.localDay()
        async let v: DayVerse? = try? api.get("/scripture/verse-of-the-day?date=\(day)&translation=\(translation)")
        async let d: Devotional? = try? api.get("/devotionals/today?date=\(day)&translation=\(translation)") // 404 = none approved: no card
        async let p: PlanList? = try? api.get("/plans")
        let (verse, devotional, plans) = await (v, d, p)
        if let verse { self.verse = verse }
        if let devotional { self.devotional = devotional }
        if let plans { self.plans = plans }
        await loadStreak()
        loaded = true
    }

    func loadStreak() async {
        struct Wrapped: Decodable { let streak: Streak }
        if let s: Wrapped = try? await api.get("/me/streak?today=\(AppModel.localDay())") {
            streak = s.streak
            UserDefaults.standard.set(try? JSONEncoder().encode(s.streak), forKey: "hc.streak")
        }
    }

    func loadProgress() async {
        progress = try? await api.get("/me/progress?today=\(AppModel.localDay())")
    }

    /// "Mark today as read": one reading event for her local day (counted once however often she taps).
    func markTodayRead(ref: String) async {
        let day = AppModel.localDay()
        streak = Streak(current: streak.readToday ? streak.current : streak.current + 1, best: max(streak.best, streak.current + (streak.readToday ? 0 : 1)),
                        readToday: true, week: streak.week.map { $0.day == day ? .init(day: day, read: true) : $0 }, milestone: streak.milestone)
        _ = try? await api.send("POST", "/me/reading-events", json: ["events": [[
            "id": "home-\(day)", "localDay": day, "timeZone": TimeZone.current.identifier, "ref": ref,
        ]]])
        await Analytics.shared.track("day_marked_read", ["source": .string("home")])
        await loadStreak()
    }

    func markDevotionalRead(_ id: String) async {
        _ = try? await api.send("POST", "/me/devotionals/\(id)/read", json: ["localDay": AppModel.localDay()])
    }

    func startPlan(_ id: String) async -> ReadingPlan? {
        let plan: ReadingPlan? = try? await api.call("POST", "/plans/\(id)/start")
        plans = try? await api.get("/plans")
        return plan
    }

    func completeStep(_ planId: String, _ position: Int) async {
        _ = try? await api.send("POST", "/plans/\(planId)/steps/\(position)/complete", json: ["localDay": AppModel.localDay()])
        plans = try? await api.get("/plans")
    }

    private static func cached<T: Decodable>(_ key: String) -> T? {
        UserDefaults.standard.data(forKey: key).flatMap { try? JSONDecoder().decode(T.self, from: $0) }
    }
}

extension Streak: Encodable {}
extension Streak.Day: Encodable {}
