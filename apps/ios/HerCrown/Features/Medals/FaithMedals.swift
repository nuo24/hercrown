import Foundation
import Observation

/// Only server-recorded activity qualifies. Opening the medal screen never records reading.
struct MedalProgress: Codable, Equatable {
    struct Days: Codable, Equatable { var total: Int }
    struct Bible: Codable, Equatable {
        struct Book: Codable, Equatable { let id: String; let chapters: Int; let chaptersRead: Int }
        var chaptersRead: Int
        var books: [Book]
    }
    var daysRead: Days
    var bible: Bible
    static let empty = Self(daysRead: .init(total: 0), bible: .init(chaptersRead: 0, books: []))
}

struct FaithMedal: Identifiable {
    enum Collection: String, CaseIterable, Identifiable {
        case fruit, armor, psalms, women, promises
        var id: String { rawValue }
        var title: String {
            switch self {
            case .fruit: "Fruit of the Spirit"
            case .armor: "Armor of God"
            case .psalms: "The Psalms"
            case .women: "Women of the Bible"
            case .promises: "Promises of God"
            }
        }
        var reference: String {
            switch self {
            case .fruit: "Galatians 5:22–23"
            case .armor: "Ephesians 6:10–18"
            case .psalms: "The Book of Psalms"
            case .women: "Stories of faith"
            case .promises: "Hope, peace, and trust"
            }
        }
    }
    let collection: Collection
    let index: Int
    let name: String
    let days: Int
    let chapters: Int
    var book: String? = nil
    var id: String { "\(collection.rawValue)-\(index)" }
    var rarity: String { days >= 180 ? "Legendary" : days >= 90 ? "Exceptional" : days >= 30 ? "Rare" : "Uncommon" }
    var requirement: String {
        if let book {
            let name = BibleStore.shared.books.first { $0.id == book }?.name ?? book
            return "Read on \(days) different days and complete \(chapters) chapters in \(name)."
        }
        return "Read on \(days) different days and complete \(chapters) different Bible chapters."
    }
    func counts(_ progress: MedalProgress) -> (days: Int, chapters: Int) {
        (min(days, max(0, progress.daysRead.total)), min(chapters, max(0, book.map { id in progress.bible.books.first { $0.id == id }?.chaptersRead ?? 0 } ?? progress.bible.chaptersRead)))
    }
    func fraction(_ progress: MedalProgress) -> Double {
        let n = counts(progress)
        return min(Double(n.days) / Double(days), Double(n.chapters) / Double(chapters))
    }
    func earned(_ progress: MedalProgress) -> Bool { fraction(progress) >= 1 }
    var artwork: String {
        if index == 0 {
            switch collection {
            case .armor: return "reward-belt-v2"
            case .women: return "reward-ruth-wheat"
            case .promises: return "reward-rainbow-v2"
            default: break
            }
        }
        return collection == .fruit ? "reward-fruit-concept" : collection == .armor ? "reward-armor-concept" : "reward-collections-concept"
    }
    var spriteCell: (column: Int, row: Int, rows: Int)? {
        if index == 0 && [.armor, .women, .promises].contains(collection) { return nil }
        if collection == .fruit || collection == .armor { return (index % 3, index / 3, collection == .armor ? 2 : 3) }
        return (index, collection == .psalms ? 0 : collection == .women ? 1 : 2, 3)
    }
    static let all: [FaithMedal] = {
        var result: [FaithMedal] = []
        func add(_ group: Collection, _ names: [String], _ days: [Int], _ chapters: [Int], book: String? = nil) {
            for i in names.indices { result.append(FaithMedal(collection: group, index: i, name: names[i], days: days[i], chapters: chapters[i], book: book)) }
        }
        add(.fruit, ["Love", "Joy", "Peace", "Patience", "Kindness", "Goodness", "Faithfulness", "Gentleness", "Self-control"], [14,21,30,45,60,90,120,180,365], [14,21,30,45,60,90,120,180,365])
        add(.armor, ["Belt of Truth", "Breastplate of Righteousness", "Shoes of Peace", "Shield of Faith", "Helmet of Salvation", "Sword of the Spirit"], [21,30,45,60,90,180], [21,30,45,60,90,180])
        add(.psalms, ["Harp", "Lyre", "Shepherd’s Staff"], [30,90,180], [30,75,150], book: "PSA")
        add(.women, ["Ruth’s Wheat"], [30], [4], book: "RUT")
        result.append(.init(collection: .women, index: 1, name: "Esther’s Scepter", days: 60, chapters: 10, book: "EST"))
        result.append(.init(collection: .women, index: 2, name: "Alabaster Jar", days: 90, chapters: 24, book: "LUK"))
        add(.promises, ["Rainbow", "Anchor of Hope", "Olive Branch"], [60,120,365], [50,120,365])
        return result
    }()
    static func items(_ group: Collection) -> [Self] { all.filter { $0.collection == group } }
}

@MainActor @Observable
final class FaithMedalsModel {
    private(set) var progress: MedalProgress?
    private(set) var account: String?
    private(set) var unavailable = false
    private(set) var earnedDates: [String: Date] = [:]
    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    private struct Cache: Codable { let progress: MedalProgress; let dates: [String: Date] }
    var homeMedal: FaithMedal {
        let fruits = FaithMedal.items(.fruit)
        return fruits.first { !$0.earned(progress ?? .empty) } ?? fruits.last!
    }
    func load(app: AppModel) async {
        let user = app.me?.user.id
        if account != user {
            account = user; progress = nil; earnedDates = [:]; unavailable = false
            if let user, let data = defaults.data(forKey: "hc.medals.\(user)"), let cache = try? JSONDecoder().decode(Cache.self, from: data) {
                progress = cache.progress; earnedDates = cache.dates
            }
        }
        guard let user else { unavailable = true; return }
        do {
            let fresh: MedalProgress = try await app.api.get("/me/progress?today=\(AppModel.localDay())")
            guard !Task.isCancelled, app.me?.user.id == user, account == user else { return }
            progress = fresh; unavailable = false
            for medal in FaithMedal.all where medal.earned(fresh) && earnedDates[medal.id] == nil {
                earnedDates[medal.id] = .now // First verified detection, not an invented historical award date.
                await Analytics.shared.track("faith_medal_earned", ["medal": .string(medal.id)])
            }
            defaults.set(try? JSONEncoder().encode(Cache(progress: fresh, dates: earnedDates)), forKey: "hc.medals.\(user)")
        } catch {
            guard app.me?.user.id == user, account == user else { return }
            unavailable = true
        }
    }
}
