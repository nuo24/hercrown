import SwiftUI

/// Explain easier / Deeper study: streams in, then shows the checked sections with their sources and an honest label.
struct AIStudyView: View {
    let ref: VerseRef
    let translation: String
    let tool: StudyTool
    @Environment(AppModel.self) private var app
    @State private var state: StudyState<StudyAnswer> = .loading
    @State private var saved = false
    @State private var reporting = false
    @State private var reported = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("\(BibleStore.shared.label(ref)) · \(BibleStore.offline[translation] ?? "KJV")").font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                Text(BibleStore.shared.text(translation, ref) ?? "").font(.serif(20, relativeTo: .title3))
                Divider()
                content
            }
            .padding(24)
        }
        .navigationTitle(tool.title)
        .toolbar {
            if case .loaded = state {
                ToolbarItem(placement: .primaryAction) {
                    Button { toggleSave() } label: { Image(systemName: saved ? "bookmark.fill" : "bookmark") }
                        .accessibilityLabel(saved ? "Remove from your studies" : "Save to your studies")
                }
            }
        }
        .confirmationDialog("What’s wrong with this study?", isPresented: $reporting, titleVisibility: .visible) {
            ForEach([("inaccurate", "It’s inaccurate"), ("unclear", "It’s unclear"), ("offensive", "It’s offensive"), ("other", "Something else")], id: \.0) { reason, title in
                Button(title) { report(reason) }
            }
        }
        .task { await StudyService.stream(ref, tool) { state = $0 } }
    }

    @ViewBuilder private var content: some View {
        switch state {
        case .loading:
            HStack(spacing: 10) { ProgressView(); Text("Preparing your study…").foregroundStyle(.secondary) }
        case .partial(let text):
            ForEach(Self.liveSections(text), id: \.0) { title, body in section(title, body) }
        case .loaded(let answer):
            ForEach(answer.sections) { section($0.title, $0.text) }
            VStack(alignment: .leading, spacing: 8) {
                Text("Sources").font(.system(size: 13, weight: .semibold))
                ForEach(answer.sources) { s in
                    Text("[\(s.tag)] \(s.author), \(s.name) (\(s.published)) · \(s.license)").font(.system(size: 12)).foregroundStyle(.secondary)
                }
                Text(answer.notice).font(.system(size: 12)).foregroundStyle(.secondary).padding(.top, 4)
                Button(reported ? "Thanks — we’ll take a look" : "Report a problem") { reporting = true }
                    .font(.system(size: 13)).disabled(reported).padding(.top, 4)
            }
            .padding(.top, 6)
        case .needsPlus:
            PlusRequiredView(tool: tool)
        case .failed(let message):
            VStack(alignment: .leading, spacing: 12) {
                Text(message).foregroundStyle(.secondary)
                Button("Try again") { state = .loading; Task { await StudyService.stream(ref, tool) { state = $0 } } }.buttonStyle(CapsuleButtonStyle(kind: .secondary))
            }
        }
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.serif(21, relativeTo: .title3))
            CitedText(text: body).font(.system(size: 16)).lineSpacing(4)
        }
    }

    /// While streaming: "## Title\nbody…" → (title, body) pairs as they arrive.
    static func liveSections(_ text: String) -> [(String, String)] {
        text.components(separatedBy: "## ").compactMap { chunk in
            let trimmed = chunk.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            let parts = trimmed.split(separator: "\n", maxSplits: 1)
            return (String(parts[0]), parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines) : "")
        }
    }

    private func toggleSave() {
        saved.toggle()
        let save = saved
        Task { _ = try? await APIClient.shared.send(save ? "PUT" : "DELETE", "/me/studies/\(ref.description)/\(tool.rawValue)") }
    }

    private func report(_ reason: String) {
        reported = true
        Task { _ = try? await APIClient.shared.send("POST", "/study/\(ref.description)/\(tool.rawValue)/report", json: ["reason": reason]) }
    }
}

