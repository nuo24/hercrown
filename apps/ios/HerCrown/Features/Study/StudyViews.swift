import SwiftUI
import UIKit

/// Explain easier / Deeper study: streams in, then shows the checked sections with their sources and an honest label.
struct AIStudyView: View {
    let ref: VerseRef
    let translation: String
    let tool: StudyTool
    @Environment(\.colorScheme) private var scheme
    @Environment(AppModel.self) private var app
    @State private var state: StudyState<StudyAnswer> = .loading
    @State private var saved = false
    @State private var showingNotes = false
    @State private var copied = false
    @State private var reporting = false
    @State private var reported = false
    @State private var attempt = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(tool.title).font(.ui(20, weight: .semibold))
                    .accessibilityAddTraits(.isHeader)
                VStack(spacing: 16) {
                    ScriptureReference(ref: ref, translation: translation).font(.ui(21, weight: .semibold))
                    ScriptureText(text: BibleStore.shared.text(translation, ref) ?? "", reference: ref.description, translation: translation)
                        .font(.serif(25, relativeTo: .title2)).lineSpacing(4)
                    Text(BibleStore.offline[translation] ?? translation.uppercased())
                        .font(.ui(12)).foregroundStyle(Theme.muted(scheme))
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 10)
                content
            }
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 44)
        }
        .background(Theme.canvas(scheme))
        .tint(Theme.text(scheme)).foregroundStyle(Theme.text(scheme)).buttonStyle(.plain)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if case .loaded = state {
                ToolbarItem(placement: .primaryAction) {
                    Button { toggleSave() } label: { Image(systemName: saved ? "bookmark.fill" : "bookmark") }
                        .accessibilityLabel(saved ? "Remove from your studies" : "Save to your studies")
                }
            }
        }
        .sheet(isPresented: $showingNotes) {
            ReflectionSheet(ref: ref, translation: translation).presentationDetents([.large])
        }
        .confirmationDialog("What’s wrong with this study?", isPresented: $reporting, titleVisibility: .visible) {
            ForEach([("inaccurate", "It’s inaccurate"), ("unclear", "It’s unclear"), ("offensive", "It’s offensive"), ("other", "Something else")], id: \.0) { reason, title in
                Button(title) { report(reason) }
            }
        }
        .task(id: "\(attempt)-\(app.membership.premium)") {
            guard app.membership.premium else { state = .needsPlus; return }
            state = .loading
            await StudyService.stream(ref, tool) { state = $0 }
        }
    }

    @ViewBuilder private var content: some View {
        switch state {
        case .loading:
            HStack(spacing: 10) { ProgressView(); Text("Preparing your study…").foregroundStyle(.secondary) }
        case .partial(let text):
            ForEach(Self.liveSections(text), id: \.0) { title, body in section(title, body) }
        case .loaded(let answer):
            Text("Study commentary · separate from Scripture")
                .font(.ui(12)).foregroundStyle(Theme.muted(scheme))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Theme.surface(scheme), in: RoundedRectangle(cornerRadius: 12))
            ForEach(answer.sections) { section($0.title, $0.text) }
            DisclosureGroup("Sources & study notice") {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(answer.sources) { source in
                        Text("[\(source.tag)] \(source.author), \(source.name) (\(source.published)) · \(source.license)")
                    }
                }
                .font(.ui(12))
                .foregroundStyle(Theme.muted(scheme))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 10)
            }
            .font(.ui(14, weight: .medium))
            let export = ([ "\(tool.title) · \(BibleStore.shared.label(ref))" ] +
                answer.sections.map { "\($0.title)\n\($0.text)" } +
                ["Sources\n" + answer.sources.map { "[\($0.tag)] \($0.author), \($0.name)" }.joined(separator: "\n")])
                .joined(separator: "\n\n")
            HStack {
                Button { toggleSave() } label: { studyAction(saved ? "Saved" : "Save study", icon: saved ? "bookmark.fill" : "bookmark") }
                Spacer()
                Button { showingNotes = true } label: { studyAction("Note", icon: "square.and.pencil") }
                Spacer()
                Button { UIPasteboard.general.string = export; copied = true } label: {
                    studyAction(copied ? "Copied" : "Copy", icon: "doc.on.doc")
                }
                Spacer()
                ShareLink(item: export) { studyAction("Share", icon: "square.and.arrow.up") }
            }
            .font(.ui(13, weight: .medium))
            .frame(minHeight: 44)
            Button(reported ? "Thanks — we’ll take a look" : "Report a problem") { reporting = true }
                .font(.ui(13))
                .disabled(reported)
        case .needsPlus:
            PlusRequiredView(tool: tool)
        case .failed(let message):
            VStack(alignment: .leading, spacing: 12) {
                Text(message).foregroundStyle(.secondary)
                Button("Try again") { attempt += 1 }.buttonStyle(CapsuleButtonStyle(kind: .secondary))
            }
        }
    }

    private func studyAction(_ title: String, icon: String) -> some View {
        VStack(spacing: 7) {
            Image(systemName: icon).font(.system(size: 22, weight: .regular))
            Text(title).font(.ui(11, weight: .medium))
        }.frame(minWidth: 52, minHeight: 52).foregroundStyle(Theme.text(scheme))
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.ui(15, weight: .semibold)).accessibilityAddTraits(.isHeader)
            CitedText(text: body).font(.ui(14)).lineSpacing(6)
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
    @Environment(AppModel.self) private var app
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
                            .padding(14)
                            .surfaceCard(radius: 14)
                        }
                        .buttonStyle(.plain)
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
        .task(id: app.membership.premium) {
            guard app.membership.premium else { state = .needsPlus; return }
            state = .loading
            state = await StudyService.load(ref, .original, translation: translation)
        }
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
    @Environment(AppModel.self) private var app
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
                                    ScriptureText(text: item.text, reference: item.ref, translation: translation).font(.serif(18)).multilineTextAlignment(.leading)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 20)
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
        .task(id: app.membership.premium) {
            guard app.membership.premium else { state = .needsPlus; return }
            state = .loading
            state = await StudyService.load(ref, .related, translation: translation)
        }
    }
}
