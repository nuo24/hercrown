import Foundation

/// Study tools (docs/study-tools.md). Explain easier and Deeper study are AI summaries of cited public-domain sources;
/// Original language and Related verses are data, not AI.
enum StudyTool: String, CaseIterable, Identifiable, Hashable {
    case explain, deeper, original, related
    var id: String { rawValue }
    var title: String { switch self { case .explain: "Explain easier"; case .deeper: "Deeper study"; case .original: "Original language"; case .related: "Related verses" } }
    var symbol: String { switch self { case .explain: "lightbulb"; case .deeper: "book"; case .original: "character.book.closed"; case .related: "link" } }
    var isAI: Bool { self == .explain || self == .deeper }
}

struct StudyAnswer: Decodable, Equatable {
    struct Section: Decodable, Equatable, Identifiable { let title: String; let text: String; var id: String { title } }
    struct Source: Decodable, Equatable, Identifiable { let tag: String; let name: String; let author: String; let published: String; let license: String; var id: String { tag } }
    let ref: String
    let label: String
    let tool: String
    let sections: [Section]
    let sources: [Source]
    let notice: String
    let cached: Bool
}

struct OriginalWords: Decodable {
    struct Word: Decodable, Identifiable, Hashable {
        let text: String
        let transliteration: String
        let gloss: String
        let strong: String
        let parsing: String?
        let lemma: String?
        let lemmaTransliteration: String?
        let meaning: String?
        let definition: String?
        let editions: String?
        var id: String { strong + text + transliteration }
    }
    struct Source: Decodable { let name: String; let license: String }
    let label: String
    let language: String
    let words: [Word]
    let source: Source
}

struct RelatedVerses: Decodable {
    struct Item: Decodable, Identifiable { let ref: String; let label: String; let text: String; let votes: Int; var id: String { ref } }
    struct Source: Decodable { let name: String; let license: String }
    let related: [Item]
    let source: Source
}

/// Loading a study: streaming AI text arrives as `partial`, then the checked answer.
enum StudyState<Value> {
    case loading
    case partial(String)
    case loaded(Value)
    case needsPlus
    case failed(String)
}

@MainActor
enum StudyService {
    static func path(_ ref: VerseRef, _ tool: StudyTool, translation: String? = nil) -> String {
        "/study/\(ref.description)/\(tool.rawValue)" + (translation.map { "?translation=\($0)" } ?? "")
    }

    /// Explain / Deeper: stored answers come back at once; new ones stream (`delta`, `reset`, `done`, `error`).
    static func stream(_ ref: VerseRef, _ tool: StudyTool, update: @escaping (StudyState<StudyAnswer>) -> Void) async {
        var text = ""
        do {
            for try await (event, data) in APIClient.shared.events(path(ref, tool)) {
                switch event {
                case "delta":
                    if let d = try? JSONDecoder().decode([String: String].self, from: data)["text"] { text += d; update(.partial(text)) }
                case "reset":
                    text = ""; update(.loading)
                case "done":
                    update((try? JSONDecoder().decode(StudyAnswer.self, from: data)).map { .loaded($0) } ?? .failed("We couldn't read this study. Please try again."))
                    return
                case "error":
                    let e = (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
                    update(.failed(e["message"] ?? "Study tools are busy right now. Try again in a moment."))
                    return
                default: break
                }
            }
        } catch let error as APIError {
            update(error.isPremiumRequired ? .needsPlus : .failed(error.message))
        } catch {
            update(.failed(APIError.offline.message))
        }
    }

    static func load<T: Decodable>(_ ref: VerseRef, _ tool: StudyTool, translation: String) async -> StudyState<T> {
        do { return .loaded(try await APIClient.shared.get(path(ref, tool, translation: translation))) }
        catch let error as APIError { return error.isPremiumRequired ? .needsPlus : .failed(error.message) }
        catch { return .failed(APIError.offline.message) }
    }
}
