import Foundation
import WidgetKit

struct WidgetPassage: Codable {
    let ref: String
    let label: String
    let text: String
    let translation: String
    let chosen: Bool
}

/// Hands the widget its chosen verse, else today's, and refreshes the saved visual design.
@MainActor enum WidgetBridge {
    static var current: WidgetPassage? {
        WidgetDesignStore.suite?.data(forKey: "widgetVerse").flatMap { try? JSONDecoder().decode(WidgetPassage.self, from: $0) }
    }
    static func refresh(translation: String, userID: String?) async {
        WidgetDesignStore.activate(owner: userID)
        let token = APIClient.shared.token
        struct Response: Decodable { let source: String; let ref: String; let label: String; let text: String?; let translation: String }
        guard let r: Response = try? await APIClient.shared.get("/me/widget?date=\(AppModel.localDay())&translation=\(translation)"), let text = r.text,
              APIClient.shared.token == token,
              WidgetDesignStore.suite?.string(forKey: "widgetDesignOwner") == (userID ?? "local") else { return }
        let passage = WidgetPassage(ref: r.ref, label: r.label, text: text, translation: r.translation, chosen: r.source == "chosen")
        guard let data = try? JSONEncoder().encode(passage) else { return }
        WidgetDesignStore.suite?.set(data, forKey: "widgetVerse")
        WidgetDesignStore.refresh(passage: passage, owner: userID)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
