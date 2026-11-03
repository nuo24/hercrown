import SwiftUI

struct Passage: Identifiable, Codable, Hashable {
    let id: String
    let ref: String
    let topic: String
    let text: String
    let reflection: String
}

@MainActor
final class ScriptureLibrary: ObservableObject {
    @Published var passages: [Passage] = []
    @Published private(set) var saved: Set<String> = []
    @Published var selectedPlan = UserDefaults.standard.string(forKey: "selectedPlan") ?? ""
    @Published var loadError: String?
    init() {
        saved = Set(UserDefaults.standard.stringArray(forKey: "savedPassages") ?? [])
        do {
            guard let url = Bundle.main.url(forResource: "passages", withExtension: "json") else {
                throw CocoaError(.fileNoSuchFile)
            }
            passages = try JSONDecoder().decode([Passage].self, from: Data(contentsOf: url))
        } catch { loadError = "The sample Scripture library could not be loaded." }
    }
    func toggle(_ passage: Passage) {
        if saved.contains(passage.id) { saved.remove(passage.id) } else { saved.insert(passage.id) }
        UserDefaults.standard.set(Array(saved), forKey: "savedPassages")
    }
    func choosePlan(_ title: String) {
        selectedPlan = title
        UserDefaults.standard.set(title, forKey: "selectedPlan")
    }
}

enum BibleStyle {
    static let gutter: CGFloat = 20
    static let radius: CGFloat = 16
    static func editorial(_ size: CGFloat, italic: Bool = false, relativeTo style: Font.TextStyle = .title) -> Font {
        .custom(italic ? "Georgia-Italic" : "Georgia", size: size, relativeTo: style)
    }
}

struct Panel<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: BibleStyle.radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: BibleStyle.radius, style: .continuous).stroke(Color(uiColor: .separator).opacity(0.3), lineWidth: 0.5))
            .shadow(color: .black.opacity(scheme == .dark ? 0.22 : 0.03), radius: 1.5, x: 0, y: 1)
            .shadow(color: .black.opacity(scheme == .dark ? 0.28 : 0.04), radius: 4, x: 0, y: 4)
            .shadow(color: .black.opacity(scheme == .dark ? 0.3 : 0.05), radius: 12, x: 0, y: 10)
    }
}

struct PillButton: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.body).foregroundStyle(scheme == .dark ? .black : .white)
            .padding(.horizontal, 20).frame(minHeight: 48)
            .background {
                Capsule().fill(scheme == .dark ? Color.white : Color.black)
                    .shadow(color: .black.opacity(0.08), radius: 1, x: 0, y: 1)
                    .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
                    .animation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
            }
    }
}
