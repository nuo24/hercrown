import SwiftUI

/// Native chapter selection: books by testament, then a grid of chapters.
struct ChapterPicker: View {
    let current: Chapter?
    let onPick: (String, Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var books: [BibleBook] {
        let all = BibleStore.shared.books
        return query.isEmpty ? all : all.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(["OT", "NT"], id: \.self) { testament in
                    Section(testament == "OT" ? "Old Testament" : "New Testament") {
                        ForEach(books.filter { $0.testament == testament }) { book in
                            NavigationLink(book.name) { ChapterGrid(book: book, current: current, onPick: onPick) }
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: "Find a book")
            .navigationTitle("Choose a chapter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }
}

private struct ChapterGrid: View {
    let book: BibleBook
    let current: Chapter?
    let onPick: (String, Int) -> Void

    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                ForEach(1...book.chapterCount, id: \.self) { n in
                    let selected = current?.book.id == book.id && current?.number == n
                    Button { onPick(book.id, n) } label: {
                        Text("\(n)").font(.system(size: 16, weight: selected ? .semibold : .regular))
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(selected ? Color.primary.opacity(0.15) : Color.primary.opacity(0.05)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Chapter \(n)")
                }
            }
            .padding()
        }
        .navigationTitle(book.name)
    }
}

/// Reflection: the verse, a prompt clearly marked as not Scripture, her own note (auto-saved), and a way to mark today as read.
struct ReflectionSheet: View {
    let ref: VerseRef
    let translation: String
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var marked = false
    @State private var note = ""
    @State private var noteLoaded = false
    @State private var noteStatus = ""
    @FocusState private var editing: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(BibleStore.shared.label(ref)).font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
                Text("“\(BibleStore.shared.text(translation, ref) ?? "")”").font(.serif(24, relativeTo: .title2))
                VStack(alignment: .leading, spacing: 6) {
                    Text("A moment of reflection").font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
                    Text("What stands out to you in this verse, and how might it shape your day?").font(.system(size: 17))
                    Text("Reflection prompt · not Scripture").font(.system(size: 12)).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Your notes").font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Text(noteStatus).font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                    TextEditor(text: $note)
                        .focused($editing)
                        .font(.system(size: 16))
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 110)
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.supporting(scheme)))
                        .overlay(alignment: .topLeading) {
                            if note.isEmpty && !editing { Text("Write a thought, a prayer, a question…").font(.system(size: 16)).foregroundStyle(.tertiary).padding(18).allowsHitTesting(false) }
                        }
                        .disabled(!noteLoaded)
                }
                Button(marked ? "Today’s reading is marked" : "Mark today as read") {
                    marked = true
                    let day = AppModel.localDay()
                    Task {
                        _ = try? await app.api.send("POST", "/me/reading-events", json: ["events": [[
                            "id": "reflect-\(day)-\(ref.description.replacingOccurrences(of: ".", with: "-"))", "localDay": day,
                            "timeZone": TimeZone.current.identifier, "ref": ref.description,
                        ]]])
                        await Analytics.shared.track("day_marked_read", ["source": .string("reflection")])
                    }
                }
                .buttonStyle(CapsuleButtonStyle())
                .disabled(marked)
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .task {
            struct Note: Decodable { let text: String }
            if let existing: Note = try? await app.api.get("/me/notes/\(ref.description)") { note = existing.text }
            noteLoaded = true
        }
        .task(id: note) {
            guard noteLoaded else { return }
            try? await Task.sleep(for: .milliseconds(800)) // auto-save once she pauses
            guard !Task.isCancelled else { return }
            let text = note
            let at = (Date().timeIntervalSince1970 * 1000).rounded()
            noteStatus = "Saving…"
            do {
                try await app.api.send("PUT", "/me/notes/\(ref.description)", json: ["text": text, "at": at])
                noteStatus = "Auto-saved"
                await Analytics.shared.track("note_saved")
            } catch {
                noteStatus = "Not saved. Check your connection."
            }
        }
    }
}
