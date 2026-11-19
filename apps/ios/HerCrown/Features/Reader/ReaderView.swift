import SwiftUI

/// The Bible tab: one verse per page, swiped vertically, with the verse rail on the left and actions on the right.
struct ReaderView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @State private var model: ReaderModel
    @State private var showingChapters = false
    @State private var showingSaved = false
    @State private var showingBookmarks = false
    @State private var studyRef: VerseRef?
    @State private var reflectRef: VerseRef?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var chapterWindow: ReaderChapterWindow?
    @State private var visibleRef: String?

    init(app: AppModel) {
        let model = ReaderModel(app: app)
        _model = State(initialValue: model)
        _chapterWindow = State(initialValue: model.chapter.map { ReaderChapterWindow(chapter: $0) })
        _visibleRef = State(initialValue: model.currentRef?.description)
        #if DEBUG
        _showingChapters = State(initialValue: UserDefaults.standard.bool(forKey: "hcPreviewChapterPicker"))
        #endif
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            AppGradient()
            // .reader-pages: the top 670 pt of the 778 pt frame; the dock floats below.
            pages.padding(.bottom, 54).clipped()
            VerseRail(verses: model.verses.map(\.number), current: Binding(get: { model.current ?? 1 }, set: { verse in
                if let chapter = model.chapter { jump(to: VerseRef(book: chapter.book.id, chapter: chapter.number, verse: verse)) }
            }))
                .padding(.top, 94)
                .padding(.bottom, 65)
                .padding(.leading, 10)
        }
        .overlay {
            if model.loading || model.failure != nil {
                ZStack {
                    AppGradient()
                    VStack(spacing: 16) {
                        if model.loading {
                            ProgressView("Loading translation…")
                        }
                        else {
                            Text(model.failure ?? "Unable to load translation").font(.ui(14)).multilineTextAlignment(.center)
                            Button("Try again") { model.retry() }
                                .buttonStyle(CapsuleButtonStyle(kind: .secondary))
                            ScrollView { offlineTranslations }.frame(maxHeight: 340)
                        }
                    }
                    .foregroundStyle(Theme.text(scheme))
                    .tint(Theme.text(scheme))
                    .padding(32)
                }
            }
        }
        .overlay(alignment: .top) { toolbar }
        .sheet(isPresented: $showingChapters) {
            ChapterPicker(current: model.chapter) { book, number in jump(to: VerseRef(book: book, chapter: number, verse: 1)); showingChapters = false }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $studyRef) { ref in
            InsightsSheet(ref: ref, translation: model.translation) { r in jump(to: r) }
                .presentationDetents([.large])
        }
        .sheet(item: $reflectRef) { ref in
            ReflectionSheet(ref: ref, translation: model.translation).presentationDetents([.large])
        }
        .fullScreenCover(isPresented: $showingSaved) { SavedSheet(translation: model.translation) }
        .sheet(isPresented: $showingBookmarks) {
            ReaderBookmarks(current: model.currentRef) { ref in
                jump(to: ref)
                showingBookmarks = false
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: visibleRef) { _, value in
            guard let value, let ref = VerseRef(value) else { return }
            if model.chapter?.book.id != ref.book || model.chapter?.number != ref.chapter {
                model.open(ref.book, ref.chapter, verse: ref.verse)
            } else { model.current = ref.verse }
            model.didView(ref.verse)
            if let chapter = model.chapter { chapterWindow?.extend(around: chapter) }
        }
        .onChange(of: model.chapter.map { "\($0.translation).\($0.book.id).\($0.number)" }) { _, _ in
            guard let chapter = model.chapter, chapter.translation == model.translation, let ref = model.currentRef else { return }
            if chapterWindow?.chapters.first?.translation != chapter.translation || chapterWindow?.contains(ref) != true {
                chapterWindow = ReaderChapterWindow(chapter: chapter)
            }
            visibleRef = ref.description
        }
        .onChange(of: app.preferences.translation) { _, id in model.setTranslation(id) }
        .task(id: model.chapter.map { "\($0.translation).\($0.book.id).\($0.number)" }) {
            await model.prepareNeighbours()
            if !Task.isCancelled, let chapter = model.chapter { chapterWindow?.extend(around: chapter) }
        }
        .task(id: "\(model.pendingGuestPaywall?.uuidString ?? "")-\(canOfferGuestPaywall)") {
            guard canOfferGuestPaywall else { return }
            do { try await Task.sleep(for: .milliseconds(600)) } catch { return }
            guard !Task.isCancelled, canOfferGuestPaywall else { return }
            model.pendingGuestPaywall = nil
            // Reuse the already configured standard campaign; no new Superwall campaign is required.
            app.presentPaywall(placement: "onboarding_complete")
            await Analytics.shared.track("guest_chapter_paywall_requested")
        }
        .onChange(of: app.me?.user.id) { _, _ in model.pendingGuestPaywall = nil }
        #if DEBUG
        .task {
            guard let preview = UserDefaults.standard.string(forKey: "hcOpenStudy"), !preview.isEmpty else { return }
            try? await Task.sleep(for: .seconds(1))
            if preview == "reflection" { reflectRef = model.currentRef }
            else { studyRef = model.currentRef }
        }
        #endif
    }

    private var canOfferGuestPaywall: Bool {
        model.pendingGuestPaywall != nil && model.guestPaywallUserID != nil
            && model.guestPaywallUserID == app.me?.user.id
            && (model.guestPaywallQueuedAt.map { Date.now.timeIntervalSince($0) < 5 * 60 } ?? false)
            && app.onboardingCompleted && app.phase == .ready && !app.offline
            && scenePhase == .active && !app.checkingPaywall && !app.showExistingAppleSubscription
            && !showingChapters && !showingSaved && !showingBookmarks && studyRef == nil && reflectRef == nil
            && Billing.shared.configured && !Billing.shared.isPaywallBusy
            && GuestPaywallPrompter.shared.canRequest(isGuest: app.isGuest, premium: app.membership.premium)
    }

    private var offlineTranslations: some View {
        VStack(spacing: 12) {
            ForEach(BibleStore.offlineIDs, id: \.self) { id in
                Button { model.setTranslation(id) } label: {
                    HStack {
                        Text(BibleStore.names[id] ?? id.uppercased()).font(.ui(14, weight: .medium))
                        Spacer()
                        Text(BibleStore.offline[id] ?? id.uppercased()).font(.ui(11)).foregroundStyle(Theme.muted(scheme))
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .foregroundStyle(Theme.text(scheme))
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.canvas(scheme)))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.border(scheme), lineWidth: 1))
                    .contentShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Toolbar

    /// Keep the reader controls on the open canvas above the passage.
    private var toolbar: some View {
        HStack(spacing: 2) {
            HStack(spacing: 2) {
                Button { shuffle() } label: { Image.glyph("shuffle").frame(width: 19, height: 19).frame(width: 40, height: 44) }
                    .accessibilityLabel("Surprise me with a verse")
                Button { showingSaved = true } label: { Image.glyph("heart").frame(width: 19, height: 19).frame(width: 40, height: 44) }
                    .accessibilityLabel("Saved passages")
            }
            .padding(2)

            Menu {
                Picker("Translation", selection: Binding(get: { model.translation }, set: { model.setTranslation($0) })) {
                    Section("English") {
                        ForEach(BibleStore.translationIDs.filter { $0 != "rv1909" }, id: \.self) { id in
                            Text((BibleStore.names[id] ?? id) + (BibleStore.online[id] != nil ? " · online" : "")).tag(id)
                        }
                    }
                    Section("Español") { Text("Reina-Valera 1909 · offline").tag("rv1909") }
                }
            } label: {
                HStack(spacing: 4) { Text(BibleStore.offline[model.translation] ?? BibleStore.online[model.translation] ?? "KJV").font(.ui(16)); Image(systemName: "chevron.down").font(.system(size: 11, weight: .semibold)) }
                    .padding(.horizontal, 10).frame(height: 44)
            }
            .padding(.leading, 2)
            .accessibilityLabel("Bible translation, \(BibleStore.offline[model.translation] ?? BibleStore.online[model.translation] ?? "KJV")")
            Spacer()
            Button { showingBookmarks = true } label: {
                Group {
                    if let ref = model.currentRef, app.readerBookmarks.contains(ref.description) {
                        Image(systemName: "bookmark.fill").font(.system(size: 18))
                    } else { Image.glyph("bookmark").frame(width: 19, height: 19) }
                }
                .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Bookmarks")
            Button { showingChapters = true } label: {
                HStack(spacing: 4) { Text(model.chapter?.label ?? "Genesis 1").font(.ui(16)).lineLimit(1); Image(systemName: "chevron.down").font(.system(size: 11, weight: .semibold)) }
                    .padding(.horizontal, 10).frame(height: 44)
            }
            .accessibilityLabel("Chapter, \(model.chapter?.label ?? "")")
        }
        .foregroundStyle(Theme.text(scheme))
        .padding(.horizontal, 12)
        .padding(.top, 12)
    }

    // MARK: Pages

    private var pages: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(chapterWindow?.chapters ?? [], id: \.label) { chapter in
                    let next = ReaderChapterWindow.neighbourReference(of: chapter, direction: 1)
                    ForEach(chapter.verses) { verse in
                        let ref = VerseRef(book: chapter.book.id, chapter: chapter.number, verse: verse.number, end: verse.end)
                        VersePage(verse: verse, chapter: chapter, artwork: model.artwork(for: verse, in: chapter),
                                  isLast: verse.number == chapter.verses.last?.number, next: next.map { "\(BibleStore.shared.book($0.book)?.displayName ?? $0.book) \($0.chapter)" },
                                  onStudy: { studyRef = ref }, onReflect: { reflectRef = ref },
                                  onNext: {
                                      if let next { jump(to: next, animated: true) }
                                  })
                            .containerRelativeFrame(.vertical)
                            .id(ref.description)
                    }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $visibleRef)
        .scrollIndicators(.hidden)
    }

    private func jump(to ref: VerseRef, reset: Bool = false, animated: Bool = false) {
        model.open(ref.book, ref.chapter, verse: ref.verse)
        guard let chapter = model.chapter, chapter.translation == model.translation, chapter.book.id == ref.book, chapter.number == ref.chapter, let destination = model.currentRef else { return }
        if reset || chapterWindow?.contains(destination) != true {
            chapterWindow = ReaderChapterWindow(chapter: chapter)
        }
        withAnimation(animated && !reduceMotion ? .easeInOut(duration: 0.45) : nil) {
            visibleRef = destination.description
        }
    }

    private func shuffle() {
        Task {
            struct Random: Decodable { let ref: String }
            let ref: VerseRef? = (try? await app.api.get("/scripture/random?translation=\(model.translation)", as: Random.self)).flatMap { VerseRef($0.ref) }
            let fallback = ["PSA.23.1", "JHN.3.16", "PRO.3.5", "ISA.40.31", "MAT.11.28", "ROM.8.28", "PHP.4.7"].randomElement().flatMap(VerseRef.init)
            if let r = ref ?? fallback { jump(to: r) }
        }
    }
}

