import SwiftUI

/// Home (specs/SCREEN-MAP.md `home`): greeting with her streak, streak card, verse of the day, verse search,
/// Today's Reading, "For the season you're in" topic cards, and today's devotional in the reflection card.
struct HomeView: View {
    let onOpenSettings: () -> Void
    @Environment(AppModel.self) private var app
    @Environment(\.colorScheme) private var scheme
    @State private var model = HomeModel()
    @State private var showingStreak = false
    @State private var showingSaved = false
    @State private var showingSearch = false
    @State private var pendingSearchStudy: VerseRef?
    @State private var showingProfile = false
    @State private var collection: Collection = .library
    @State private var noteRef: VerseRef?
    @State private var notes: [HomeNote]?
    @State private var notesUnavailable = false
    @State private var noteToDelete: HomeNote?
    @State private var deleteFailed = false

    private enum Collection: String, CaseIterable { case library = "Library", bookmarks = "Bookmarks", notes = "Notes" }
    private struct HomeNote: Decodable, Identifiable {
        let ref: String
        let label: String
        let text: String
        var id: String { ref }
    }
    @State private var studyRef: VerseRef?
    @State private var openPlan: ReadingPlan?
    @State private var showingPlans = false
    @State private var openDevotional: Devotional?
    @State private var searchRef = VerseRef(book: "PSA", chapter: 23, verse: 1)

    private var translation: String { BibleStore.offline[app.preferences.translation] == nil ? "kjv" : app.preferences.translation }

