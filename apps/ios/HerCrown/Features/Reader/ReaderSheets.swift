import SwiftUI

/// Choose a book, then a chapter, from the bundled Bible catalog.
struct ChapterPicker: View {
    let current: Chapter?
    let onPick: (String, Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var query = ""
    @State private var selectedBook: BibleBook?

    private var books: [BibleBook] {
        let all = BibleStore.shared.books(for: current?.translation ?? "kjv")
        let search = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return search.isEmpty ? all : all.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button {
                    if selectedBook != nil { selectedBook = nil }
                    else { dismiss() }
                } label: {
                    Label("Back", systemImage: "arrow.left")
                        .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
                        .contentShape(Rectangle())
                }
            }
            .font(.ui(13, weight: .medium))
            .buttonStyle(.plain)
            .padding(.bottom, 10)

            Text(selectedBook?.name ?? "Choose a chapter")
                .font(.ui(20, weight: .medium, relativeTo: .title3))
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, 18)

            if let selectedBook {
                chapterGrid(selectedBook)
            } else {
                bookSearch
                bookList
            }
        }
        .padding(.horizontal, 22)
        .foregroundStyle(Theme.text(scheme))
        .background(Theme.canvas(scheme).ignoresSafeArea())
        .task { await Analytics.shared.track("bible_book_picker_viewed") }
    }

    private var bookSearch: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Search books").font(.ui(13, weight: .medium))
            TextField("Search books…", text: $query)
                .font(.ui(16))
                .padding(.horizontal, 13)
                .frame(minHeight: 46)
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.border(scheme)))
                .accessibilityLabel("Search books")
                .autocorrectionDisabled()
                .submitLabel(.search)
        }
        .padding(.bottom, 18)
    }

    private var bookList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(books) { book in
                    Button {
                        selectedBook = book
                    } label: {
                        HStack(spacing: 12) {
                            BibleBookImage(bookID: book.id).frame(width: 40, height: 40)
                            Text(book.name).font(.ui(14, weight: .medium))
                            Text("\(book.chapterCount) chapters").font(.ui(11))
                                .foregroundStyle(Theme.muted(scheme))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9))
                                .foregroundStyle(Theme.muted(scheme))
                                .accessibilityHidden(true)
                        }
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    Divider()
                }
                if books.isEmpty {
                    Text("No books found.").font(.ui(14))
                        .foregroundStyle(Theme.muted(scheme))
                        .padding(.vertical, 16)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func chapterGrid(_ book: BibleBook) -> some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                ForEach(1...book.chapterCount, id: \.self) { number in
                    let selected = current?.book.id == book.id && current?.number == number
                    Button { onPick(book.id, number) } label: {
                        Text("\(number)").font(.ui(16, weight: selected ? .medium : .regular))
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Theme.supporting(scheme), in: RoundedRectangle(cornerRadius: 10))
                            .overlay {
                                if selected { RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.text(scheme)) }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Chapter \(number)")
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            .padding(.vertical, 12)
        }
    }
}

/// Reflection keeps Scripture separate from the prompt and her saved note; Discover can also offer study actions.
struct ReflectionSheet: View {
    let ref: VerseRef
    let translation: String
    var notesOnly = false
    var autofocus = true
    var onStudy: (() -> Void)? = nil
    var onComplete: (() -> Void)? = nil
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var note = ""
    @State private var noteLoaded = false
    @State private var noteStatus = ""
    @State private var savedNote = ""
    @State private var onlinePassage: OnlineBible.Passage?
    @State private var passageError: String?
    @State private var confirmStudied = false
    @State private var finishing = false
    @State private var saving = false
    @FocusState private var editing: Bool

