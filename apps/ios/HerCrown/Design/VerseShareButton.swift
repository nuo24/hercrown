import SwiftUI
import UIKit

/// All sharing entry points use the passage already loaded from the Bible repository.
struct VerseShareButton: View {
    let text: String
    let reference: String
    let translation: String
    @State private var showingSnapshot = false

    private var translationName: String { BibleStore.offline[translation] ?? translation.uppercased() }

    var body: some View {
        Menu {
            ShareLink(item: "“\(text)” — \(reference) (\(translationName))") {
                Label("Share verse text", systemImage: "text.quote")
            }
            Button("Create a snapshot", systemImage: "photo") { showingSnapshot = true }
        } label: {
            Image.glyph("share").frame(width: 20, height: 20)
                .frame(width: 44, height: 44).contentShape(Rectangle())
        }
        .accessibilityLabel("Share verse")
        .sheet(isPresented: $showingSnapshot) {
            VerseSnapshotView(text: text, reference: reference, translation: translationName)
        }
    }
}
