import SwiftUI
import WidgetKit

/// The home-screen widget: her chosen "Widget verse", else today's verse. The app writes it to the shared App Group
/// (WidgetBridge) whenever it changes; the widget never invents or stores Scripture of its own.
struct WidgetVerse: Codable {
    let ref: String
    let label: String
    let text: String
    let translation: String
    let chosen: Bool

    static let appGroup = "group.com.hercrown.app"
    static func load() -> WidgetVerse? {
        UserDefaults(suiteName: appGroup)?.data(forKey: "widgetVerse").flatMap { try? JSONDecoder().decode(WidgetVerse.self, from: $0) }
    }
}

struct VerseEntry: TimelineEntry {
    let date: Date
    let verse: WidgetVerse?
    var artwork: Data? = nil

    static func load(family: WidgetFamily) -> VerseEntry {
        let suite = UserDefaults(suiteName: WidgetVerse.appGroup)
        var artwork: Data?
        if let data = suite?.data(forKey: "widgetDesignManifest"),
           let manifest = try? JSONDecoder().decode(WidgetArtwork.self, from: data), UUID(uuidString: manifest.folder) != nil,
           let group = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WidgetVerse.appGroup) {
            let size = family == .systemSmall ? "small" : family == .systemMedium ? "medium" : "large"
            artwork = try? Data(contentsOf: group.appendingPathComponent(manifest.folder).appendingPathComponent(size + ".png"))
        }
        return VerseEntry(date: .now, verse: WidgetVerse.load(), artwork: artwork)
    }
}
private struct WidgetArtwork: Decodable { let folder: String }


struct VerseProvider: TimelineProvider {
    func placeholder(in context: Context) -> VerseEntry { VerseEntry(date: .now, verse: nil) }
    func getSnapshot(in context: Context, completion: @escaping (VerseEntry) -> Void) { completion(VerseEntry.load(family: context.family)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<VerseEntry>) -> Void) {
        // Today's verse changes at midnight; the app also reloads the widget when she opens it or picks a verse.
        let midnight = Calendar.current.nextDate(after: .now, matching: DateComponents(hour: 0, minute: 5), matchingPolicy: .nextTime) ?? .now.addingTimeInterval(86_400)
        completion(Timeline(entries: [VerseEntry.load(family: context.family)], policy: .after(midnight)))
    }
}

struct VerseWidgetView: View {
    let entry: VerseEntry
    var quietLayout = false
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if let data = entry.artwork, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().interpolation(.high).scaledToFill()
                    .accessibilityLabel(entry.verse.map { "\($0.text) \($0.label)" } ?? "Your verse widget")
                    .containerBackground(for: .widget) { Color.clear }
            } else { defaultVerse }
        }
    }

    private var defaultVerse: some View {
        VStack(alignment: .leading, spacing: 6) {
            if family == .systemLarge {
                Label(entry.verse?.chosen == true ? "Your chosen verse" : "Verse of the day", systemImage: "book")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
                Spacer(minLength: 0)
            }
            if let verse = entry.verse {
                Text(verse.text)
                    .font(.custom("Baskerville", size: family == .systemLarge ? (quietLayout ? 24 : 32) : family == .systemSmall ? 15 : 18))
                    .lineLimit(family == .systemSmall ? 6 : family == .systemMedium ? 5 : 12)
                    .minimumScaleFactor(0.7)
                if family == .systemLarge {
                    Divider().padding(.vertical, 6)
                } else {
                    Spacer(minLength: 0)
                }
                Text("\(verse.label) · \(verse.translation.uppercased())").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                if family == .systemLarge { Spacer(minLength: 0) }
            } else {
                Text("Her Crown").font(.custom("Baskerville", size: 18))
                Spacer(minLength: 0)
                Text("Open the app to bring today’s verse here.").font(.system(size: 12)).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .foregroundStyle(Color(red: 0.07, green: 0.07, blue: 0.07))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) {
            LinearGradient(colors: [Color(red: 0.894, green: 0.929, blue: 0.875), Color(red: 0.878, green: 0.929, blue: 0.961), Color(red: 0.918, green: 0.875, blue: 0.941)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct HerCrownWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "HerCrownVerse", provider: VerseProvider()) { VerseWidgetView(entry: $0) }
            .configurationDisplayName("Verse")
            .description("Your widget verse, or today’s verse.")
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
            .contentMarginsDisabled()
    }
}

struct QuietVerseWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "HerCrownQuietVerse", provider: VerseProvider()) {
            VerseWidgetView(entry: $0, quietLayout: true)
        }
        .configurationDisplayName("Quiet Verse")
        .description("A large verse widget with smaller type and more breathing room.")
        .supportedFamilies([.systemLarge])
            .contentMarginsDisabled()
    }
}

@main
struct HerCrownWidgets: WidgetBundle {
    var body: some Widget { HerCrownWidget(); QuietVerseWidget() }
}
