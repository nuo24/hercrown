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
    var nextOffset: Int? = nil
}

enum DiscoverStudied {
    static let storageKey = "hc.discoverStudied"

    static func byAccount(_ data: Data) -> [String: [String]] {
        (try? JSONDecoder().decode([String: [String]].self, from: data)) ?? [:]
    }

    static func accountKey(_ userID: String?) -> String { userID ?? "offline" }
}

/// discover.feed (specs/SCREEN-MAP.md): illustrated introduction, topic filters (For you, her plan, nine themes) and
/// Scripture cards from our Bibles, each with a reflection question clearly marked as not Scripture.
struct DiscoverView: View {
    let onOpenSettings: () -> Void
    @Environment(AppModel.self) private var app
    @Environment(\.colorScheme) private var scheme
    @State private var filter = "for-you"
    @State private var feed: DiscoverFeed?
    @State private var failed = false
    @State private var loadingMore = false
    @State private var moreFailed = false
    @State private var showingSaved = false
    @State private var studyRef: VerseRef?
    @State private var noteRef: VerseRef?
    @State private var detail: DiscoverFeed.Card?
    @State private var pendingDetailAction: DetailAction?
    @State private var query = ""
    @State private var searching = false
    @FocusState private var searchFocused: Bool

    private enum DetailAction {
        case note(VerseRef), study(VerseRef)
    }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(DiscoverStudied.storageKey) private var studiedData = Data()

    private var accountKey: String { DiscoverStudied.accountKey(app.me?.user.id) }
    private var studied: [String] { DiscoverStudied.byAccount(studiedData)[accountKey] ?? [] }

    private var translation: String { app.readingTranslation }
    private static let themes = ["Peace", "Purpose", "Faith", "Relationships", "Identity", "Anxiety", "Gratitude", "Hope", "Wisdom"]

    private static let editorial: [String: (title: String, art: String)] = [
        "PSA.23.1": ("A softer place to land", "olive"),
        "PRO.31.25": ("Clothed in quiet strength", "intention-heart"),
        "MAT.11.28": ("Lay down what you carry", "rest-stones"),
        "JER.29.11": ("Hope for the unfolding", "sunrise"),
        "PRO.3.5": ("Trust the next small step", "faith-hands"),
        "PSA.119.105": ("A little light for the way", "lantern"),
        "PSA.107.1": ("Notice the ordinary gifts", "gratitude-basket"),
        "PRO.17.17": ("Love that stays close", "relationship-hands"),
        "JAS.1.5": ("Make room for wisdom", "wisdom-pearl")
    ]

    private static let artworkFamilies: [String: [String]] = [
        "peace": ["olive", "dove", "rest-stones"], "identity": ["intention-heart", "milestone", "seedling"],
        "anxiety": ["rest-stones", "dove", "reflection"], "hope": ["sunrise", "butterfly", "anchor"],
        "faith": ["faith-hands", "anchor", "dove"], "purpose": ["lantern", "purpose-compass", "seedling"],
        "gratitude": ["gratitude-basket", "cosmos", "sunrise"], "relationships": ["relationship-hands", "community", "intention-heart"],
        "wisdom": ["wisdom-pearl", "open-book", "lantern"]
    ]

    private var requestedFilter: String { filter == "saved" ? "for-you" : filter }
    private var filters: [DiscoverFeed.Filter] {
        var result = feed?.filters ?? [.init(id: "for-you", title: "For you")] + Self.themes.map { .init(id: $0, title: $0) }
        if !result.contains(where: { $0.id == "saved" }) { result.insert(.init(id: "saved", title: "Saved"), at: min(1, result.count)) }
        return result
    }

    private func title(for card: DiscoverFeed.Card) -> String { Self.editorial[card.ref]?.title ?? DiscoverTitles.byReference[card.ref] ?? "A moment for \(card.theme?.lowercased() ?? "reflection")" }

    private func artwork(for card: DiscoverFeed.Card) -> String {
        if let art = Self.editorial[card.ref]?.art { return art }
        let family = Self.artworkFamilies[card.theme?.lowercased() ?? ""] ?? ["open-book", "olive", "lantern"]
        let hash = card.ref.utf16.reduce(UInt32(0)) { $0 &* 31 &+ UInt32($1) }
        return family[Int(hash % UInt32(family.count))]
    }

