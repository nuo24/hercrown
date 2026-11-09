import SwiftUI

/// A small reviewed passage collection, ranked on device. Free text never becomes Scripture.
enum OnboardingScripture {
    struct Passage {
        let ref: String
        let words: [String]
        let topics: [String]
    }
    static let passages = [
        Passage(ref: "JHN.14.27", words: ["peace", "anxiety", "anxious", "worry", "worried", "afraid", "fear", "panic", "stress"], topics: ["Peace", "Anxiety"]),
        Passage(ref: "MAT.11.28", words: ["tired", "weary", "exhausted", "burnout", "overwhelmed", "burden", "rest"], topics: []),
        Passage(ref: "PSA.34.18", words: ["grief", "grieving", "loss", "died", "death", "heartbroken", "lonely", "breakup", "divorce", "crisis"], topics: []),
        Passage(ref: "PSA.147.3", words: ["pain", "sick", "illness", "healing", "hurt", "hospital", "health"], topics: []),
        Passage(ref: "ROM.15.13", words: ["hope", "joy", "happy", "happiness", "future"], topics: ["Hope"]),
        Passage(ref: "PRO.3.5-6", words: ["decision", "direction", "purpose", "wisdom", "confused", "work", "career"], topics: ["Purpose", "Wisdom", "Faith"]),
        Passage(ref: "PSA.139.14", words: ["worth", "identity", "confidence", "enough", "insecure"], topics: ["Identity"]),
        Passage(ref: "COL.3.14", words: ["family", "marriage", "relationship", "husband", "wife", "mom", "mother", "friend"], topics: ["Relationships"]),
        Passage(ref: "PSA.107.1", words: ["thankful", "gratitude", "grateful", "thank"], topics: ["Gratitude"]),
    ]
    static func reference(answers: PersonalOnboardingAnswers, prayer: String) -> VerseRef {
        func tokens(_ value: String) -> Set<String> {
            Set(value.lowercased().components(separatedBy: CharacterSet.letters.inverted).filter { !$0.isEmpty })
        }
        let burden = tokens(answers.burden)
        let loved = tokens(answers.lovedOnes)
        let prayerWords = tokens(prayer)
        var bestReference = "PSA.23.1"
        var bestScore = 0
        for item in passages {
            let words = Set(item.words)
            let burdenScore = burden.intersection(words).count * 12
            let lovedScore = loved.intersection(words).count * 4
            let topicScore = Set(answers.heart).intersection(Set(item.topics)).count * 6
            let prayerScore = prayerWords.intersection(words).count
            let score = burdenScore + lovedScore + topicScore + prayerScore
            if score > bestScore { bestScore = score; bestReference = item.ref }
        }
        return VerseRef(bestReference)!

    }
}

struct OnboardingScriptureCard: View {
    let answers: PersonalOnboardingAnswers
    let prayer: String
    private var ref: VerseRef { OnboardingScripture.reference(answers: answers, prayer: prayer) }
    var body: some View {
        VStack(spacing: 13) {
            Image.illustration("olive").resizable().scaledToFit().frame(width: 36, height: 42).accessibilityHidden(true)
            Text("Chosen for what’s on your heart").font(.ui(10)).tracking(0.6).foregroundStyle(Color(hex: 0x716550))
            Text(BibleStore.shared.text("kjv", ref) ?? "")
                .font(.serif(20)).lineSpacing(4).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            Text("\(BibleStore.shared.label(ref)) · KJV").font(.ui(10)).foregroundStyle(Color(hex: 0x716550))
        }
        .foregroundStyle(Color(hex: 0x302A23)).padding(.horizontal, 28).padding(.vertical, 25)
        .frame(maxWidth: .infinity)
        .background(LinearGradient(colors: [Color(hex: 0xFEFDF9), Color(hex: 0xF8F5EE), Color(hex: 0xFEFDF9)], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 10))
        .overlay(alignment: .top) { scrollEdge }
        .overlay(alignment: .bottom) { scrollEdge }
        .padding(.horizontal, 3).padding(.top, 14)
        .accessibilityElement(children: .combine)
    }
    private var scrollEdge: some View {
        Capsule().fill(LinearGradient(colors: [Color(hex: 0xEFE9DD), Color(hex: 0xFFFEFC), Color(hex: 0xE9E1D2)], startPoint: .top, endPoint: .bottom))
            .frame(height: 8).padding(.horizontal, -5).shadow(color: Color(hex: 0x9B8056).opacity(0.06), radius: 3, y: 2)
    }
}
