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

/// Reflection: the verse, a prompt clearly marked as not Scripture, and a way to mark today as read.
struct ReflectionSheet: View {
    let ref: VerseRef
    let translation: String
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var marked = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(BibleStore.shared.label(ref)).font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
            Text("“\(BibleStore.shared.text(translation, ref) ?? "")”").font(.serif(24, relativeTo: .title2))
            VStack(alignment: .leading, spacing: 6) {
                Text("A moment of reflection").font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
                Text("What stands out to you in this verse, and how might it shape your day?").font(.system(size: 17))
                Text("Reflection prompt · not Scripture").font(.system(size: 12)).foregroundStyle(.secondary)
            }
            Spacer()
            Button(marked ? "Today’s reading is marked" : "Mark today as read") {
                marked = true
                let day = AppModel.localDay()
                Task {
                    _ = try? await app.api.send("POST", "/me/reading-events", json: ["events": [[
                        "id": "reflect-\(day)-\(ref.description.replacingOccurrences(of: ".", with: "-"))", "localDay": day,
                        "timeZone": TimeZone.current.identifier, "ref": ref.description,
                    ]]])
                }
            }
            .buttonStyle(CapsuleButtonStyle())
            .disabled(marked)
        }
        .padding(24)
    }
}

/// Saved passages, in her reading translation.
struct SavedSheet: View {
    let translation: String
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if app.saved.isEmpty {
                    VStack(spacing: 14) {
                        Image("bookmark").resizable().scaledToFit().frame(height: 120).accessibilityHidden(true)
                        Text("Your saved passages will find a home here.").font(.serif(20))
                        Text("Tap the heart on a verse to keep it close.").foregroundStyle(.secondary)
                    }
                    .multilineTextAlignment(.center).padding(32)
                } else {
                    List {
                        ForEach(app.saved.sorted(), id: \.self) { ref in
                            if let r = VerseRef(ref) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(BibleStore.shared.label(r)).font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
                                    Text(BibleStore.shared.text(translation, r) ?? "").font(.serif(19))
                                }
                                .swipeActions { Button("Remove", role: .destructive) { app.toggleSave(ref) } }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Saved passages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

/// Until the study sheets are built (next build), say so honestly instead of showing sample content.
struct StudyComingSoon: View {
    let ref: VerseRef
    let translation: String
    var body: some View {
        VStack(spacing: 16) {
            Image("open-book").resizable().scaledToFit().frame(height: 110).accessibilityHidden(true)
            Text(BibleStore.shared.label(ref)).font(.serif(24))
            Text("Explain easier, Deeper study, Original language and Related verses are ready on the server and arrive in the app’s next build.")
                .multilineTextAlignment(.center).foregroundStyle(.secondary)
        }
        .padding(28)
    }
}