    var body: some View {
        ZStack {
            AppGradient()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    HStack(spacing: 0) {
                        Text("Discover").font(.serif(34, relativeTo: .largeTitle)).tracking(-0.65)
                            .foregroundStyle(Theme.text(scheme)).accessibilityAddTraits(.isHeader)
                        Spacer()
                        PageIconButton(glyph: "search", label: "Search Discover") {
                            searching.toggle()
                            if searching { searchFocused = true } else { query = "" }
                        }
                        Menu {
                            Button("Saved passages", systemImage: "bookmark") { showingSaved = true }
                            Button("Settings", systemImage: "gearshape", action: onOpenSettings)
                        } label: {
                            Image(systemName: "ellipsis").font(.system(size: 20))
                                .foregroundStyle(Theme.text(scheme)).frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("Discover options")
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)

                    if searching {
                        HStack(spacing: 10) {
                            Image.glyph("search").frame(width: 18, height: 18)
                            TextField("Search passages or topics", text: $query).font(.ui(14)).focused($searchFocused)
                        }
                        .padding(.horizontal, 22).frame(minHeight: 44)
                    }
                    Section {
                        LazyVStack(alignment: .leading, spacing: 14) {
                            cards
                            if feed?.nextOffset != nil {
                                if moreFailed { Button("Try loading more") { Task { await loadMore() } }.font(.ui(13)) }
                                else { ProgressView().frame(maxWidth: .infinity).task(id: feed?.nextOffset) { await loadMore() } }
                            }
                        }
                            .padding(.horizontal, 22)
                    } header: {
                        chips
                            .background(Theme.canvas(scheme))
                    }
                }
                .padding(.bottom, 80)
            }
            .clipped()
            .scrollDismissesKeyboard(.interactively)
            .refreshable { await load() }
        }
        // Reload once she's signed in (a brand-new guest signs in while this tab may already be open).
        .task(id: "\(filter)|\(translation)|\(app.me?.user.id ?? "")") { await load() }
        .onAppear { if let topic = app.discoverTopic { filter = topic; app.discoverTopic = nil } }
        .sheet(isPresented: $showingSaved) { SavedSheet(translation: translation) }
        .sheet(item: $detail, onDismiss: openDetailAction) { card in
            NavigationStack {
                ScrollView {
                    DiscoverCard(card: card, translation: feed?.translation ?? translation, onStudy: {
                        if let ref = VerseRef(card.ref) { pendingDetailAction = .study(ref); detail = nil }
                    }, onNote: {
                        if let ref = VerseRef(card.ref) { pendingDetailAction = .note(ref); detail = nil }
                    }, onComplete: { [accountKey] in
                        markStudied(card.ref, accountKey: accountKey)
                        detail = nil
                    })
                    .padding(22)
                }
                .background(AppGradient())
                .navigationTitle(title(for: card))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { detail = nil } } }
            }
        }
        .sheet(item: $studyRef) { ref in
            NavigationStack {
                AIStudyView(ref: ref, translation: feed?.translation ?? translation, tool: .deeper)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) { Button("Done") { studyRef = nil } }
                    }
            }
                .presentationDetents([.large])
        }
        .sheet(item: $noteRef) { ref in
            ReflectionSheet(ref: ref, translation: feed?.translation ?? translation)
                .presentationDetents([.large])
        }
    }

    private func openStudy(_ ref: VerseRef) {
        studyRef = ref
    }
    private func openDetailAction() {
        switch pendingDetailAction {
        case .study(let ref): openStudy(ref)
        case .note(let ref): noteRef = ref
        case nil: break
        }
        pendingDetailAction = nil
    }

    private func load() async {
        if feed?.translation != translation { feed = nil }
        let selected = filter
        let source = requestedFilter
        let encoded = source.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? source
        do {
            let response: DiscoverFeed = try await app.api.get("/discover?filter=\(encoded)&translation=\(translation)")
            guard !Task.isCancelled, filter == selected else { return }
            feed = response
            failed = false
        } catch {
            guard !Task.isCancelled, filter == selected else { return }
            failed = feed?.filter != source
        }
        await Analytics.shared.track("discover_viewed", ["filter": .string(selected)])
    }

    private func loadMore() async {
        guard !loadingMore, let previous = feed, let offset = previous.nextOffset else { return }
        loadingMore = true; moreFailed = false
        defer { loadingMore = false }
        let selected = filter; let edition = translation
        let encoded = requestedFilter.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? requestedFilter
        do {
            let next: DiscoverFeed = try await app.api.get("/discover?filter=\(encoded)&translation=\(edition)&offset=\(offset)")
            guard !Task.isCancelled, filter == selected, translation == edition else { return }
            feed = DiscoverFeed(filter: next.filter, filters: next.filters, translation: next.translation,
                cards: previous.cards + next.cards.filter { c in !previous.cards.contains { $0.id == c.id } }, nextOffset: next.nextOffset)
        } catch { if !Task.isCancelled { moreFailed = true } }
    }

    private func markStudied(_ ref: String, accountKey: String) {
        var completed = DiscoverStudied.byAccount(studiedData)
        guard completed[accountKey]?.contains(ref) != true else { return }
        completed[accountKey, default: []].append(ref)
        guard let data = try? JSONEncoder().encode(completed) else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.32)) { studiedData = data }
        Task { await Analytics.shared.track("discover_card_read", ["ref": .string(ref)]) }
    }

    private func feature(_ card: DiscoverFeed.Card) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 12) {
                Text(title(for: card)).font(.serif(34, relativeTo: .title)).tracking(-0.6)
                Text(card.ref == "PSA.23.1" ? "A moment in Psalm 23, just for you and God." : card.label)
                    .font(.ui(12)).foregroundStyle(Theme.muted(scheme))
                Button { detail = card } label: {
                    HStack(spacing: 9) {
                        Text("Begin reading").font(.ui(12, weight: .medium))
                        Image.glyph("arrow").frame(width: 16, height: 16)
                    }
                    .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image.illustration(artwork(for: card)).resizable().scaledToFit()
                .frame(maxWidth: 165, maxHeight: 182).rotationEffect(.degrees(12)).accessibilityHidden(true)
        }
        .foregroundStyle(Theme.text(scheme))
        .frame(minHeight: 219)
    }

    private func entry(_ card: DiscoverFeed.Card) -> some View {
        HStack(spacing: 6) {
            Button { detail = card } label: {
                HStack(spacing: 14) {
                    Image.illustration(artwork(for: card)).resizable().scaledToFit()
                        .padding(3).frame(width: 74, height: 86).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(title(for: card)).font(.serif(23, relativeTo: .title3)).tracking(-0.3)
                            .padding(.bottom, 5)
                        Text(card.label.uppercased()).font(.ui(10)).tracking(0.35).foregroundStyle(Theme.muted(scheme))
                        if let theme = card.theme { Text(theme.uppercased()).font(.ui(9)).tracking(0.4).foregroundStyle(Theme.muted(scheme)) }
                    }
                    Spacer(minLength: 0)
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, minHeight: 86, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Menu {
                Button(app.isSaved(card.ref) ? "Remove from saved" : "Save passage", systemImage: "heart") { app.toggleSave(card.ref) }
                Button("Read in The Bible", systemImage: "book") { if let ref = VerseRef(card.ref) { app.openInReader(ref) } }
                Button("Study passage", systemImage: "magnifyingglass") { if let ref = VerseRef(card.ref) { openStudy(ref) } }
                Button("Write a note", systemImage: "message") { noteRef = VerseRef(card.ref) }
            } label: {
                Image(systemName: "ellipsis").font(.system(size: 20)).frame(width: 44, height: 44)
            }
            .accessibilityLabel("Actions for \(card.label)")
        }
        .foregroundStyle(Theme.text(scheme))
    }

    // MARK: Filters

    /// .filterbar: 44 pt chips, 13 pt, 14 pt side padding, 8 apart; selected is ink.
    private var chips: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(filters) { f in
                        let selected = f.id == filter
                        Button { filter = f.id } label: {
                            Text((f.id == "plan" ? "Plan" : f.title).uppercased())
                                .font(.ui(10, weight: .medium)).tracking(0.45)
                                .padding(.horizontal, 6).frame(minHeight: 44)
                                .foregroundStyle(selected ? Theme.text(scheme) : Theme.muted(scheme))
                                .overlay(alignment: .bottom) {
                                    if selected { Rectangle().fill(Theme.text(scheme)).frame(height: 1) }
                                }
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
        if let feed, feed.filter == requestedFilter {
            let search = query.trimmingCharacters(in: .whitespacesAndNewlines)
            let remaining = feed.cards.filter { card in
                if filter == "saved", !app.isSaved(card.ref) { return false }
                if filter != "saved", studied.contains(card.ref) { return false }
                return search.isEmpty || [card.label, card.text, card.theme ?? "", title(for: card)]
                    .contains { $0.localizedCaseInsensitiveContains(search) }
            }
            if remaining.isEmpty {
                VStack(spacing: 10) {
                    Image.illustration("lantern").resizable().scaledToFit().frame(height: 90).accessibilityHidden(true)
                    Text(emptyMessage(searching: !search.isEmpty, sourceEmpty: feed.cards.isEmpty))
                        .font(.ui(14)).foregroundStyle(Theme.muted(scheme)).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 40)
            } else {
                let featured = filter == "for-you" && search.isEmpty
                    ? remaining.first(where: { $0.ref == "PSA.23.1" }) ?? remaining.first
                    : nil
                if let featured { feature(featured) }
                HStack {
                    Text("For your everyday").font(.ui(13, weight: .medium))
                    Spacer()
                    Text("Read at your own pace").font(.ui(10)).foregroundStyle(Theme.muted(scheme))
                }
                .padding(.top, 19)
                .overlay(alignment: .top) { Divider() }
                ForEach(remaining.filter { $0.id != featured?.id }) { card in
                    entry(card).transition(.opacity)
                }
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

    private func emptyMessage(searching: Bool, sourceEmpty: Bool) -> String {
        if searching { return "No passages match your search." }
        if filter == "saved" { return "Saved Discover passages will appear here." }
        if filter == "plan" { return "Start a reading plan from Home to see its passages here." }
        return sourceEmpty ? "Nothing here yet." : "You’ve studied every verse in this collection."
    }

}

private struct DiscoverCard: View {
    let card: DiscoverFeed.Card
    let translation: String
    let onStudy: () -> Void
    let onNote: () -> Void
    let onComplete: () -> Void
    @Environment(AppModel.self) private var app
    @Environment(\.colorScheme) private var scheme

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var confirmStudied = false
    @State private var completing = false

    private var translationName: String {
        BibleStore.names[translation] ?? translation.uppercased()
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
                ScriptureText(text: "“\(card.text)”", reference: card.ref, translation: translation).font(.serif(25, relativeTo: .title2)).tracking(-0.4).lineSpacing(2.9)
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
                Button(action: onStudy) {
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
                    Button(action: onNote) { Image(systemName: "message").foregroundStyle(Theme.muted(scheme)).frame(width: 44, height: 44) }.accessibilityLabel("Write a note")
                    VerseShareButton(text: card.text, reference: card.label, translation: translation)
                    Button { confirmStudied = true } label: {
                        Image(systemName: completing ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(completing ? Theme.readDay : Theme.muted(scheme))
                            .scaleEffect(completing && !reduceMotion ? 1.15 : 1)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Mark as studied")
                    .disabled(completing)
                }
                .font(.system(size: 17))
                .padding(.top, 8)
            }
            .foregroundStyle(Theme.text(scheme))
        }
        .alert("Mark as studied?", isPresented: $confirmStudied) {
            Button("Mark as Studied") {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.16)) { completing = true }
                Task {
                    if !reduceMotion { try? await Task.sleep(for: .milliseconds(440)) }
                    onComplete()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This study will leave Discover and move to Saved → Studied, including any notes you’ve written.")
        }
    }
}
