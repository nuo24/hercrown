import SwiftUI

struct DiscoverFeed: Decodable, Equatable {
    struct Filter: Decodable, Equatable, Identifiable { let id: String; let title: String }
    struct Card: Decodable, Equatable, Identifiable {
        let id: String
        let ref: String
        let label: String
        let theme: String?
        let text: String
        let reflection: String?
        let saved: Bool
    }
    let filter: String
    let filters: [Filter]
    let translation: String?
    let cards: [Card]
}

/// discover.feed (specs/SCREEN-MAP.md): illustrated introduction, topic filters (For you, her plan, nine themes) and
/// Scripture cards from our Bibles, each with a reflection question clearly marked as not Scripture.
struct DiscoverView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.colorScheme) private var scheme
    @State private var filter = "for-you"
    @State private var feed: DiscoverFeed?
    @State private var failed = false
    @State private var showingSaved = false
    @State private var showingSettings = false
    @State private var studyRef: VerseRef?

    private var translation: String { BibleStore.offline[app.preferences.translation] == nil ? "kjv" : app.preferences.translation }
    private static let themes = ["Peace", "Purpose", "Faith", "Relationships", "Identity", "Anxiety", "Gratitude", "Hope", "Wisdom"]

    /// Artwork per filter (spec mapping).
    private static let art = ["for-you": "lantern", "plan": "journal", "Peace": "olive", "Purpose": "purpose-compass", "Faith": "faith-hands",
                              "Relationships": "relationship-hands", "Identity": "intention-heart", "Anxiety": "rest-stones",
                              "Gratitude": "gratitude-basket", "Hope": "sunrise", "Wisdom": "wisdom-pearl"]

    private var filters: [DiscoverFeed.Filter] {
        feed?.filters ?? [.init(id: "for-you", title: "For you")] + Self.themes.map { .init(id: $0, title: $0) }
    }

    var body: some View {
        ZStack {
            AppGradient()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Text("Discover").font(.system(size: 32, weight: .semibold)).tracking(-0.8).foregroundStyle(Theme.text(scheme))
                        Spacer()
                        IconButton(systemName: "bookmark", label: "Saved passages") { showingSaved = true }
                        IconButton(systemName: "gearshape", label: "Settings") { showingSettings = true }
                    }
                    .padding(.top, 6)
                    hero
                    chips
                    cards
                }
                .padding(.horizontal, Theme.Spacing.gutter)
                .padding(.bottom, 120)
            }
            .refreshable { await load() }
        }
        .task(id: filter) { await load() }
        .onAppear { if let topic = app.discoverTopic { filter = topic; app.discoverTopic = nil } }
        .sheet(isPresented: $showingSaved) { SavedSheet(translation: translation) }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .sheet(item: $studyRef) { ref in
            InsightsSheet(ref: ref, translation: translation) { r in app.openInReader(r) }.presentationDetents([.large])
        }
    }

    private func load() async {
        let query = filter.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? filter
        do {
            feed = try await app.api.get("/discover?filter=\(query)&translation=\(translation)")
            failed = false
        } catch {
            failed = feed?.filter != filter
        }
        await Analytics.shared.track("discover_viewed", ["filter": .string(filter)])
    }

    // MARK: Hero

    private var hero: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                Text(heroTitle).font(.serif(30, relativeTo: .title)).fixedSize(horizontal: false, vertical: true)
                Text(heroSubtitle).font(.system(size: 15)).opacity(0.8)
            }
            Spacer(minLength: 0)
            Image(Self.art[filter] ?? "lantern").resizable().scaledToFit().frame(width: 112, height: 132).accessibilityHidden(true)
        }
        .foregroundStyle(scheme == .dark ? .white : Color(hex: 0x111111))
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 196)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: scheme == .dark ? [Color(hex: 0x33443B), Color(hex: 0x2B3747)] : [Color(hex: 0xE4EDDF), Color(hex: 0xE0EDF5)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Theme.border(scheme), lineWidth: 0.8))
        .shadow(color: .black.opacity(scheme == .dark ? 0.3 : 0.06), radius: 14, y: 6)
        .animation(.easeOut(duration: 0.2), value: filter)
    }

    private var heroTitle: String {
        switch filter {
        case "for-you": "For your everyday"
        case "plan": filters.first { $0.id == "plan" }?.title ?? "Your plan"
        default: "For \(filter.lowercased())"
        }
    }

    private var heroSubtitle: String {
        switch filter {
        case "for-you": "Find Scripture for the season you’re in."
        case "plan": "The passages in the plan you’re reading."
        default: "Scripture to sit with, a little at a time."
        }
    }

    // MARK: Filters

    private var chips: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(filters) { f in
                        let selected = f.id == filter
                        Button { filter = f.id } label: {
                            Text(f.id == "plan" ? "Plan" : f.title).font(.system(size: 16))
                                .padding(.horizontal, 18).frame(height: 44)
                                .foregroundStyle(selected ? (scheme == .dark ? Color(hex: 0x111111) : .white) : Theme.text(scheme))
                                .background(Capsule().fill(selected ? (scheme == .dark ? .white : Color(hex: 0x111111)) : Theme.surface(scheme)))
                                .overlay(Capsule().strokeBorder(Theme.border(scheme), lineWidth: selected ? 0 : 0.8))
                        }
                        .buttonStyle(.plain)
                        .id(f.id)
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
                .padding(.horizontal, Theme.Spacing.gutter)
            }
            .padding(.horizontal, -Theme.Spacing.gutter)
            .onChange(of: filter) { _, f in withAnimation { proxy.scrollTo(f, anchor: .center) } }
            .onAppear { proxy.scrollTo(filter, anchor: .center) }
        }
    }

    // MARK: Cards

    @ViewBuilder private var cards: some View {
        if let feed, feed.filter == filter {
            if feed.cards.isEmpty {
                VStack(spacing: 10) {
                    Image(Self.art[filter] ?? "lantern").resizable().scaledToFit().frame(height: 90).accessibilityHidden(true)
                    Text(filter == "plan" ? "Start a reading plan from Home to see its passages here." : "Nothing here yet.")
                        .font(.system(size: 15)).foregroundStyle(Theme.muted(scheme)).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 40)
            } else {
                ForEach(feed.cards) { card in DiscoverCard(card: card, translation: feed.translation ?? translation, onStudy: { studyRef = VerseRef(card.ref) }) }
            }
        } else if failed {
            VStack(spacing: 12) {
                Text("Discover needs a connection. Your Bible still works offline.").font(.system(size: 15)).foregroundStyle(Theme.muted(scheme)).multilineTextAlignment(.center)
                Button("Try again") { Task { await load() } }.buttonStyle(CapsuleButtonStyle(kind: .secondary)).frame(width: 180)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 40)
        } else {
            ProgressView().frame(maxWidth: .infinity).padding(.vertical, 40)
        }
    }
}

