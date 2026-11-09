import SwiftUI

// Her library (docs/api.md "Saved / library"): saved verses, notes, saved studies and verses studied.

private struct NoteItem: Decodable, Identifiable { let ref: String; let label: String; let verse: String?; let text: String; let updatedAt: Double; var id: String { ref } }
private struct StudyItem: Decodable, Identifiable { let ref: String; let label: String; let verse: String?; let tool: String; let savedAt: Double; var id: String { ref + tool } }
private struct StudiedItem: Decodable, Identifiable { let ref: String; let label: String; let verse: String?; let tools: [String]; let lastStudiedAt: Double; var id: String { ref } }
private struct LibraryStudyRoute: Hashable { let ref: VerseRef; let tool: StudyTool }
private struct LibraryCounts: Decodable { let savedVerses: Int; let notes: Int; let studies: Int; let studied: Int }

/// saved: "Saved passages · Words to keep close." One collection shared by the reader, Home and Discover.
struct SavedSheet: View {
    let translation: String
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    enum Section: String, CaseIterable, Identifiable { case verses = "Verses", notes = "Notes", studies = "Studies", studied = "Studied"; var id: String { rawValue } }
    @State private var section: Section = .verses
    @State private var order: [String] = []
    @State private var notes: [NoteItem]?
    @State private var studies: [StudyItem]?
    @State private var studied: [StudiedItem]?
    @State private var counts: LibraryCounts?
    @State private var studyRef: VerseRef?
    @State private var openStudy: LibraryStudyRoute?
    @State private var noteRef: VerseRef?
    @AppStorage(DiscoverStudied.storageKey) private var studiedData = Data()