/// Body text with source tags like [JFB] shown as small, muted labels.
struct CitedText: View {
    let text: String
    var body: some View {
        var result = Text("")
        var rest = Substring(text)
        while let open = rest.range(of: "["), let close = rest[open.upperBound...].range(of: "]") {
            result = result + Text(rest[..<open.lowerBound])
            let tag = rest[open.upperBound..<close.lowerBound]
            result = result + Text(" \(tag)").font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary)
            rest = rest[close.upperBound...]
        }
        return result + Text(rest)
    }
}

/// Every Greek or Hebrew word: original, transliteration, gloss, grammar, dictionary meaning (tap for the full entry).
struct OriginalLanguageView: View {
    let ref: VerseRef
    let translation: String
    @State private var state: StudyState<OriginalWords> = .loading
    @State private var open: OriginalWords.Word?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                switch state {
                case .loaded(let data):
                    Text(data.language == "grc" ? "Greek" : "Hebrew").font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
                    ForEach(data.words) { word in
                        Button { open = word } label: {
                            HStack(alignment: .firstTextBaseline, spacing: 14) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(word.text).font(.system(size: 24))
                                    Text(word.transliteration).font(.system(size: 13, design: .serif)).italic().foregroundStyle(.secondary)
                                }
                                .frame(minWidth: 96, alignment: .leading)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(Self.plainGloss(word.gloss)).font(.system(size: 16, weight: .medium))
                                    if let meaning = word.meaning, meaning != word.gloss, !meaning.hasPrefix("[") { Text(meaning).font(.system(size: 13)).foregroundStyle(.secondary) }
                                    if let parsing = word.parsing { Text(parsing).font(.system(size: 12)).foregroundStyle(.tertiary) }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                    Text("\(data.source.name) · \(data.source.license)").font(.system(size: 11)).foregroundStyle(.secondary)
                case .needsPlus: PlusRequiredView(tool: .original)
                case .failed(let message): Text(message).foregroundStyle(.secondary)
                default: ProgressView()
                }
            }
            .padding(24)
        }
        .navigationTitle("Original language")
        .sheet(item: $open) { word in
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text(word.lemma ?? word.text).font(.system(size: 30))
                    Text([word.lemmaTransliteration, word.strong].compactMap { $0 }.joined(separator: " · ")).foregroundStyle(.secondary)
                    if let parsing = word.parsing { Text(parsing).font(.system(size: 14)) }
                    Divider()
                    Text(word.definition ?? word.meaning ?? "").font(.system(size: 15))
                }
                .padding(24)
            }
            .presentationDetents([.medium, .large])
        }
        .task { state = await StudyService.load(ref, .original, translation: translation) }
    }

    /// STEPBible marks words English doesn't translate in angle brackets ("<obj.>", "<the>"): say what they do instead.
    static func plainGloss(_ gloss: String) -> String {
        let markers = ["<obj.>": "(marks the object)", "and <obj.>": "and (marks the object)", "<the>": "(the)", "<to>": "(to)"]
        if let plain = markers[gloss] { return plain }
        return gloss.replacingOccurrences(of: "<", with: "(").replacingOccurrences(of: ">", with: ")")
    }
}

/// Cross-references, best first, in her translation. Tap to read one.
struct RelatedVersesView: View {
    let ref: VerseRef
    let translation: String
    let onOpen: (VerseRef) -> Void
    @State private var state: StudyState<RelatedVerses> = .loading

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                switch state {
                case .loaded(let data):
                    Text("Passages often read alongside this verse").font(.system(size: 13)).foregroundStyle(.secondary).padding(.bottom, 8)
                    ForEach(data.related) { item in
                        Button { if let r = VerseRef(item.ref) { onOpen(r) } } label: {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.label).font(.system(size: 14, weight: .semibold))
                                    Text(item.text).font(.serif(18)).multilineTextAlignment(.leading)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                    Text("\(data.source.name) · \(data.source.license)").font(.system(size: 11)).foregroundStyle(.secondary).padding(.top, 8)
                case .needsPlus: PlusRequiredView(tool: .related)
                case .failed(let message): Text(message).foregroundStyle(.secondary)
                default: ProgressView()
                }
            }
            .padding(24)
        }
        .navigationTitle("Related verses")
        .task { state = await StudyService.load(ref, .related, translation: translation) }
    }
}
