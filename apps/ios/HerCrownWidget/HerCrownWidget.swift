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
}

struct VerseProvider: TimelineProvider {
    func placeholder(in context: Context) -> VerseEntry { VerseEntry(date: .now, verse: nil) }
    func getSnapshot(in context: Context, completion: @escaping (VerseEntry) -> Void) { completion(VerseEntry(date: .now, verse: WidgetVerse.load())) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<VerseEntry>) -> Void) {
        // Today's verse changes at midnight; the app also reloads the widget when she opens it or picks a verse.
        let midnight = Calendar.current.nextDate(after: .now, matching: DateComponents(hour: 0, minute: 5), matchingPolicy: .nextTime) ?? .now.addingTimeInterval(86_400)
        completion(Timeline(entries: [VerseEntry(date: .now, verse: WidgetVerse.load())], policy: .after(midnight)))
    }
}

struct VerseWidgetView: View {
    let entry: VerseEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let verse = entry.verse {
                Text(verse.text)
                    .font(.custom("Baskerville", size: family == .systemSmall ? 15 : 18))
                    .lineLimit(family == .systemSmall ? 6 : family == .systemMedium ? 5 : 12)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                Text("\(verse.label) · \(verse.translation.uppercased())").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
            } else {
                Text("Her Crown").font(.custom("Baskerville", size: 18))
                Spacer(minLength: 0)
                Text("Open the app to bring today’s verse here.").font(.system(size: 12)).foregroundStyle(.secondary)
            }
        }
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
    }
}

@main
struct HerCrownWidgets: WidgetBundle {
    var body: some Widget { HerCrownWidget() }
}