    private var discoverStudied: [String] {
        DiscoverStudied.byAccount(studiedData)[DiscoverStudied.accountKey(app.me?.user.id)] ?? []
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.canvas(scheme)
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 18) {
                            Button { dismiss() } label: { Image(systemName: "arrow.left").frame(width: 24, height: 44) }
                            Text("Saved passages").font(.serif(28)).tracking(-0.5)
                            Spacer()
                            Button("Done") { dismiss() }.font(.ui(12, weight: .medium))
                        }.buttonStyle(.plain).padding(.horizontal, 22)
                        Text("Words to keep close.").font(.ui(14)).foregroundStyle(Theme.muted(scheme))
                            .padding(.horizontal, 20).padding(.vertical, 18)
                        sectionChips.padding(.bottom, 16)
                        VStack(spacing: 16) { content }.padding(.horizontal, 20)
                    }
                    .foregroundStyle(Theme.text(scheme))
                    .padding(.bottom, 40)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $openStudy) { route in
                AIStudyView(ref: route.ref, translation: translation, tool: route.tool)
                    .toolbar(.visible, for: .navigationBar)
            }
        }
        .sheet(item: $studyRef) { ref in
            InsightsSheet(ref: ref, translation: translation) { r in dismiss(); app.openInReader(r) }.presentationDetents([.large])
        }
        .sheet(item: $noteRef) { ref in
            ReflectionSheet(ref: ref, translation: translation, notesOnly: true)
                .presentationDetents([.large])
        }
        .task { await load() }
        .task(id: section) { await loadSection() }
    }

    /// Sections as the mockup's filter chips (44 pt, 13 pt, ink when selected).
    private var sectionChips: some View {
        HStack(spacing: 4) {
            ForEach(Section.allCases) { item in
                Button { section = item } label: {
                    VStack(spacing: 3) {
                        Text(item.rawValue).font(.ui(12, weight: .medium))
                        Text(count(item).formatted()).font(.ui(10))
                    }.frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(item == section ? Theme.text(scheme) : Theme.muted(scheme))
                        .background(item == section ? Theme.surface(scheme) : .clear, in: RoundedRectangle(cornerRadius: 9))
                }.buttonStyle(.plain).accessibilityAddTraits(item == section ? .isSelected : [])
            }
        }.padding(4).background(Theme.supporting(scheme), in: RoundedRectangle(cornerRadius: 12)).padding(.horizontal, 20).padding(.vertical, 8)
    }

    private func count(_ section: Section) -> Int {
        switch section {
        case .verses: app.saved.count
        case .notes: counts?.notes ?? notes?.count ?? 0
        case .studies: counts?.studies ?? studies?.count ?? 0
        case .studied: max(counts?.studied ?? studied?.count ?? 0, discoverStudied.count)
        }
    }

    private func title(_ s: Section) -> String {
        guard let counts else { return s.rawValue }
        let n = switch s { case .verses: app.saved.count; case .notes: counts.notes; case .studies: counts.studies; case .studied: counts.studied }
        return n > 0 ? "\(s.rawValue) \(n)" : s.rawValue
    }

    private func load() async {
        counts = try? await app.api.get("/me/library")
        struct SavedList: Decodable { struct Item: Decodable { let ref: String }; let saved: [Item] }
        if let list: SavedList = try? await app.api.get("/me/saved") { order = list.saved.map(\.ref) }
        await Analytics.shared.track("library_viewed")
    }

    private func loadSection() async {
        struct Notes: Decodable { let notes: [NoteItem] }
        struct Studies: Decodable { let studies: [StudyItem] }
        struct Studied: Decodable { let studied: [StudiedItem] }
        switch section {
        case .verses: break
        case .notes: if let r: Notes = try? await app.api.get("/me/notes") { notes = r.notes } else if notes == nil { notes = [] }
        case .studies: if let r: Studies = try? await app.api.get("/me/studies") { studies = r.studies } else if studies == nil { studies = [] }
        case .studied: if let r: Studied = try? await app.api.get("/me/studied") { studied = r.studied } else if studied == nil { studied = [] }
        }
    }

    // MARK: Sections

    @ViewBuilder private var content: some View {
        switch section {
        case .verses:
            // Newest first from the server, then anything saved on this phone that hasn't synced yet.
            let refs = order.filter { app.saved.contains($0) } + app.saved.subtracting(order).sorted()
            if refs.isEmpty {
                empty("Your saved passages will find a home here.", "Tap the heart on a verse to keep it close.")
            } else {
                ForEach(refs, id: \.self) { ref in
                    if let verse = VerseRef(ref) {
                        SavedVerseCard(ref: verse, translation: translation,
                                       onNotes: { noteRef = verse },
                                       onReadAndReflect: { studyRef = verse })
                    }
                }
            }
        case .notes:
            if let notes {
                if notes.isEmpty { empty("Your notes will gather here.", "Add a note when you reflect on a verse.") }
                else { ForEach(notes) { n in row(n.label, n.verse, detail: n.text) { if let r = VerseRef(n.ref) { dismiss(); app.openInReader(r) } } } }
            } else { ProgressView().frame(maxWidth: .infinity).padding(40) }
        case .studies:
            if let studies {
                if studies.isEmpty { empty("Studies you save will live here.", "Tap the bookmark on Explain easier or Deeper study.") }
                else {
                    ForEach(studies) { study in
                        let tool = StudyTool(rawValue: study.tool)
                        row(study.label, study.verse, detail: tool?.title ?? study.tool) {
                            if let ref = VerseRef(study.ref), let tool { openStudy = LibraryStudyRoute(ref: ref, tool: tool) }
                        }
                    }
                }
            } else { ProgressView().frame(maxWidth: .infinity).padding(40) }
        case .studied:
            let discoverRefs = discoverStudied.reversed().compactMap { VerseRef($0) }
            if discoverRefs.isEmpty && studied == nil {
                ProgressView().frame(maxWidth: .infinity).padding(40)
            } else if discoverRefs.isEmpty && studied?.isEmpty == true {
                empty("Verses you study will show here.", "Tap the lens beside any verse to begin.")
            } else {
                ForEach(discoverRefs, id: \.self) { ref in
                    VStack(alignment: .trailing, spacing: 4) {
                        row(BibleStore.shared.label(ref), BibleStore.shared.text(translation, ref), detail: "Deeper study") {
                            openStudy = LibraryStudyRoute(ref: ref, tool: .deeper)
                        }
                        Button { noteRef = ref } label: {
                            Label("Verse notes", systemImage: "message")
                                .font(.system(size: 13)).frame(minHeight: 44).padding(.horizontal, 12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                ForEach((studied ?? []).filter { !discoverStudied.contains($0.ref) }) { s in
                    row(s.label, s.verse, detail: s.tools.compactMap { StudyTool(rawValue: $0)?.title }.joined(separator: " · ")) {
                        studyRef = VerseRef(s.ref)
                    }
                }
            }
        }
    }

    private func empty(_ title: String, _ hint: String) -> some View {
        VStack(spacing: 12) {
            Image.illustration("bookmark").resizable().scaledToFit().frame(height: 110).accessibilityHidden(true)
            Text(title).font(.serif(21))
            Text(hint).font(.system(size: 15)).foregroundStyle(Theme.muted(scheme))
        }
        .multilineTextAlignment(.center).frame(maxWidth: .infinity).padding(.vertical, 36)
        .foregroundStyle(Theme.text(scheme))
    }

    private func row(_ label: String, _ verse: String?, detail: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Card {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(label).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.muted(scheme))
                        if let verse {
                            Text(verse).font(.serif(19)).lineLimit(3).multilineTextAlignment(.leading)
                            Text(translation.uppercased() + (BibleStore.online[translation] == nil ? "" : " ©")).font(.system(size: 9)).foregroundStyle(.secondary)
                        }
                        Text(detail).font(.system(size: 15)).lineLimit(4).multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(.tertiary)
                }
                .foregroundStyle(Theme.text(scheme))
            }
        }
        .buttonStyle(.plain)
    }
}

private struct SavedVerseCard: View {
    let ref: VerseRef
    let translation: String
    let onNotes: () -> Void
    let onReadAndReflect: () -> Void
    @Environment(AppModel.self) private var app
    @Environment(\.colorScheme) private var scheme

    /// The saved .verse-card: 22/20/14 padding; 24 pt serif reference, 28 pt serif verse, translation; a full-width
    /// Read & reflect, then the actions centred under a hairline.
    var body: some View {
        let text = BibleStore.shared.text(translation, ref) ?? ""
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 16) {
                Image.illustration("olive").resizable().scaledToFit().frame(width: 60, height: 64).accessibilityHidden(true)
                ScriptureReference(ref: ref, translation: translation).font(.ui(14, weight: .semibold))
            }
            ScriptureText(text: text, reference: ref.description, translation: translation)
                .font(.serif(25, relativeTo: .title2)).lineSpacing(3).fixedSize(horizontal: false, vertical: true)
            HStack {
                Button("Read & reflect", action: onReadAndReflect)
                Spacer()
                Button("Remove") { app.toggleSave(ref.description) }
            }.font(.ui(12, weight: .medium)).frame(minHeight: 44).buttonStyle(.plain)
        }.padding(22).frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(Theme.text(scheme)).background(Theme.surface(scheme), in: RoundedRectangle(cornerRadius: 16))

    }
}
