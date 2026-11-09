import SwiftUI

struct PersonalOnboardingAnswers: Codable, Equatable {
    var name = ""
    var comparison = ""
    var season: [String] = []
    var familiarity = ""
    var heart: [String] = []
    var burden = ""
    var lovedOnes = ""
    var pace = ""

    var normalizedName: String {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.count <= 24, !clean.isEmpty,
              clean.unicodeScalars.allSatisfy({ CharacterSet.letters.union(.nonBaseCharacters).union(CharacterSet(charactersIn: " '-’")).contains($0) }) else { return "" }
        return clean.prefix(1).uppercased() + clean.dropFirst()
    }
    var prayerInput: [String: Any] {
        ["name": normalizedName, "season": season, "familiarity": familiarity, "heart": heart,
         "burden": burden, "lovedOnes": lovedOnes]
    }
    // Reviewed fallback uses only fixed choice mappings; arbitrary text is never interpolated.
    var simplePrayer: String {
        var paragraphs = ["Dear God,", "Thank You for meeting me where I am today. Help me make a little space for You in the middle of my real life."]
        let needs = ["Peace": "peace for my heart", "Purpose": "direction for my next step", "Faith": "trust when I have questions", "Relationships": "kindness in my relationships", "Identity": "confidence in my worth", "Anxiety": "steadiness in anxious moments", "Gratitude": "eyes for everyday goodness", "Hope": "hope for tomorrow", "Wisdom": "wisdom for my choices"]
        let gifts = heart.compactMap { needs[$0] }
        paragraphs.append(gifts.isEmpty ? "Give me rest for today and courage for tomorrow." : "Please give me \(gifts.joined(separator: ", ")).")
        paragraphs.append("Hold the people I love close. Help me notice the support around me, receive care when I need it, and offer love to others. Guide me gently, one small step at a time.")
        paragraphs.append("Amen.")
        return PrayerParagraphs.two(paragraphs.joined(separator: " "))
    }
}

/// Keep the original words intact while giving both generated and saved prayers two readable paragraphs.
enum PrayerParagraphs {
    static func two(_ prayer: String) -> String {
        let flat = prayer.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
        let boundaries = flat.indices.filter { flat[$0] == "." || flat[$0] == "!" || flat[$0] == "?" }
        let middle = flat.count / 2
        let split = boundaries.filter { flat.distance(from: flat.startIndex, to: $0) > flat.count / 4 && flat.distance(from: flat.startIndex, to: $0) < flat.count * 3 / 4 }
            .min { abs(flat.distance(from: flat.startIndex, to: $0) - middle) < abs(flat.distance(from: flat.startIndex, to: $1) - middle) }
        guard let split else { return flat }
        let after = flat.index(after: split)
        return String(flat[...split]) + "\n\n" + flat[after...].trimmingCharacters(in: .whitespaces)
    }
}

enum PersonalPrayerStore {
    static func key(_ userID: String?) -> String { "hc.personalPrayer.\(userID ?? "local")" }
    static func remove(_ userID: String?) { UserDefaults.standard.removeObject(forKey: key(userID)) }
    static func read(_ userID: String?) -> String? { UserDefaults.standard.string(forKey: key(userID)) }
    static func save(_ text: String, userID: String?) { UserDefaults.standard.set(text, forKey: key(userID)) }
}

struct SavedPersonalPrayerView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Image.illustration("faith-hands").resizable().scaledToFit().frame(height: 90).frame(maxWidth: .infinity)
                Text("A prayer for you.").font(.serif(30))
                if let prayer = PersonalPrayerStore.read(app.me?.user.id) {
                    Text(PrayerParagraphs.two(prayer)).font(.serif(21)).lineSpacing(6).textSelection(.enabled)
                    ShareLink(item: prayer) { Label("Save or share your prayer", systemImage: "square.and.arrow.up") }.buttonStyle(CapsuleButtonStyle())
                } else { Text("Your saved onboarding prayer will appear here.").font(.ui(14)).foregroundStyle(Theme.muted(scheme)) }
                Text("Personal prayer · separate from Scripture").font(.ui(11)).foregroundStyle(Theme.muted(scheme))
            }.padding(24)
        }.background(Theme.canvas(scheme)).foregroundStyle(Theme.text(scheme)).navigationTitle("Your prayer").navigationBarTitleDisplayMode(.inline)
    }
}

/// Reading pace is not prayer context. Moving through that question must not restart the request.
struct PrayerPreparation: Equatable {
    var answers: PersonalOnboardingAnswers
    let version: Int
    let simple: Bool
    init(answers: PersonalOnboardingAnswers, version: Int, simple: Bool) {
        self.answers = answers
        self.answers.pace = ""
        self.version = version
        self.simple = simple
    }
}

/// Milliseconds per character, with breathing room at punctuation and before the closing Amen.
enum PrayerReadingPace {
    static func delay(before index: Int, in characters: [Character]) -> Int {
        guard index > 0, index < characters.count else { return 55 }
        let remainder = String(characters[index...]).trimmingCharacters(in: .whitespacesAndNewlines)
        if characters[index] == "A", remainder == "Amen." || remainder == "Amen" { return 1055 }
        switch characters[index - 1] {
        case ".", "!", "?": return 405
        case ",", ";", ":": return 175
        case "\n": return 305
        default: return 55
        }
    }
}
