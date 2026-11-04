import SwiftUI

// Her library (docs/api.md "Saved / library"): saved verses, notes, saved studies and verses studied.

private struct NoteItem: Decodable, Identifiable { let ref: String; let label: String; let verse: String?; let text: String; let updatedAt: Double; var id: String { ref } }
private struct StudyItem: Decodable, Identifiable { let ref: String; let label: String; let verse: String?; let tool: String; let savedAt: Double; var id: String { ref + tool } }
private struct StudiedItem: Decodable, Identifiable { let ref: String; let label: String; let verse: String?; let tools: [String]; let lastStudiedAt: Double; var id: String { ref } }
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
    @State private var openStudy: StudyItem?

    var body: some View {
        NavigationStack {
            ZStack {
                AppGradient()
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // .app-header: 28 pt title; a close button where the mockup has its icon buttons.
                        HStack {
                            Text("Saved passages").font(.system(size: 28)).tracking(-0.8)
                            Spacer()
                            IconButton(systemName: "xmark", label: "Close") { dismiss() }
                        }
                        .padding(EdgeInsets(top: 20, leading: 20, bottom: 16, trailing: 20))
                        Text("Words to keep close.").font(.system(size: 14)).foregroundStyle(Theme.muted(scheme)).padding(.horizontal, 20)
                        // .saved-illustration-banner: 56×64 ribbon, 13 pt caption, 0/24/22 padding.
                        HStack(spacing: 14) {
                            Image("bookmark").resizable().scaledToFit().frame(width: 56, height: 64).accessibilityHidden(true)
                            Text("Your collected passages").font(.system(size: 13)).foregroundStyle(Theme.muted(scheme))
                        }
                        .padding(EdgeInsets(top: 20, leading: 24, bottom: 22, trailing: 24))
                        sectionChips.padding(.bottom, 16)
                        VStack(spacing: 16) { content }.padding(.horizontal, 20)
                    }
                    .foregroundStyle(Theme.text(scheme))
                    .padding(.bottom, 40)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $openStudy) { item in
                if let ref = VerseRef(item.ref), let tool = StudyTool(rawValue: item.tool) {
                    AIStudyView(ref: ref, translation: translation, tool: tool).navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .sheet(item: $studyRef) { ref in
            InsightsSheet(ref: ref, translation: translation) { r in dismiss(); app.openInReader(r) }.presentationDetents([.large])
        }
        .task { await load() }
        .task(id: section) { await loadSection() }
    }

    /// Sections as the mockup's filter chips (44 pt, 13 pt, ink when selected).
    private var sectionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Section.allCases) { s in
                    let on = s == section
                    Button { section = s } label: {
                        Text(title(s)).font(.system(size: 13)).padding(.horizontal, 14).frame(height: 44)
                            .foregroundStyle(on ? (scheme == .dark ? Color(hex: 0x080809) : Color(hex: 0xF7F7F9)) : Theme.text(scheme))
                            .background(Capsule().fill(on ? Theme.text(scheme) : (scheme == .dark ? Color(hex: 0x080809) : Color(hex: 0xF7F7F9))))
                            .overlay(Capsule().strokeBorder(on ? .clear : Theme.border(scheme), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
            .padding(.horizontal, 20)
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
                ForEach(refs, id: \.self) { ref in if let r = VerseRef(ref) { SavedVerseCard(ref: r, translation: translation, onStudy: { studyRef = r }, onRead: { dismiss(); app.openInReader(r) }) } }
            }
        case .notes:
            if let notes {
                if notes.isEmpty { empty("Your notes will gather here.", "Add a note when you reflect on a verse.") }
                else { ForEach(notes) { n in row(n.label, n.verse, detail: n.text) { if let r = VerseRef(n.ref) { dismiss(); app.openInReader(r) } } } }
            } else { ProgressView().frame(maxWidth: .infinity).padding(40) }
        case .studies:
            if let studies {
                if studies.isEmpty { empty("Studies you save will live here.", "Tap the bookmark on Explain easier or Deeper study.") }
                else { ForEach(studies) { s in row(s.label, s.verse, detail: StudyTool(rawValue: s.tool)?.title ?? s.tool) { openStudy = s } } }
            } else { ProgressView().frame(maxWidth: .infinity).padding(40) }
        case .studied:
            if let studied {
                if studied.isEmpty { empty("Verses you study will show here.", "Tap the lens beside any verse to begin.") }
                else { ForEach(studied) { s in row(s.label, s.verse, detail: s.tools.compactMap { StudyTool(rawValue: $0)?.title }.joined(separator: " · ")) { studyRef = VerseRef(s.ref) } } }
            } else { ProgressView().frame(maxWidth: .infinity).padding(40) }
        }
    }

    private func empty(_ title: String, _ hint: String) -> some View {
        VStack(spacing: 12) {
            Image("bookmark").resizable().scaledToFit().frame(height: 110).accessibilityHidden(true)
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
                        if let verse { Text(verse).font(.serif(19)).lineLimit(3).multilineTextAlignment(.leading) }
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

extension StudyItem: Hashable {
    static func == (a: StudyItem, b: StudyItem) -> Bool { a.id == b.id }
    func hash(into h: inout Hasher) { h.combine(id) }
}

private struct SavedVerseCard: View {
    let ref: VerseRef
    let translation: String
    let onStudy: () -> Void
    let onRead: () -> Void
    @Environment(AppModel.self) private var app
    @Environment(\.colorScheme) private var scheme

    /// The saved .verse-card: 22/20/14 padding; 24 pt serif reference, 28 pt serif verse, translation; a full-width
    /// Read & reflect, then the actions centred under a hairline.
    var body: some View {
        let text = BibleStore.shared.text(translation, ref) ?? ""
        let label = BibleStore.shared.label(ref)
        Card(padding: EdgeInsets(top: 22, leading: 20, bottom: 14, trailing: 20)) {
            VStack(alignment: .leading, spacing: 0) {
                Text(label).font(.serif(24, relativeTo: .title2)).tracking(-0.48)
                Text("“\(text)”").font(.serif(28, relativeTo: .title2)).tracking(-0.56).lineSpacing(4.2)
                    .fixedSize(horizontal: false, vertical: true).padding(.top, 32)
                Text(["kjv": "King James Version", "bsb": "Berean Standard Bible", "web": "World English Bible"][translation] ?? "")
                    .font(.system(size: 11)).foregroundStyle(Theme.muted(scheme)).padding(.top, 28)
                Button(action: onRead) {
                    HStack(spacing: 6) { Text("Read & reflect"); Image(systemName: "chevron.right").font(.system(size: 10, weight: .semibold)) }
                        .font(.system(size: 12)).frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
                HStack(spacing: 0) {
                    Button { app.toggleSave(ref.description) } label: { Image(systemName: "heart.fill").frame(width: 58, height: 44) }.accessibilityLabel("Remove from saved")
                    Spacer()
                    Button(action: onStudy) { Image(systemName: "message").foregroundStyle(Theme.muted(scheme)).frame(width: 58, height: 44) }.accessibilityLabel("Study this verse")
                    Spacer()
                    ShareLink(item: "“\(text)” — \(label) (\(BibleStore.offline[translation] ?? ""))") { Image(systemName: "square.and.arrow.up").foregroundStyle(Theme.muted(scheme)).frame(width: 58, height: 44) }.accessibilityLabel("Share verse")
                }
                .font(.system(size: 17))
                .frame(width: 236)
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
                .overlay(alignment: .top) { Rectangle().fill(Theme.border(scheme)).frame(width: 200, height: 1).padding(.top, 8) }
            }
            .foregroundStyle(Theme.text(scheme))
        }
    }
}
