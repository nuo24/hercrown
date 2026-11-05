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
    var notesOnly = false
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var note = ""
    @State private var noteLoaded = false
    @State private var noteStatus = ""
    @State private var savedNote = ""
    @State private var finishing = false
    @State private var saving = false
    @FocusState private var editing: Bool

    var body: some View {
        NavigationStack {
            GeometryReader { viewport in
                content(viewportHeight: viewport.size.height)
            }
                .navigationTitle(notesOnly ? "Verse notes" : "Reflection")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { Task { await finish() } }
                            .disabled(!noteLoaded || finishing || saving)
                    }
                }
        }
        .interactiveDismissDisabled(note != savedNote || finishing)
    }

    private func content(viewportHeight: CGFloat) -> some View {
        let editorHeight = min(180, max(104, viewportHeight * 0.38))
        return VStack(spacing: 12) {
            ViewThatFits(in: .vertical) {
                passage(fontSize: 26)
                passage(fontSize: 22)
                passage(fontSize: 19)
                passage(fontSize: 17)
                ScrollView { passage(fontSize: 17) }
                    .scrollDismissesKeyboard(.interactively)
            }
            .frame(maxHeight: .infinity, alignment: .topLeading)
            noteEditor(height: editorHeight)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .task {
            if !finishing { editing = true }
            struct Note: Decodable { let text: String }
            if let existing: Note = try? await app.api.get("/me/notes/\(ref.description)") {
                savedNote = existing.text
                if note.isEmpty { note = existing.text }
            }
            noteLoaded = true
        }
        .task(id: noteLoaded ? note : nil) {
            guard noteLoaded, note != savedNote else { return }
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled, !finishing else { return }
            _ = await saveNote()
        }
    }

    private func passage(fontSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(BibleStore.shared.label(ref))
                .font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
            Text(BibleStore.shared.text(translation, ref) ?? "")
                .font(.serif(fontSize, relativeTo: .title2))
            if !notesOnly {
                VStack(alignment: .leading, spacing: 4) {
                    Text("A moment of reflection").font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
                    Text("What stands out to you in this verse, and how might it shape your day?")
                        .font(.system(size: 13)).lineSpacing(2)
                    Text("Reflection prompt · not Scripture").font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func noteEditor(height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Your notes").font(.system(size: 13, weight: .semibold))
                Spacer()
                Text(noteStatus).font(.system(size: 12)).foregroundStyle(.secondary)
            }
            TextEditor(text: $note)
                .focused($editing)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(10)
                .frame(height: height)
                .background(scheme == .dark ? Color(hex: 0x35363D) : .white, in: RoundedRectangle(cornerRadius: 14))
                .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(Color.primary.opacity(0.24)).allowsHitTesting(false) }
                .overlay(alignment: .topLeading) {
                    if note.isEmpty {
                        Text("Write a thought, a prayer, a question…")
                            .font(.body).foregroundStyle(.secondary)
                            .padding(.leading, 15).padding(.top, 18)
                            .allowsHitTesting(false).accessibilityHidden(true)
                    }
                }
                .accessibilityLabel("Your notes")
                .disabled(finishing)
        }
    }

    private func finish() async {
        finishing = true
        editing = false
        if note == savedNote {
            dismiss()
        } else if await saveNote() {
            dismiss()
        }
        finishing = false
    }

    private func saveNote() async -> Bool {
        let text = note
        let at = (Date().timeIntervalSince1970 * 1000).rounded()
        saving = true
        defer { saving = false }
        noteStatus = "Saving…"
        do {
            try await app.api.send("PUT", "/me/notes/\(ref.description)", json: ["text": text, "at": at])
            savedNote = text
            noteStatus = "Auto-saved"
            await Analytics.shared.track("note_saved")
            return true
        } catch {
            noteStatus = "Not saved. Check your connection."
            return false
        }
    }
}
