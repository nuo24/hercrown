import SwiftUI

/// The Bible tab: one verse per page, swiped vertically, with the verse rail on the left and actions on the right.
struct ReaderView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.colorScheme) private var scheme
    @State private var model: ReaderModel
    @State private var showingChapters = false
    @State private var showingSaved = false
    @State private var showingBookmarks = false
    @State private var studyRef: VerseRef?
    @State private var reflectRef: VerseRef?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragging = false
    @State private var dragBeganAtEnd = false
    @State private var nextChapterRequest: VerseRef?

    init(app: AppModel) {
        _model = State(initialValue: ReaderModel(app: app))
        #if DEBUG
        _showingChapters = State(initialValue: UserDefaults.standard.bool(forKey: "hcPreviewChapterPicker"))
        #endif
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            AppGradient()
            // .reader-pages: the top 670 pt of the 778 pt frame; the dock floats below.
            pages.padding(.bottom, 54)
            VerseRail(verses: model.verses.map(\.number), current: Binding(get: { model.current ?? 1 }, set: { model.current = $0 }))
                .padding(.top, 94)
                .padding(.bottom, 65)
                .padding(.leading, 10)
            toolbar
        }
        .sheet(isPresented: $showingChapters) {
            ChapterPicker(current: model.chapter) { book, number in model.open(book, number); showingChapters = false }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $studyRef) { ref in
            InsightsSheet(ref: ref, translation: model.translation) { r in model.open(r.book, r.chapter, verse: r.verse) }
                .presentationDetents([.large])
        }
        .sheet(item: $reflectRef) { ref in
            ReflectionSheet(ref: ref, translation: model.translation).presentationDetents([.large])
        }
        .sheet(isPresented: $showingSaved) { SavedSheet(translation: model.translation) }
        .sheet(isPresented: $showingBookmarks) {
            ReaderBookmarks(current: model.currentRef) { ref in
                model.open(ref.book, ref.chapter, verse: ref.verse)
                showingBookmarks = false
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: model.current) { _, verse in model.didView(verse) }
        .task(id: nextChapterRequest) {
            guard let source = nextChapterRequest else { return }
            do { try await Task.sleep(for: .milliseconds(450)) } catch { return }
            guard model.currentRef == source, let next = model.nextChapter else {
                nextChapterRequest = nil
                return
            }
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.7)) {
                model.open(next.0, next.1)
            }
            nextChapterRequest = nil
        }
        .onDisappear { nextChapterRequest = nil }
        #if DEBUG
        .task {
            guard let preview = UserDefaults.standard.string(forKey: "hcOpenStudy") else { return }
            try? await Task.sleep(for: .seconds(1))
            if preview == "reflection" { reflectRef = model.currentRef }
            else { studyRef = model.currentRef }
        }
        #endif
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
                    Text("King James Version (KJV)").tag("kjv")
                    Text("Berean Standard Bible (BSB)").tag("bsb")
                    Text("World English Bible (WEB)").tag("web")
                }
            } label: {
                HStack(spacing: 4) { Text(BibleStore.offline[model.translation] ?? "KJV").font(.ui(16)); Image(systemName: "chevron.down").font(.system(size: 11, weight: .semibold)) }
                    .padding(.horizontal, 10).frame(height: 44)
            }
            .padding(.leading, 2)
            .accessibilityLabel("Bible translation, \(BibleStore.offline[model.translation] ?? "KJV")")
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
                ForEach(model.verses) { verse in
                    VersePage(verse: verse, chapter: model.chapter!, artwork: model.artwork(for: verse), isLast: verse.number == model.verses.last?.number,
                              next: model.nextChapter.flatMap { n in BibleStore.shared.book(n.0).map { "\($0.displayName) \(n.1)" } },
                              onStudy: { studyRef = ref(verse) }, onReflect: { reflectRef = ref(verse) },
                              onNext: { if let n = model.nextChapter { model.open(n.0, n.1) } })
                        .containerRelativeFrame(.vertical)
                        .id(verse.number)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: Binding(get: { model.current }, set: { model.current = $0 }))
        .scrollIndicators(.hidden)
        .id("\(model.translation)-\(model.chapter?.book.id ?? "")-\(model.chapter?.number ?? 0)")
        .transition(reduceMotion ? .identity : .push(from: .bottom))
        .simultaneousGesture(DragGesture(minimumDistance: 24)
            .onChanged { _ in
                if !dragging {
                    dragging = true
                    dragBeganAtEnd = model.current == model.verses.last?.number
                }
            }
            .onEnded { drag in
                dragging = false
                if dragBeganAtEnd, drag.translation.height < -80,
                   abs(drag.translation.width) < abs(drag.translation.height), model.nextChapter != nil {
                    nextChapterRequest = model.currentRef
                }
                dragBeganAtEnd = false
            })
    }

    private func ref(_ verse: Verse) -> VerseRef { VerseRef(book: model.chapter!.book.id, chapter: model.chapter!.number, verse: verse.number) }

    private func shuffle() {
        Task {
            struct Random: Decodable { let ref: String }
            let ref: VerseRef? = (try? await app.api.get("/scripture/random?translation=\(model.translation)", as: Random.self)).flatMap { VerseRef($0.ref) }
            let fallback = ["PSA.23.1", "JHN.3.16", "PRO.3.5", "ISA.40.31", "MAT.11.28", "ROM.8.28", "PHP.4.7"].randomElement().flatMap(VerseRef.init)
            if let r = ref ?? fallback { model.open(r.book, r.chapter, verse: r.verse) }
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

    private var ref: String { "\(chapter.book.id).\(chapter.number).\(verse.number)" }
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
                Text("\(chapter.book.displayName) \(chapter.number):\(verse.number)")
                    .font(.ui(13)).foregroundStyle(Theme.muted(scheme)).padding(.top, 30)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: 350)
            .padding(EdgeInsets(top: 100, leading: 44, bottom: 116, trailing: 44))
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 3) {
                Button(action: onStudy) { Image.glyph("insights").frame(width: 21, height: 21).frame(width: 44, height: 44).contentShape(Rectangle()) }
                    .accessibilityLabel("Insights for \(chapter.book.displayName) \(chapter.number):\(verse.number)")
                Button { app.toggleSave(ref) } label: {
                    Group {
                        if app.isSaved(ref) { Image(systemName: "heart.fill").font(.system(size: 19)) }
                        else { Image.glyph("heart").frame(width: 20, height: 20) }
                    }.frame(width: 44, height: 44).contentShape(Rectangle())
                }
                    .accessibilityLabel(app.isSaved(ref) ? "Unsave" : "Save")
                Button(action: onReflect) { Image.glyph("message").frame(width: 20, height: 20).frame(width: 44, height: 44).contentShape(Rectangle()) }
                    .accessibilityLabel("Reflect")
                VerseShareButton(text: verse.text,
                                 reference: "\(chapter.book.displayName) \(chapter.number):\(verse.number)",
                                 translation: chapter.translation)
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
