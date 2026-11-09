import SwiftUI
import UIKit

/// All sharing entry points use the passage already loaded from the Bible repository.
struct VerseShareButton: View {
    let text: String
    let reference: String
    let translation: String
    var copyright: String? = nil
    @State private var showingSnapshot = false
    @State private var showingWidget = false

    private var translationName: String { BibleStore.offline[translation] ?? translation.uppercased() }

    var body: some View {
        Menu {
            ShareLink(item: "“\(text)” — \(reference) (\(translationName))\(copyright.map { "\n" + $0 } ?? "")") {
                Label("Share verse text", systemImage: "text.quote")
            }
            Button("Create a snapshot", systemImage: "photo") { showingSnapshot = true }
            Button("Widget Studio", systemImage: "square.grid.2x2") { showingWidget = true }
        } label: {
            Image.glyph("share").frame(width: 20, height: 20)
                .frame(width: 44, height: 44).contentShape(Rectangle())
        }
        .accessibilityLabel("Share verse")
        .sheet(isPresented: $showingWidget) {
            VerseSnapshotView(text: text, reference: reference, translation: translation.uppercased(), widgetMode: true)
        }
        .sheet(isPresented: $showingSnapshot) {
            VerseSnapshotView(text: text, reference: reference, translation: translationName)
        }
    }
}
