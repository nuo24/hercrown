import Foundation
import WidgetKit

/// Hands the widget its verse (GET /me/widget: her chosen verse, else today's) through the shared App Group.
enum WidgetBridge {
    private struct Payload: Codable { let ref: String; let label: String; let text: String; let translation: String; let chosen: Bool }

    static func refresh(translation: String) async {
        struct Response: Decodable { let source: String; let ref: String; let label: String; let text: String?; let translation: String }
        guard let r: Response = try? await APIClient.shared.get("/me/widget?date=\(AppModel.localDay())&translation=\(translation)"), let text = r.text,
              let data = try? JSONEncoder().encode(Payload(ref: r.ref, label: r.label, text: text, translation: r.translation, chosen: r.source == "chosen"))
        else { return }
        UserDefaults(suiteName: "group.com.hercrown.app")?.set(data, forKey: "widgetVerse")
        WidgetCenter.shared.reloadAllTimelines()
    }
}
