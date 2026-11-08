import AVFoundation
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
        return paragraphs.joined(separator: "\n\n")
    }
}

enum PersonalPrayerStore {
    static func key(_ userID: String?) -> String { "hc.personalPrayer.\(userID ?? "local")" }
    static func remove(_ userID: String?) { UserDefaults.standard.removeObject(forKey: key(userID)) }
    static func read(_ userID: String?) -> String? { UserDefaults.standard.string(forKey: key(userID)) }
    static func save(_ text: String, userID: String?) { UserDefaults.standard.set(text, forKey: key(userID)) }
}

/// Speech and feedback share one lifecycle. Haptics occur at slow phrase intervals, never for every character.
@MainActor final class PrayerReciter: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published private(set) var speaking = false
    private let speech = AVSpeechSynthesizer()
    private let feedback = UIImpactFeedbackGenerator(style: .soft)
    private var lastPulse = Date.distantPast

    override init() { super.init(); speech.delegate = self }
    func start(_ prayer: String, haptics: Bool) {
        guard !speaking else { return }
        speaking = true
        Task { await Analytics.shared.track("prayer_recited") }
        allowHaptics = haptics
        lastPulse = .distantPast
        let utterance = AVSpeechUtterance(string: prayer)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.42
        utterance.preUtteranceDelay = 0.15
        speech.speak(utterance)
    }
    private var allowHaptics = true
    func stop() { speech.stopSpeaking(at: .immediate); speaking = false }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString range: NSRange, utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            guard let self, speaking, allowHaptics, Date().timeIntervalSince(lastPulse) >= 1.6 else { return }
            feedback.impactOccurred(intensity: 0.35)
            lastPulse = Date()
        }
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in self?.speaking = false }
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in self?.speaking = false }
    }
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
                    Text(prayer).font(.serif(21)).lineSpacing(6).textSelection(.enabled)
                    ShareLink(item: prayer) { Label("Save or share your prayer", systemImage: "square.and.arrow.up") }.buttonStyle(CapsuleButtonStyle())
                } else { Text("Your saved onboarding prayer will appear here.").font(.ui(14)).foregroundStyle(Theme.muted(scheme)) }
                Text("Personal prayer · separate from Scripture").font(.ui(11)).foregroundStyle(Theme.muted(scheme))
            }.padding(24)
        }.background(Theme.canvas(scheme)).foregroundStyle(Theme.text(scheme)).navigationTitle("Your prayer").navigationBarTitleDisplayMode(.inline)
    }
}