extension VerseRef: Identifiable { var id: String { description } }

/// One verse, centred, in Baskerville, with its reference and the action column.
struct VersePage: View {
    let verse: Verse
    let chapter: Chapter
    let artwork: String?
    let isLast: Bool
    let next: String?
    let onStudy: () -> Void
    let onReflect: () -> Void
    let onNext: () -> Void
    @Environment(AppModel.self) private var app
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var likePulse = 0
    @State private var showingLike = false

    private var ref: String { VerseRef(book: chapter.book.id, chapter: chapter.number, verse: verse.number, end: verse.end).description }
    private var reference: String { BibleStore.shared.label(VerseRef(book: chapter.book.id, chapter: chapter.number, verse: verse.number, end: verse.end), translation: chapter.translation) }
    private var fontSize: CGFloat { (ReaderFontSize(rawValue: app.preferences.fontSize) ?? .default).points }

    /// Center the Scripture and artwork between the toolbar and the bottom controls.
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                if let artwork {
                    Image.illustration(artwork).resizable().scaledToFit().frame(width: 112, height: 112).accessibilityHidden(true).padding(.bottom, 30)
                }
                if verse.number == chapter.verses.first?.number, let title = chapter.title {
                    Text(title).font(.serif(17, italic: true, relativeTo: .callout)).foregroundStyle(Theme.muted(scheme)).multilineTextAlignment(.center).padding(.bottom, 16)
                }
                Text(scripture)
                    .font(.serif(fontSize, relativeTo: .title))
                    .tracking(-0.4)
                    .lineSpacing(fontSize * 0.17)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(Theme.text(scheme))
                Text(reference)
                    .font(.ui(13)).foregroundStyle(Theme.muted(scheme)).padding(.top, 30)
                if BibleStore.online[chapter.translation] != nil {
                    Text("\(chapter.translation.uppercased()) ©").font(.system(size: 9))
                        .foregroundStyle(Theme.muted(scheme)).padding(.top, 6)
                        .accessibilityLabel("\(BibleStore.names[chapter.translation] ?? chapter.translation). Copyright details in Settings, Credits and Licenses.")
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: 350)
            .padding(EdgeInsets(top: 100, leading: 44, bottom: 116, trailing: 44))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) { likeVerse() }
            .overlay {
                if showingLike || previewLikeAnimation {
                    VerseLikeBloom(reduceMotion: reduceMotion, holdForPreview: previewLikeAnimation)
                        .id(likePulse)
                        .accessibilityHidden(true)
                        .allowsHitTesting(false)
                }
            }

            VStack(spacing: 3) {
                Button(action: onStudy) { Image.glyph("insights").frame(width: 21, height: 21).frame(width: 44, height: 44).contentShape(Rectangle()) }
                    .accessibilityLabel("Insights for \(chapter.book.displayName) \(chapter.number):\(verse.number)")
                Button {
                    if app.isSaved(ref) { app.toggleSave(ref) }
                    else { likeVerse() }
                } label: {
                    Group {
                        if app.isSaved(ref) { Image(systemName: "heart.fill").font(.system(size: 19)).foregroundStyle(Color(red: 0.91, green: 0.16, blue: 0.28)) }
                        else { Image.glyph("heart").frame(width: 20, height: 20) }
                    }.frame(width: 44, height: 44).contentShape(Rectangle())
                }
                    .accessibilityLabel(app.isSaved(ref) ? "Unsave" : "Save")
                Button(action: onReflect) { Image.glyph("message").frame(width: 20, height: 20).frame(width: 44, height: 44).contentShape(Rectangle()) }
                    .accessibilityLabel("Reflect")
                VerseShareButton(text: verse.text,
                                 reference: reference,
                                 translation: chapter.translation, copyright: chapter.copyright)
            }
            .foregroundStyle(Theme.text(scheme))
            .padding(.trailing, 12)
            .padding(.bottom, 62)

            HStack(spacing: 10) {
                if isLast, let next {
                    Button(action: onNext) {
                        HStack(spacing: 10) {
                            Text("Swipe up · Next: \(next)").font(.system(size: 11))
                            Text("↓").font(.system(size: 14)).accessibilityHidden(true)
                        }
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, -14)
                } else {
                    Text(isLast ? "End of chapter" : "Scroll for the next verse").font(.system(size: 11))
                    if !isLast { Text("↓").font(.system(size: 14)).accessibilityHidden(true) }
                }
            }
            .foregroundStyle(Theme.muted(scheme))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 44)
            .padding(.bottom, 24)
        }
        .task(id: likePulse) {
            guard likePulse > 0 else { return }
            showingLike = true
            do { try await Task.sleep(for: .milliseconds(1400)) } catch { return }
            showingLike = false
        }
        .onDisappear { showingLike = false }
    }

    private var previewLikeAnimation: Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: "hcPreviewLikeAnimation")
        #else
        false
        #endif
    }

    /// Double-tapping confirms a like; it never removes an already saved passage.
    private func likeVerse() {
        if !app.isSaved(ref) { app.toggleSave(ref) }
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.5)
        likePulse += 1
    }

    /// Words of Jesus in red when the setting is on.
    private var scripture: AttributedString {
        let ns = NSMutableAttributedString(string: verse.text)
        if app.preferences.wordsOfJesusInRed {
            let red = scheme == .dark ? Theme.wordsOfJesusDark : Theme.wordsOfJesus
            for range in verse.wordsOfJesus where NSMaxRange(range) <= ns.length {
                ns.addAttribute(.foregroundColor, value: UIColor(red), range: range)
            }
        }
        return (try? AttributedString(ns, including: \.uiKit)) ?? AttributedString(verse.text)
    }
}

