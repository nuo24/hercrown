import Foundation
import Observation

/// Only server-recorded activity qualifies. Opening the medal screen never records reading.
struct MedalProgress: Codable, Equatable {
    struct Days: Codable, Equatable { var total: Int }
    struct Bible: Codable, Equatable {
        struct Book: Codable, Equatable { let id: String; let chapters: Int; let chaptersRead: Int }
        var chaptersRead: Int
        var books: [Book]
        var completedChapterRefs: [String]? = nil
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
    var completedBooks: Int? = nil
    var book: String? = nil
    var journey: String? = nil
    var requiredChapterRefs: [String] = []
    var id: String { "\(collection.rawValue)-\(index)" }
    var rarity: String { days >= 180 ? "Legendary" : days >= 90 ? "Exceptional" : days >= 30 ? "Rare" : "Uncommon" }
    var targetCount: Int { completedBooks ?? chapters }
    var reference: String {
        collection == .armor ? "Ephesians 6:\([14, 14, 15, 16, 17, 17][index])" : collection.reference
    }
    var requirement: String {
        if let completedBooks {
            return "Read on \(days) different days and finish \(completedBooks) complete Bible \(completedBooks == 1 ? "book" : "books")."
        }
        if let journey {
            return "Read on \(days) different days and complete all \(chapters) chapters in the \(journey) reading journey."
        }
        if let book {
            let name = BibleStore.shared.books.first { $0.id == book }?.name ?? book
            return "Read on \(days) different days and complete \(chapters) chapters in \(name)."
        }
        return "Read on \(days) different days and complete \(chapters) different Bible chapters."
    }
    func counts(_ progress: MedalProgress) -> (days: Int, units: Int) {
        let completed: Int
        if completedBooks != nil {
            let canon = Dictionary(uniqueKeysWithValues: BibleStore.shared.books.map { ($0.id, $0.chapterCount) })
            completed = Set(progress.bible.books.compactMap { book -> String? in
                guard let total = canon[book.id], total > 0, book.chapters == total,
                      book.chaptersRead >= total else { return nil }
                return book.id
            }).count
        } else if journey != nil {
            // Older API responses/caches have no chapter identities; never infer themed completion from totals.
            completed = Set(requiredChapterRefs).intersection(Set(progress.bible.completedChapterRefs ?? [])).count
        } else {
            completed = book.map { id in progress.bible.books.first { $0.id == id }?.chaptersRead ?? 0 } ?? progress.bible.chaptersRead
        }
        return (min(days, max(0, progress.daysRead.total)), min(targetCount, max(0, completed)))
    }
    func progressLabel(_ progress: MedalProgress) -> String {
        let n = counts(progress)
        let unit = completedBooks != nil ? "books" : journey == nil ? "chapters" : "journey chapters"
        return "\(n.days) of \(days) reading days · \(n.units) of \(targetCount) \(unit)"
    }
    func fraction(_ progress: MedalProgress) -> Double {
        let n = counts(progress)
        return min(Double(n.days) / Double(days), Double(n.units) / Double(targetCount))
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
        func journey(_ group: Collection, _ index: Int, _ name: String, _ days: Int, _ title: String, _ refs: String) {
            let chapters = refs.split(separator: " ").map(String.init)
            result.append(.init(collection: group, index: index, name: name, days: days,
                chapters: chapters.count, journey: title, requiredChapterRefs: chapters))
        }
        let armorNames = ["Belt of Truth", "Breastplate of Righteousness", "Shoes of Peace", "Shield of Faith", "Helmet of Salvation", "Sword of the Spirit"]
        let armorDays = [21, 30, 45, 60, 90, 180]
        let armorBooks = [1, 3, 5, 10, 20, 40]
        for index in armorNames.indices {
            result.append(.init(collection: .armor, index: index, name: armorNames[index], days: armorDays[index],
                chapters: 0, completedBooks: armorBooks[index]))
        }
        add(.psalms, ["Harp", "Lyre", "Shepherd’s Staff"], [30,90,180], [30,75,150], book: "PSA")
        add(.women, ["Ruth’s Wheat"], [30], [4], book: "RUT")
        result.append(.init(collection: .women, index: 1, name: "Esther’s Scepter", days: 60, chapters: 10, book: "EST"))
        result.append(.init(collection: .women, index: 2, name: "Alabaster Jar", days: 90, chapters: 24, book: "LUK"))
        journey(.promises, 0, "Rainbow", 60, "God’s Faithfulness", "GEN.6 GEN.7 GEN.8 GEN.9 GEN.12 GEN.15 GEN.17 ISA.40 ISA.41 ISA.43 LAM.3 ROM.8 2CO.1 HEB.6")
        journey(.promises, 1, "Anchor of Hope", 120, "Hope", "HEB.6 HEB.10 HEB.11 HEB.12 ROM.5 ROM.8 ROM.15 PSA.42 PSA.62 PSA.121 PSA.130 ISA.25 ISA.40 JHN.14 1PE.1 REV.21")
        journey(.promises, 2, "Olive Branch", 365, "Peace and Trust", "PSA.4 PSA.23 PSA.29 PSA.46 PSA.85 PSA.131 ISA.26 ISA.32 ISA.54 MAT.5 MAT.6 MAT.11 JHN.14 JHN.16 ROM.12 ROM.14 PHP.4 COL.3 2TH.3")
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
    private struct Cache: Codable { let progress: MedalProgress; let dates: [String: Date]; var rulesVersion: Int? = nil }
    static func retainedDates(_ dates: [String: Date], rulesVersion: Int?) -> [String: Date] {
        switch rulesVersion {
        case 3: dates
        case 2: dates.filter { !$0.key.hasPrefix("armor-") }
        default: dates.filter { !$0.key.hasPrefix("armor-") && !$0.key.hasPrefix("promises-") }
        }
    }
    var homeMedal: FaithMedal {
        let fruits = FaithMedal.items(.fruit)
        return fruits.first { !$0.earned(progress ?? .empty) } ?? fruits.last!
    }
    func load(app: AppModel) async {
        let user = app.me?.user.id
        if account != user {
            account = user; progress = nil; earnedDates = [:]; unavailable = false
            if let user, let data = defaults.data(forKey: "hc.medals.\(user)"), let cache = try? JSONDecoder().decode(Cache.self, from: data) {
                progress = cache.progress; earnedDates = Self.retainedDates(cache.dates, rulesVersion: cache.rulesVersion)
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
            defaults.set(try? JSONEncoder().encode(Cache(progress: fresh, dates: earnedDates, rulesVersion: 3)), forKey: "hc.medals.\(user)")
        } catch {
            guard app.me?.user.id == user, account == user else { return }
            unavailable = true
        }
    }
}
