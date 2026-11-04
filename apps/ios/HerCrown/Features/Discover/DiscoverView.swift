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
                VStack(alignment: .leading, spacing: 0) {
                    // .app-header: 20/20/16, 28 pt title, 44 pt icon buttons
                    HStack(spacing: 4) {
                        Text("Discover").font(.system(size: 28)).tracking(-0.8).foregroundStyle(Theme.text(scheme))
                        Spacer()
                        IconButton(systemName: "bookmark", label: "Saved passages") { showingSaved = true }
                        IconButton(systemName: "gearshape", label: "Settings") { showingSettings = true }
                    }
                    .padding(EdgeInsets(top: 20, leading: 20, bottom: 16, trailing: 20))
                    hero.padding(.horizontal, 24)
                    chips.padding(.top, 22).padding(.bottom, 20)
                    VStack(spacing: 16) { cards }.padding(.horizontal, 20)
                }
                .padding(.bottom, 124)
            }
            .refreshable { await load() }
            .clipped()
        }
        // Reload once she's signed in (a brand-new guest signs in while this tab may already be open).
        .task(id: "\(filter)|\(app.me?.user.id ?? "")") { await load() }
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

    /// .discovery-illustrated-intro: 24 radius, 26/22 padding, sage-to-sky glass, 32 pt serif, 145×163 art.
    private var hero: some View {
        let dark = scheme == .dark
        return HStack(alignment: .center, spacing: 2) {
            VStack(alignment: .leading, spacing: 14) {
                Text(heroTitle).font(.serif(32, relativeTo: .title)).tracking(-0.6).fixedSize(horizontal: false, vertical: true)
                Text(heroSubtitle).font(.system(size: 13)).lineSpacing(5.3).foregroundStyle(dark ? Color(hex: 0xC4D3C9) : Color(hex: 0x51605A))
            }
            .frame(width: 180, alignment: .leading)
            .foregroundStyle(Theme.text(scheme))
            Spacer(minLength: 0)
            Image(Self.art[filter] ?? "lantern").resizable().scaledToFit().frame(width: 145, height: 163).accessibilityHidden(true)
        }
        .padding(EdgeInsets(top: 22, leading: 22, bottom: 20, trailing: 4))
        .frame(maxWidth: .infinity, minHeight: 206)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous).fill(LinearGradient(
                stops: dark
                    ? [.init(color: Color(red: 52 / 255, green: 72 / 255, blue: 61 / 255, opacity: 0.72), location: 0), .init(color: Color(red: 38 / 255, green: 51 / 255, blue: 61 / 255, opacity: 0.69), location: 0.65), .init(color: Color(red: 51 / 255, green: 66 / 255, blue: 86 / 255, opacity: 0.74), location: 1)]
                    : [.init(color: Color(red: 230 / 255, green: 237 / 255, blue: 223 / 255, opacity: 0.7), location: 0), .init(color: Color.white.opacity(0.52), location: 0.58), .init(color: Color(red: 223 / 255, green: 234 / 255, blue: 244 / 255, opacity: 0.65), location: 1)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Color.white.opacity(dark ? 0.15 : 0.78), lineWidth: 1))
        .shadow(color: dark ? .black.opacity(0.533) : Color(red: 37 / 255, green: 61 / 255, blue: 76 / 255, opacity: 0.22), radius: 8, y: 14)
        .shadow(color: dark ? .black.opacity(0.333) : Color(red: 33 / 255, green: 61 / 255, blue: 66 / 255, opacity: 0.13), radius: 2, y: 3)
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

    /// .filterbar: 44 pt chips, 13 pt, 14 pt side padding, 8 apart; selected is ink.
    private var chips: some View {
        let dark = scheme == .dark
        return ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(filters) { f in
                        let selected = f.id == filter
                        Button { filter = f.id } label: {
                            Text(f.id == "plan" ? "Plan" : f.title).font(.system(size: 13))
                                .padding(.horizontal, 14).frame(height: 44)
                                .foregroundStyle(selected ? (dark ? Color(hex: 0x080809) : Color(hex: 0xF7F7F9)) : Theme.text(scheme))
                                .background(Capsule().fill(selected ? Theme.text(scheme) : (dark ? Color(hex: 0x080809) : Color(hex: 0xF7F7F9))))
                                .overlay(Capsule().strokeBorder(selected ? .clear : Theme.border(scheme), lineWidth: 1))
                                .shadow(color: .black.opacity(selected ? 0.08 : 0.03), radius: selected ? 2 : 1, y: selected ? 2 : 1)
                        }
                        .buttonStyle(.plain)
                        .id(f.id)
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
                .padding(.horizontal, 20)
            }
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

    /// .verse-card: meta (11 pt tag · reference), 29 pt serif verse, translation, a reflection block under a hairline,
    /// Read & reflect, and 44 pt actions.
    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    if let theme = card.theme {
                        Text(theme).font(.system(size: 11)).tracking(0.3).padding(.horizontal, 2)
                            .overlay(Rectangle().strokeBorder(Theme.border(scheme), lineWidth: 1))
                        Text("·")
                    }
                    Text(card.label).font(.system(size: 11, weight: .medium))
                }
                .font(.system(size: 11))
                .foregroundStyle(Theme.muted(scheme))
                Text("“\(card.text)”").font(.serif(29, relativeTo: .title2)).tracking(-0.4).lineSpacing(2.9)
                    .fixedSize(horizontal: false, vertical: true).padding(.top, 26)
                Text(translationName).font(.system(size: 11)).foregroundStyle(Theme.muted(scheme)).padding(.top, 16)
                if let reflection = card.reflection {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("A moment of reflection").font(.system(size: 10)).tracking(0.8).foregroundStyle(Theme.muted(scheme))
                        Text(reflection).font(.system(size: 15)).lineSpacing(4.6).fixedSize(horizontal: false, vertical: true).padding(.top, 10)
                        Text("Reflection prompt · not Scripture").font(.system(size: 11)).foregroundStyle(Theme.muted(scheme)).padding(.top, 14)
                    }
                    .padding(.top, 20)
                    .overlay(alignment: .top) { Rectangle().fill(Theme.border(scheme)).frame(height: 1) }
                    .padding(.top, 22)
                }
                Button {
                    if let ref = VerseRef(card.ref) { app.openInReader(ref) }
                    Task { await Analytics.shared.track("discover_card_read", ["ref": .string(card.ref)]) }
                } label: {
                    HStack(spacing: 8) { Text("Read & reflect"); Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold)) }
                        .font(.system(size: 14)).padding(.horizontal, 20).frame(height: 48)
                        .foregroundStyle(scheme == .dark ? Color(hex: 0x080809) : Color(hex: 0xF7F7F9))
                        .background(Capsule().fill(Theme.text(scheme)))
                        .shadow(color: .black.opacity(0.07), radius: 1, y: 1)
                }
                .buttonStyle(.plain)
                .padding(.top, 20)
                HStack(spacing: 13) {
                    Button { app.toggleSave(card.ref) } label: {
                        Image(systemName: app.isSaved(card.ref) ? "heart.fill" : "heart").foregroundStyle(app.isSaved(card.ref) ? Theme.text(scheme) : Theme.muted(scheme)).frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(app.isSaved(card.ref) ? "Remove from saved" : "Save verse")
                    Button(action: onStudy) { Image(systemName: "bubble").foregroundStyle(Theme.muted(scheme)).frame(width: 44, height: 44) }.accessibilityLabel("Study this verse")
                    ShareLink(item: "“\(card.text)” — \(card.label) (\(BibleStore.offline[translation] ?? ""))") {
                        Image(systemName: "square.and.arrow.up").foregroundStyle(Theme.muted(scheme)).frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Share verse")
                }
                .font(.system(size: 17))
                .padding(.top, 8)
            }
            .foregroundStyle(Theme.text(scheme))
        }
    }
}