/// A red heart blooms, then drifts upward and fades.
private struct VerseLikeBloom: View {
    let reduceMotion: Bool
    let holdForPreview: Bool
    @State private var bloomed = false
    @State private var departing = false
    private let red = Color(red: 0.91, green: 0.16, blue: 0.28)

    var body: some View {
        ZStack {
            Image(systemName: "heart.fill")
                .font(.system(size: 78))
                .foregroundStyle(LinearGradient(colors: [Color(red: 1, green: 0.36, blue: 0.43), red], startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: red.opacity(0.22), radius: 16, y: 6)
                .scaleEffect(bloomed ? 1 : 0.25)
                .rotationEffect(.degrees(bloomed ? -8 : -20))
        }
        .scaleEffect(departing && !reduceMotion ? 0.65 : 1)
        .offset(x: departing && !reduceMotion ? 32 : 0, y: departing && !reduceMotion ? -90 : 0)
        .opacity(departing ? 0 : 1)
        .task {
            withAnimation(reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.55)) { bloomed = true }
            guard !holdForPreview else { return }
            do { try await Task.sleep(for: .milliseconds(650)) } catch { return }
            withAnimation(.easeInOut(duration: 0.65)) { departing = true }
        }
    }
}

private struct ReaderBookmarks: View {
    @Environment(AppModel.self) private var app
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    let current: VerseRef?
    let open: (VerseRef) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let current {
                        let saved = app.readerBookmarks.contains(current.description)
                        VStack(alignment: .leading, spacing: 12) {
                            caption("Current position")
                            Text(title(current)).font(.serif(28, relativeTo: .title))
                            Button {
                                app.toggleBookmark(current.description)
                            } label: {
                                Label(saved ? "Remove Bookmark" : "Bookmark This Verse", systemImage: saved ? "bookmark.fill" : "bookmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .frame(maxWidth: .infinity, minHeight: 50)
                                    .foregroundStyle(scheme == .dark ? .black : .white)
                                    .background(Theme.text(scheme), in: RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(16)
                        .background(Theme.surface(scheme), in: RoundedRectangle(cornerRadius: 22))
                    }
                    caption("Saved")
                    if app.readerBookmarks.isEmpty {
                        Text("Bookmarked verses will appear here.").font(.subheadline)
                            .foregroundStyle(Theme.muted(scheme))
                    }
                    ForEach(app.readerBookmarks.compactMap { VerseRef($0) }, id: \.self) { ref in
                        HStack {
                            Button { open(ref) } label: {
                                Label(title(ref), systemImage: "bookmark.fill")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .frame(minHeight: 44)
                                    .contentShape(Rectangle())
                            }
                            Button { app.toggleBookmark(ref.description) } label: {
                                Image(systemName: "trash").frame(width: 44, height: 44)
                                    .foregroundStyle(Theme.muted(scheme))
                            }
                            .accessibilityLabel("Remove bookmark for \(title(ref))")
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)
                        .background(Theme.surface(scheme), in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(16)
            }
            .foregroundStyle(Theme.text(scheme))
            .background(AppGradient())
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func caption(_ text: String) -> some View {
        Text(text.uppercased()).font(.system(size: 12, weight: .semibold)).tracking(1)
            .foregroundStyle(Theme.muted(scheme))
    }

    private func title(_ ref: VerseRef) -> String {
        let book = BibleStore.shared.book(ref.book)?.displayName ?? ref.book
        let range = ref.end.map { "–\($0)" } ?? ""
        return "\(book) \(ref.chapter):\(ref.verse)\(range)"
    }
}
