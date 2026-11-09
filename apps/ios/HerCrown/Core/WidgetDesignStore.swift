import SwiftUI
import WidgetKit

/// Widgets receive finished images through the existing App Group, never private photo-library access.
@MainActor enum WidgetDesignStore {
    static let appGroup = "group.com.hercrown.app"
    static let suite = UserDefaults(suiteName: appGroup)
    struct Manifest: Codable {
        let folder: String
        let reference: String
        let translation: String
    }
    enum StoreError: Error { case unavailable, rendering }
    static func activate(owner: String?) {
        let id = owner ?? "local"
        guard suite?.string(forKey: "widgetDesignOwner") != id else { return }
        suite?.set(id, forKey: "widgetDesignOwner")
        suite?.removeObject(forKey: "widgetVerse")
        clearArtwork()
        WidgetCenter.shared.reloadAllTimelines()
    }
    static func clearArtwork() {
        if let data = suite?.data(forKey: "widgetDesignManifest"), let manifest = try? JSONDecoder().decode(Manifest.self, from: data), UUID(uuidString: manifest.folder) != nil,
           let group = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) {
            try? FileManager.default.removeItem(at: group.appendingPathComponent(manifest.folder, isDirectory: true))
        }
        suite?.removeObject(forKey: "widgetDesignManifest")
    }
    static func refresh(passage: WidgetPassage, owner: String?) {
        let id = owner ?? "local"
        guard let data = UserDefaults.standard.data(forKey: "hc.widgetStudio.\(id)"), let design = try? JSONDecoder().decode(SnapshotDesign.self, from: data) else { return }
        let photoURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("widget-\(id).jpg")
        do { try publish(design: design, photo: UIImage(contentsOfFile: photoURL.path), text: passage.text, reference: passage.label, translation: passage.translation.uppercased(), owner: owner) }
        catch { clearArtwork() }
    }
    static func images(design: SnapshotDesign, photo: UIImage?, text: String, reference: String, translation: String) throws -> [String: Data] {
        var result: [String: Data] = [:]
        for size in ["Small", "Medium", "Large"] {
            var variant = design; variant.format = "Widget " + size
            if size == "Small" { variant.fontSize = max(40, variant.fontSize) }
            let renderer = ImageRenderer(content: SnapshotCanvas(text: text, reference: reference, translation: translation, design: variant, photo: photo, watermark: false).environment(\.colorScheme, .light))
            // 600 logical canvas points need enough pixels for large @3x widgets.
            renderer.scale = 2
            guard let data = renderer.uiImage?.pngData() else { throw StoreError.rendering }
            result[size.lowercased()] = data
        }
        return result
    }
    static func publish(design: SnapshotDesign, photo: UIImage?, text: String, reference: String, translation: String, owner: String?) throws {
        guard let group = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup), let suite else { throw StoreError.unavailable }
        let images = try images(design: design, photo: photo, text: text, reference: reference, translation: translation)
        let folder = UUID().uuidString
        let destination = group.appendingPathComponent(folder, isDirectory: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        do {
            for (size, data) in images { try data.write(to: destination.appendingPathComponent(size + ".png"), options: .atomic) }
            let manifest = try JSONEncoder().encode(Manifest(folder: folder, reference: reference, translation: translation))
            activate(owner: owner)
            clearArtwork()
            suite.set(manifest, forKey: "widgetDesignManifest")
            WidgetCenter.shared.reloadAllTimelines()
        } catch { try? FileManager.default.removeItem(at: destination); throw error }
    }
}
