import SwiftUI

/// The Bible tab: one verse per page, swiped vertically, with the verse rail on the left and actions on the right.
struct ReaderView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.colorScheme) private var scheme
    @State private var model: ReaderModel
    @State private var showingChapters = false
    @State private var showingSaved = false
    @State private var studyRef: VerseRef?
    @State private var reflectRef: VerseRef?

    init(app: AppModel) { _model = State(initialValue: ReaderModel(app: app)) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            AppGradient()
            // .reader-pages: the top 670 pt of the 778 pt frame; the dock floats below.
            pages.padding(.bottom, 108)
            VerseRail(verses: model.verses.map(\.number), current: Binding(get: { model.current ?? 1 }, set: { model.current = $0 }))
                .padding(.top, 94)
                .padding(.bottom, 108)
                .padding(.leading, 10)
            toolbar
        }
        .sheet(isPresented: $showingChapters) {
            ChapterPicker(current: model.chapter) { book, number in model.open(book, number); showingChapters = false }
                .presentationDetents([.large])
        }
        .sheet(item: $studyRef) { ref in
            InsightsSheet(ref: ref, translation: model.translation) { r in model.open(r.book, r.chapter, verse: r.verse) }
                .presentationDetents([.large])
        }
        .sheet(item: $reflectRef) { ref in
            ReflectionSheet(ref: ref, translation: model.translation).presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingSaved) { SavedSheet(translation: model.translation) }
        .onChange(of: model.current) { _, verse in model.didView(verse) }
        #if DEBUG
        .task { if UserDefaults.standard.string(forKey: "hcOpenStudy") != nil { try? await Task.sleep(for: .seconds(1)); studyRef = model.currentRef } }
        #endif
    }

    // MARK: Toolbar

    /// .reader-toolbar: 12 pt from the edges; white pill controls with the icon-button surface; 16 pt labels.
    private var toolbar: some View {
        HStack(spacing: 2) {
            HStack(spacing: 2) {
                Button { shuffle() } label: { Image(systemName: "shuffle").font(.system(size: 16)).frame(width: 40, height: 44) }
                    .accessibilityLabel("Surprise me with a verse")
                Button { showingSaved = true } label: { Image(systemName: "heart").font(.system(size: 16)).frame(width: 40, height: 44) }
                    .accessibilityLabel("Saved passages")
            }
            .padding(2)
            .iconSurface(Capsule())
            Menu {
                Picker("Translation", selection: Binding(get: { model.translation }, set: { model.setTranslation($0) })) {
                    Text("King James Version (KJV)").tag("kjv")
                    Text("Berean Standard Bible (BSB)").tag("bsb")
                    Text("World English Bible (WEB)").tag("web")
                }
            } label: {
                HStack(spacing: 4) { Text(BibleStore.offline[model.translation] ?? "KJV").font(.system(size: 16)); Image(systemName: "chevron.down").font(.system(size: 11, weight: .semibold)) }
                    .padding(.horizontal, 10).frame(height: 44).iconSurface(Capsule())
            }
            .padding(.leading, 2)
            .accessibilityLabel("Bible translation, \(BibleStore.offline[model.translation] ?? "KJV")")
            Spacer()
            Button { if let ref = model.currentRef { app.toggleSave(ref.description) } } label: {
                Image(systemName: model.currentRef.map { app.isSaved($0.description) } == true ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 16)).frame(width: 40, height: 44).iconSurface(Capsule())
            }
            .accessibilityLabel("Save current verse")
            Button { showingChapters = true } label: {
                HStack(spacing: 4) { Text(model.chapter?.label ?? "Genesis 1").font(.system(size: 16)).lineLimit(1); Image(systemName: "chevron.down").font(.system(size: 11, weight: .semibold)) }
                    .padding(.horizontal, 10).frame(height: 44).iconSurface(Capsule())
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

    /// .reader-page: 100/44/116 padding, verse block centred (112 pt art, 30 pt serif, 13 pt reference); side actions
    /// 12 pt from the right and 62 pt above the page bottom; the hint 24 pt above it.
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                if let artwork {
                    Image(artwork).resizable().scaledToFit().frame(width: 112, height: 112).accessibilityHidden(true).padding(.bottom, 30)
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
                    .font(.system(size: 13)).foregroundStyle(Theme.muted(scheme)).padding(.top, 24)
                Spacer(minLength: 0)
            }
            .padding(EdgeInsets(top: 100, leading: 44, bottom: 116, trailing: 44))
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 8) {
                Button(action: onStudy) { InsightLens().stroke(style: StrokeStyle(lineWidth: 1.65, lineCap: .round, lineJoin: .round)).frame(width: 25, height: 25).frame(width: 44, height: 44) }
                    .accessibilityLabel("Insights for \(chapter.book.displayName) \(chapter.number):\(verse.number)")
                Button { app.toggleSave(ref) } label: { Image(systemName: app.isSaved(ref) ? "heart.fill" : "heart").font(.system(size: 21)).frame(width: 44, height: 44) }
                    .accessibilityLabel(app.isSaved(ref) ? "Unsave" : "Save")
                Button(action: onReflect) { Image(systemName: "bubble.left").font(.system(size: 20)).frame(width: 44, height: 44) }
                    .accessibilityLabel("Reflect")
                ShareLink(item: "“\(verse.text)” — \(chapter.book.displayName) \(chapter.number):\(verse.number) (\(BibleStore.offline[chapter.translation] ?? "KJV"))") {
                    Image(systemName: "square.and.arrow.up").font(.system(size: 20)).frame(width: 44, height: 44)
                }
                .accessibilityLabel("Share")
            }
            .foregroundStyle(Theme.text(scheme))
            .padding(.trailing, 12)
            .padding(.bottom, 62)

            HStack(spacing: 10) {
                if isLast, let next {
                    Button(action: onNext) {
                        HStack(spacing: 6) { Text("Next: \(next)"); Image(systemName: "arrow.right") }
                            .font(.system(size: 13)).padding(.horizontal, 16).frame(height: 40)
                            .iconSurface(Capsule())
                    }
                } else if !isLast {
                    Text("Scroll for the next verse").font(.system(size: 11)); Text("↓").font(.system(size: 14))
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
