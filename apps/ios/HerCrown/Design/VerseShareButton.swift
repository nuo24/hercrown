import SwiftUI
import UIKit

/// All sharing entry points use the passage already loaded from the Bible repository.
struct VerseShareButton: View {
    let text: String
    let reference: String
    let translation: String
    var copyright: String? = nil
    @State private var showingOptions = false

    var body: some View {
        Button { showingOptions = true } label: {
            Image.glyph("share").frame(width: 20, height: 20)
                .frame(width: 44, height: 44).contentShape(Rectangle())
        }
        .accessibilityLabel("Share verse")
        .sheet(isPresented: $showingOptions) {
            VerseShareOptions(text: text, reference: reference, translation: translation, copyright: copyright)
        }
    }
}

private struct VerseShareOptions: View {
    let text: String
    let reference: String
    let translation: String
    let copyright: String?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var studio: Studio?
    private enum Studio: String, Identifiable { case snapshot, widget; var id: String { rawValue } }
    private var translationName: String { BibleStore.names[translation.lowercased()] ?? translation.uppercased() }
    private var shareText: String { "“\(text)” — \(reference) (\(translationName))\(copyright.map { "\n" + $0 } ?? "")" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SheetControls(back: { dismiss() }, done: { dismiss() })
                Text("Share verse").font(.ui(20, weight: .semibold))
                VStack(spacing: 16) {
                    Text(reference).font(.ui(21, weight: .semibold))
                    Text(text).font(.serif(25)).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    Text(translationName).font(.ui(12)).foregroundStyle(Theme.muted(scheme))
                }.frame(maxWidth: .infinity).padding(.vertical, 6)
                VStack(spacing: 0) {
                    ShareLink(item: shareText) { row("Share verse text", icon: "doc.text") }
                    Divider()
                    Button { studio = .snapshot } label: { row("Snapshot Studio", icon: "square.and.arrow.up", subtitle: "Create an image of this verse") }
                    Divider()
                    Button { studio = .widget } label: { row("Set as widget verse", icon: "square.grid.2x2") }
                }
            }.padding(.horizontal, 22).padding(.top, 12).padding(.bottom, 56)
        }
        .foregroundStyle(Theme.text(scheme)).background(Theme.canvas(scheme)).buttonStyle(.plain)
        .presentationDetents([.fraction(0.75), .large]).presentationDragIndicator(.visible)
        .task { await Analytics.shared.track("verse_share_opened") }
        .fullScreenCover(item: $studio) { destination in
            VerseSnapshotView(text: text, reference: reference,
                              translation: destination == .widget ? translation.uppercased() : translationName,
                              widgetMode: destination == .widget)
        }
    }

    private func row(_ title: String, icon: String, subtitle: String? = nil) -> some View {
        HStack(spacing: 18) {
            Image(systemName: icon).font(.system(size: 19)).frame(width: 24)
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.ui(14, weight: .semibold))
                if let subtitle { Text(subtitle).font(.ui(12)) }
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right").font(.system(size: 10))
        }.padding(.horizontal, 18).padding(.vertical, 18).frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
    }
}