    var body: some View {
        NavigationStack {
            GeometryReader { viewport in
                content(viewportHeight: viewport.size.height)
            }
                .safeAreaInset(edge: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 14) {
                        SheetControls(back: { Task { await finish() } }, done: { Task { await finish() } })
                            .disabled(!noteLoaded || finishing || saving)
                        Text("Reflection").font(.ui(18, weight: .semibold))
                            .accessibilityAddTraits(.isHeader)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                    .foregroundStyle(Theme.text(scheme))
                    .background(Theme.canvas(scheme))
                }
                .toolbar(.hidden, for: .navigationBar)
        }
        .confirmationDialog("Mark as studied?", isPresented: $confirmStudied, titleVisibility: .visible) {
            Button("Mark as Studied") { Task { if note == savedNote { onComplete?() } else if await saveNote() { onComplete?() } } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You won’t see this study in Discover again. It will be saved under Saved → Studied, including any notes you’ve written.")
        }
        .task(id: "\(translation)|\(ref)") {
            guard BibleStore.online[translation] != nil else { return }
            do {
                let loaded = try await OnlineBible.passage(translation, ref: ref)
                if !Task.isCancelled { onlinePassage = loaded; passageError = nil }
            } catch { if !Task.isCancelled { passageError = "This passage couldn’t load. Reconnect and reopen it to try again." } }
        }
        .presentationDetents([.large]).presentationDragIndicator(.visible)
        .interactiveDismissDisabled(note != savedNote || finishing)
    }

    private func content(viewportHeight: CGFloat) -> some View {
        let editorHeight: CGFloat = viewportHeight < 550 ? 104 : 180
        return VStack(spacing: 12) {
            ViewThatFits(in: .vertical) {
                passage(fontSize: 24, compact: false)
                passage(fontSize: 22, compact: true)
                passage(fontSize: 19, compact: true)
                passage(fontSize: 17, compact: true)
                ScrollView { passage(fontSize: 17, compact: true) }
                    .scrollDismissesKeyboard(.interactively)
            }
            .frame(maxHeight: .infinity, alignment: .topLeading)
            noteEditor(height: editorHeight)
            if let onStudy {
                HStack {
                    Button("Read & reflect") { Task { if note == savedNote { onStudy() } else if await saveNote() { onStudy() } } }.font(.ui(13, weight: .medium))
                    Spacer()
                    if onComplete != nil { Button("Mark as studied") { confirmStudied = true }.font(.ui(12)) }
                }.buttonStyle(.plain).foregroundStyle(Theme.text(scheme)).frame(minHeight: 44)
                    .disabled(!noteLoaded || saving || finishing)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(Theme.canvas(scheme))
        .task {
            #if DEBUG
            if autofocus && !finishing && !UserDefaults.standard.bool(forKey: "hcPreviewReflectionNoKeyboard") { editing = true }
            #else
            if autofocus && !finishing { editing = true }
            #endif
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

    private func passage(fontSize: CGFloat, compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 24) {
            VStack(spacing: compact ? 8 : 22) {
                Image.illustration("intention-heart")
                    .resizable().scaledToFit()
                    .frame(width: compact ? 28 : 64, height: compact ? 24 : 64)
                    .accessibilityHidden(true)
                ScriptureReference(ref: ref, translation: translation)
                    .font(.ui(compact ? 16 : 20, weight: .semibold))
                if let text = onlinePassage?.text ?? BibleStore.shared.text(translation, ref) {
                    ScriptureText(text: text, reference: ref.description, translation: translation)
                        .font(.serif(fontSize, relativeTo: .title2))
                        .lineSpacing(max(0, fontSize * 0.15))
                } else if let passageError {
                    Text(passageError).font(.ui(13)).foregroundStyle(Theme.muted(scheme))
                } else { ProgressView("Loading passage…").font(.ui(12)) }
                Text(translationName)
                    .font(.ui(12)).foregroundStyle(Theme.muted(scheme))
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, compact ? 0 : 20)
            if !notesOnly {
                Divider()
                VStack(alignment: .leading, spacing: compact ? 4 : 12) {
                    Text("A moment of reflection").font(.ui(compact ? 13 : 14, weight: .semibold))
                    Text("What stands out to you in this verse, and how might it shape your day?")
                        .font(.ui(compact ? 12 : 14)).lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Reflection prompt · not Scripture")
                        .font(.ui(11)).foregroundStyle(Theme.muted(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, compact ? 0 : 14)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var translationName: String {
        switch translation.lowercased() {
        case "kjv": "King James Version"
        case "bsb": "Berean Standard Bible"
        case "web": "World English Bible"
        default: BibleStore.offline[translation] ?? translation.uppercased()
        }
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
                .font(.ui(14))
                .scrollContentBackground(.hidden)
                .padding(10)
                .frame(height: height)
                .background(scheme == .dark ? Color(hex: 0x171719) : Theme.surface(scheme), in: RoundedRectangle(cornerRadius: 14))
                .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(Color.primary.opacity(0.24)).allowsHitTesting(false) }
                .overlay(alignment: .topLeading) {
                    if note.isEmpty {
                        Text("Write a thought, a prayer, a question…")
                            .font(.ui(14)).foregroundStyle(.secondary)
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