private struct DiscoverCard: View {
    let card: DiscoverFeed.Card
    let translation: String
    let onStudy: () -> Void
    @Environment(AppModel.self) private var app
    @Environment(\.colorScheme) private var scheme

    private var translationName: String {
        ["kjv": "King James Version", "bsb": "Berean Standard Bible", "web": "World English Bible"][translation] ?? translation.uppercased()
    }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    if let theme = card.theme {
                        Text(theme).font(.system(size: 13)).padding(.horizontal, 6).padding(.vertical, 2)
                            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Theme.border(scheme)))
                        Text("·").foregroundStyle(Theme.muted(scheme))
                    }
                    Text(card.label).font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(Theme.muted(scheme))
                Text("“\(card.text)”").font(.serif(27, relativeTo: .title2)).fixedSize(horizontal: false, vertical: true)
                Text(translationName).font(.system(size: 13)).foregroundStyle(Theme.muted(scheme))
                if let reflection = card.reflection {
                    Divider().padding(.vertical, 4)
                    Text("A moment of reflection").font(.system(size: 12, weight: .medium)).tracking(1).foregroundStyle(Theme.muted(scheme))
                    Text(reflection).font(.system(size: 17, weight: .medium))
                    Text("Reflection prompt · not Scripture").font(.system(size: 13)).foregroundStyle(Theme.muted(scheme))
                }
                Button {
                    if let ref = VerseRef(card.ref) { app.openInReader(ref) }
                    Task { await Analytics.shared.track("discover_card_read", ["ref": .string(card.ref)]) }
                } label: {
                    HStack(spacing: 8) { Text("Read & reflect"); Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)) }
                        .font(.system(size: 16, weight: .medium)).padding(.horizontal, 22).frame(height: 48)
                        .foregroundStyle(scheme == .dark ? Color(hex: 0x111111) : .white)
                        .background(Capsule().fill(scheme == .dark ? .white : Color(hex: 0x111111)))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
                HStack(spacing: 34) {
                    Button { app.toggleSave(card.ref) } label: { Image(systemName: app.isSaved(card.ref) ? "heart.fill" : "heart") }
                        .accessibilityLabel(app.isSaved(card.ref) ? "Remove from saved" : "Save verse")
                    Button(action: onStudy) { Image(systemName: "bubble") }.accessibilityLabel("Study this verse")
                    ShareLink(item: "“\(card.text)” — \(card.label) (\(BibleStore.offline[translation] ?? ""))") { Image(systemName: "square.and.arrow.up") }
                        .accessibilityLabel("Share verse")
                }
                .font(.system(size: 19))
                .padding(.leading, 6)
            }
            .foregroundStyle(Theme.text(scheme))
        }
    }
}