    var body: some View {
        ZStack {
            AppGradient()
            ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    identity
                    collections
                    Divider()
                    VStack(alignment: .leading, spacing: 0) {
                        switch collection {
                        case .library: library
                        case .bookmarks: bookmarks
                        case .notes: notesPanel
                        }
                    }
                    .padding(.horizontal, 22)
                }
                .padding(.bottom, 124)
            }
            .refreshable { await model.load(translation: translation); if collection == .notes { await loadNotes() } }
            #if DEBUG
            // Review switch: `-hcHomeScroll search|season` scrolls there once loaded.
            .task(id: model.loaded) {
                guard model.loaded, let anchor = UserDefaults.standard.string(forKey: "hcHomeScroll") else { return }
                try? await Task.sleep(for: .milliseconds(300)); if anchor == "search" { showingSearch = true } else { proxy.scrollTo(anchor, anchor: .top) }
            }
            #endif
            }
        }
        // Reload once she's signed in (a brand-new guest signs in while Home is already on screen).
        .task(id: app.me?.user.id) { await model.load(translation: translation) }
        .onChange(of: app.me?.user.id) { _, _ in
            notes = nil
            notesUnavailable = false
            noteToDelete = nil
            noteRef = nil
        }
        .task(id: collection == .notes ? app.me?.user.id ?? "offline" : nil) {
            if collection == .notes { await loadNotes() }
        }
        .sheet(isPresented: $showingSearch, onDismiss: { if let ref = pendingSearchStudy { pendingSearchStudy = nil; studyRef = ref } }) {
            NavigationStack {
                ScrollView { verseSearch.padding(22) }
                    .navigationTitle("Search Scripture")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showingSearch = false } } }
            }
        }
        .sheet(isPresented: $showingProfile) {
            NavigationStack {
                AccountView().toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { showingProfile = false } } }
            }
        }
        .sheet(item: $noteRef, onDismiss: { Task { await loadNotes() } }) { ref in
            ReflectionSheet(ref: ref, translation: translation, notesOnly: true).presentationDetents([.large])
        }
        .alert("Delete this note?", isPresented: Binding(get: { noteToDelete != nil }, set: { if !$0 { noteToDelete = nil } }), presenting: noteToDelete) { note in
            Button("Delete", role: .destructive) { Task { await deleteNote(note) } }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Couldn’t delete the note", isPresented: $deleteFailed) { Button("OK", role: .cancel) {} }
        .sheet(isPresented: $showingStreak) { StreakSheet(model: model).presentationDetents([.large]) }
        .sheet(isPresented: $showingSaved) { SavedSheet(translation: translation) }
        .sheet(isPresented: $showingPlans) { PlansListSheet(model: model) { plan in showingPlans = false; openPlan = plan }.presentationDetents([.large]) }
        .sheet(item: $studyRef) { ref in
            InsightsSheet(ref: ref, translation: translation) { r in app.openInReader(r) }.presentationDetents([.large])
        }
        .sheet(item: $openPlan) { plan in PlanSheet(planId: plan.id, model: model).presentationDetents([.large]) }
        .sheet(item: $openDevotional) { d in DevotionalSheet(devotional: d, model: model).presentationDetents([.large]) }
        #if DEBUG
        // Review switch: `-hcOpenHome streak|devotional|plan|plans|saved|settings`.
        .task(id: model.loaded) {
            guard model.loaded else { return }
            switch UserDefaults.standard.string(forKey: "hcOpenHome") {
            case "streak": showingStreak = true
            case "devotional": openDevotional = model.devotional
            case "plan": openPlan = model.todaysPlan
            case "plans": showingPlans = true
            case "saved": showingSaved = true
            case "settings": onOpenSettings()
            default: break
            }
        }
        #endif
    }

    private var header: some View {
        HStack(spacing: 0) {
            Text("Home").font(.serif(32, relativeTo: .largeTitle)).tracking(-0.65)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            PageIconButton(glyph: "search", label: "Search Scripture") { showingSearch = true }
            PageIconButton(glyph: "gear", label: "Settings", action: onOpenSettings)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
    }

    private var identity: some View {
        HStack(spacing: 12) {
            Button { showingProfile = true } label: {
                HStack(spacing: 12) {
                    Avatar(size: 57)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(app.displayName.flatMap { $0.isEmpty || $0 == "Guest" ? nil : $0 } ?? "Welcome")
                            .font(.serif(26, relativeTo: .title2)).lineLimit(1).minimumScaleFactor(0.75)
                        Text(app.me?.profile.bio.flatMap { $0.isEmpty ? nil : $0 } ?? "Make a little room for faith every day.")
                            .font(.ui(11)).foregroundStyle(Theme.muted(scheme))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .accessibilityHint("Edit your profile")
            Button { showingStreak = true } label: {
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image.glyph("flame").frame(width: 19, height: 23)
                        Text(model.streak.current.formatted()).font(.serif(26, relativeTo: .title2))
                    }
                    Text("day streak").font(.ui(10)).foregroundStyle(Theme.muted(scheme))
                }
                .frame(minWidth: 61, minHeight: 49)
            }
            .accessibilityLabel("Reading streak, \(model.streak.current) days")
        }
        .buttonStyle(.plain)
        .foregroundStyle(Theme.text(scheme))
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
    }

    private var collections: some View {
        HStack(spacing: 8) {
            ForEach(Collection.allCases, id: \.self) { item in
                let selected = item == collection
                Button { collection = item } label: {
                    Text(item.rawValue.uppercased()).font(.ui(10, weight: .medium)).tracking(0.3)
                        .padding(.horizontal, 13)
                        .frame(minHeight: 35)
                        .foregroundStyle(selected ? Theme.canvas(scheme) : Theme.muted(scheme))
                        .background(selected ? Theme.text(scheme) : .clear, in: Capsule())
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22)
        .padding(.bottom, 8)
    }

    private var library: some View {
        VStack(alignment: .leading, spacing: 0) {
            if app.membership.premium, let trial = app.membership.subscription?.trial, app.membership.subscription?.isTrial == true,
               Date().timeIntervalSince1970 * 1000 >= trial.remindFrom,
               Date().timeIntervalSince1970 * 1000 < trial.endsAt { trialNotice(trial) }
            if let verse = model.verse { verseOfTheDay(verse) }
            else if !model.loaded { ProgressView().frame(maxWidth: .infinity).padding(30) }
            if let devotional = model.devotional {
                editorialRow(devotional.title, kicker: "Today’s devotional", detail: devotional.label, art: "devotional-teacup") {
                    openDevotional = devotional
                }
            }
            let plan = model.todaysPlan
            editorialRow(plan?.title ?? "Find your reading rhythm", kicker: "Reading plans", detail: plan.map(planStatus) ?? "Make a little room for the Word", art: "wisdom-scroll") {
                if let plan { openPlan = plan } else { showingPlans = true }
            }
            if let ref = model.verse.flatMap({ VerseRef($0.ref) }) {
                editorialRow("A little space to reflect", kicker: "Verse reflection", detail: BibleStore.shared.label(ref), art: "reflection-quill") {
                    noteRef = ref
                }
            }
            season.id("season").padding(.top, 24)
            Button("Saved passages") { showingSaved = true }.font(.ui(13, weight: .medium)).frame(minHeight: 44)
        }
    }

    private var bookmarks: some View {
        VStack(alignment: .leading, spacing: 0) {
            collectionHeading("Bookmarks")
            if app.readerBookmarks.isEmpty {
                Text("Bookmark a verse in The Bible to pick up where you left off.")
                    .font(.ui(14)).foregroundStyle(Theme.muted(scheme))
                Button("Open The Bible") { app.requestedTab = .bible }.font(.ui(14, weight: .medium)).frame(minHeight: 44)
            }
            ForEach(app.readerBookmarks.compactMap { VerseRef($0) }, id: \.self) { ref in
                editorialRow(BibleStore.shared.label(ref), kicker: "Bookmarked verse", detail: BibleStore.offline[translation] ?? "KJV", art: "bookmark") {
                    app.openInReader(ref)
                }
                Button("Remove bookmark", role: .destructive) { app.toggleBookmark(ref.description) }
                    .font(.ui(11)).frame(minHeight: 44).padding(.leading, 88)
                    .accessibilityLabel("Remove bookmark for \(BibleStore.shared.label(ref))")
            }
        }
    }

    private var notesPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            collectionHeading("Notes")
            if notesUnavailable {
                Text("Connect to load your verse notes.").font(.ui(14)).foregroundStyle(Theme.muted(scheme))
                Button("Try again") { Task { await loadNotes() } }.frame(minHeight: 44)
            } else if let notes {
                if notes.isEmpty {
                    Text("Your notes will gather here when you reflect on a verse.").font(.ui(14)).foregroundStyle(Theme.muted(scheme))
                    Button("Open The Bible") { app.requestedTab = .bible }.frame(minHeight: 44)
                }
                ForEach(notes) { note in
                    if let ref = VerseRef(note.ref) {
                        VStack(alignment: .leading, spacing: 12) {
                            Button { app.openInReader(ref) } label: {
                                Text(note.label).font(.serif(25, relativeTo: .title2))
                            }
                            if let excerpt = BibleStore.shared.text(translation, ref) {
                                Text(excerpt).font(.serif(15)).foregroundStyle(Theme.muted(scheme))
                            }
                            Text(note.text).font(.ui(13)).lineSpacing(4)
                            HStack {
                                Button("Edit note") { noteRef = ref }.font(.ui(13, weight: .medium))
                                Spacer()
                                Button("Delete note", role: .destructive) { noteToDelete = note }.font(.ui(11))
                            }
                            .frame(minHeight: 44)
                        }
                        .padding(.bottom, 24)
                        .buttonStyle(.plain)
                        Divider().padding(.bottom, 24)
                    }
                }
            } else { ProgressView().frame(maxWidth: .infinity).padding(30) }
        }
    }

    private func collectionHeading(_ title: String) -> some View {
        Text(title).font(.serif(30, relativeTo: .title)).accessibilityAddTraits(.isHeader)
            .padding(.vertical, 24)
    }

    private func loadNotes() async {
        struct Response: Decodable { let notes: [HomeNote] }
        let account = app.me?.user.id
        do {
            let response: Response = try await app.api.get("/me/notes")
            guard !Task.isCancelled, app.me?.user.id == account else { return }
            notes = response.notes
            notesUnavailable = false
        } catch {
            guard !Task.isCancelled, app.me?.user.id == account else { return }
            notesUnavailable = true
        }
    }

    private func deleteNote(_ note: HomeNote) async {
        let account = app.me?.user.id
        do {
            _ = try await app.api.send("DELETE", "/me/notes/\(note.ref)")
            guard app.me?.user.id == account else { return }
            notes?.removeAll { $0.ref == note.ref }
        } catch {
            if app.me?.user.id == account { deleteFailed = true }
        }
    }

    @ViewBuilder private func editorialRow(_ title: String, kicker: String, detail: String, art: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image.illustration(art).resizable().scaledToFit().frame(width: 72, height: 88).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 7) {
                    Text(title).font(.serif(24, relativeTo: .title2)).tracking(-0.35)
                    Text(kicker.uppercased()).font(.ui(9, weight: .medium)).tracking(0.55).foregroundStyle(Theme.muted(scheme))
                    Text(detail).font(.ui(11)).foregroundStyle(Theme.muted(scheme))
                }
                Spacer(minLength: 4)
                Image.glyph("arrow").frame(width: 15, height: 15)
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, minHeight: 102, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        Divider()
    }

    // MARK: Trial notice (docs/trial-reminder.md: from 2 days before the trial converts)

    private func trialNotice(_ trial: Membership.Trial) -> some View {
        let ends = Date(timeIntervalSince1970: trial.endsAt / 1000)
        return Card {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your free trial ends \(ends.formatted(.relative(presentation: .named)))").font(.system(size: 14, weight: .semibold))
                Text(trial.convertsToPaid
                     ? "Her Crown Plus becomes a paid plan on \(ends.formatted(date: .abbreviated, time: .omitted)). To avoid being charged, cancel before then."
                     : "Plus ends on \(ends.formatted(date: .abbreviated, time: .omitted)). You won’t be charged.")
                    .font(.system(size: 12)).foregroundStyle(Theme.muted(scheme))
                if trial.convertsToPaid, let url = URL(string: trial.manageUrl) {
                    Link("Manage subscription", destination: url).font(.system(size: 13, weight: .semibold)).padding(.top, 2)
                }
            }
            .foregroundStyle(Theme.text(scheme))
        }
    }

    // MARK: Verse of the Day

    private func verseOfTheDay(_ verse: DayVerse) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Verse of the Day").font(.ui(12, weight: .medium))
                    Spacer()
                    Button { app.toggleSave(verse.ref) } label: {
                        Group {
                            if app.isSaved(verse.ref) { Image(systemName: "heart.fill").font(.system(size: 19)) }
                            else { Image.glyph("heart").frame(width: 21, height: 21) }
                        }
                        .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(app.isSaved(verse.ref) ? "Remove from saved" : "Save verse")
                }
                Text(verse.text ?? "").font(.serif(28, relativeTo: .title2)).tracking(-0.4).lineSpacing(1)
                    .fixedSize(horizontal: false, vertical: true).frame(maxWidth: 265, alignment: .leading)
                HStack(spacing: 4) {
                    Text("\(verse.label.uppercased()) · \(BibleStore.offline[verse.translation] ?? verse.translation.uppercased())")
                        .font(.ui(10)).tracking(0.45).foregroundStyle(Theme.muted(scheme))
                    Spacer()
                    Button { studyRef = VerseRef(verse.ref) } label: {
                        HStack(spacing: 5) {
                            Text("Read & reflect").font(.ui(11, weight: .medium))
                            Image.glyph("arrow").frame(width: 14, height: 14)
                        }
                        .frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    ShareLink(item: "“\(verse.text ?? "")” — \(verse.label) (\(BibleStore.offline[verse.translation] ?? ""))") {
                        Image.glyph("share").frame(width: 19, height: 19).frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Share verse")
                }
            }
            .foregroundStyle(Theme.text(scheme))
            .padding(.vertical, 10)
            Divider()
        }
    }

    // MARK: Verse search (.search-card)

    private var verseSearch: some View {
        let books = BibleStore.shared.books
        let chapters = books.first { $0.id == searchRef.book }?.chapterCount ?? 0
        let verses = BibleStore.shared.chapter(translation, book: searchRef.book, chapter: searchRef.chapter)?.verses ?? []
        let selectedVerse = verses.first { $0.number == searchRef.verse } ?? verses.first

        return Card {
            VStack(alignment: .leading, spacing: 10) {
                Label("Verse Search", systemImage: "magnifyingglass")
                    .font(.serif(23, relativeTo: .title3))
                Text("Choose a passage to read and reflect on.")
                    .font(.system(size: 13)).foregroundStyle(Theme.muted(scheme))
                HStack(spacing: 0) {
                    Picker("Book", selection: Binding(get: { searchRef.book }, set: {
                        searchRef = VerseRef(book: $0, chapter: 1, verse: 1)
                    })) {
                        ForEach(books) { book in
                            Text(book.displayName).lineLimit(1).minimumScaleFactor(0.7).tag(book.id)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    Picker("Chapter", selection: Binding(get: { searchRef.chapter }, set: {
                        searchRef = VerseRef(book: searchRef.book, chapter: $0, verse: 1)
                    })) {
                        ForEach(1..<(chapters + 1), id: \.self) { Text("\($0)").tag($0) }
                    }
                    .frame(width: 64)
                    Picker("Verse", selection: Binding(get: { selectedVerse?.number ?? 1 }, set: {
                        searchRef = VerseRef(book: searchRef.book, chapter: searchRef.chapter, verse: $0)
                    })) {
                        ForEach(verses) { verse in Text("\(verse.number)").tag(verse.number) }
                    }
                    .frame(width: 64)
                }
                .pickerStyle(.wheel)
                .frame(height: 100)
                .clipped()
                Button("Study this verse") {
                    guard let selectedVerse else { return }
                    let ref = VerseRef(book: searchRef.book, chapter: searchRef.chapter, verse: selectedVerse.number)
                    pendingSearchStudy = ref
                    showingSearch = false
                    Task { await Analytics.shared.track("verse_search_studied", ["ref": .string(ref.description)]) }
                }
                .buttonStyle(CapsuleButtonStyle())
                .disabled(selectedVerse == nil)
            }
            .foregroundStyle(Theme.text(scheme))
        }
    }

    // MARK: Today's Reading (.reading-card: 16 padding, 14 gap, 82×100 journal)

    private func planStatus(_ plan: ReadingPlan) -> String {
        guard let p = plan.progress else { return "\(plan.days) passages · Read at your own pace" }
        if p.completedAt != nil { return "Completed · all \(plan.days) passages" }
        return "\(p.completedSteps) of \(plan.days) passages read"
    }

    // MARK: For the season you're in (.home-topic-section)

    private var season: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("For the season you’re in").font(.serif(28, relativeTo: .title)).tracking(-0.4).foregroundStyle(Theme.text(scheme))
            Text("A little guidance for today.").font(.system(size: 13)).foregroundStyle(Theme.muted(scheme)).padding(.top, 8)
            HStack(alignment: .top, spacing: 12) {
                SeasonCard(kind: .faith) { openTopic("Faith") }
                SeasonCard(kind: .purpose) { openTopic("Purpose") }
            }
            .padding(.top, 20)
        }
        .padding(.top, 4).padding(.bottom, 6)
    }

    private func openTopic(_ topic: String) {
        app.discoverTopic = topic
        app.requestedTab = .discover
        Task { await Analytics.shared.track("home_topic_opened", ["topic": .string(topic)]) }
    }


}

/// .home-topic-card: 175×287, 20 radius, tinted gradient (light and dark values from the mockup), 145×134 art.
private struct SeasonCard: View {
    enum Kind { case faith, purpose }
    let kind: Kind
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let dark = scheme == .dark
        let faith = kind == .faith
        let colors: [Color] = faith
            ? (dark ? [Color(hex: 0x293B30), Color(hex: 0x222E28)] : [Color(hex: 0xE7EEE5), Color(hex: 0xF4F7EF)])
            : (dark ? [Color(hex: 0x293C4B), Color(hex: 0x232E38)] : [Color(hex: 0xE2EDF5), Color(hex: 0xF1F4F7)])
        let ink: Color = faith ? (dark ? Color(hex: 0xEFF4EE) : Color(hex: 0x1F342A)) : (dark ? Color(hex: 0xEFF5FA) : Color(hex: 0x273B4C))
        let sub: Color = faith ? (dark ? Color(hex: 0xC2D3C6) : Color(hex: 0x506354)) : (dark ? Color(hex: 0xC4D3E0) : Color(hex: 0x526574))
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                Image.illustration(faith ? "faith-hands" : "purpose-compass").resizable().scaledToFit().frame(height: 134).frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
                Text(faith ? "Rooted in faith" : "Find your next step").font(.serif(23, relativeTo: .title3)).tracking(-0.3)
                    .foregroundStyle(ink).fixedSize(horizontal: false, vertical: true).padding(.top, 12)
                Text(faith ? "Find a little reassurance" : "Explore your purpose").font(.system(size: 11)).foregroundStyle(sub).padding(.top, 9)
                Image(systemName: "arrow.right").font(.system(size: 18)).foregroundStyle(ink).padding(.top, 15)
                Spacer(minLength: 0)
            }
            .multilineTextAlignment(.leading)
            .padding(EdgeInsets(top: 12, leading: 15, bottom: 20, trailing: 15))
            .frame(maxWidth: .infinity, minHeight: 287, alignment: .topLeading)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)))
            .shadow(color: Color(red: 25 / 255, green: 49 / 255, blue: 44 / 255, opacity: 0.19), radius: 6, y: 9)
        }
        .buttonStyle(.plain)
    }
}
