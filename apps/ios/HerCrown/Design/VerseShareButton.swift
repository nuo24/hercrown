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

struct VerseSnapshotView: View {
    let text: String
    let reference: String
    let translation: String
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var showsWatermark = true
    @State private var rendered: UIImage?

    private var watermark: Bool { !app.membership.premium || showsWatermark }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let rendered {
                        Image(uiImage: rendered).resizable().scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .accessibilityLabel("Verse snapshot, \(reference)")
                        ShareLink(item: Image(uiImage: rendered),
                                  preview: SharePreview(reference, image: Image(uiImage: rendered))) {
                            Label("Share snapshot", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(CapsuleButtonStyle())
                    } else {
                        Text("The snapshot couldn’t be prepared. Please try again.").font(.ui(14))
                        Button("Try again") { render() }.buttonStyle(CapsuleButtonStyle(kind: .secondary))
                    }
                    if app.membership.premium {
                        Toggle("Her Crown watermark", isOn: $showsWatermark).font(.ui(14))
                            .tint(Theme.text(scheme))
                    } else {
                        Text("Snapshots include the Her Crown watermark. Plus members can turn it off.")
                            .font(.ui(12)).foregroundStyle(Theme.muted(scheme))
                    }
                }
                .padding(22)
            }
            .background(AppGradient())
            .navigationTitle("Verse snapshot").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .task { render(); await Analytics.shared.track("verse_snapshot_opened") }
        .onChange(of: watermark) { _, _ in render() }
    }

    @MainActor private func render() {
        let card = VStack(alignment: .leading, spacing: 28) {
            Image.illustration("cosmos").resizable().scaledToFit().frame(width: 72, height: 80)
            Spacer(minLength: 16)
            Text(text).font(.custom("Baskerville", fixedSize: 34))
                .lineSpacing(7).fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(reference) · \(translation)").font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color(hex: 0x555B56))
            Spacer(minLength: 16)
            if watermark {
                Text("Her Crown").font(.custom("Baskerville-Italic", fixedSize: 22))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(44).frame(width: 540, alignment: .leading).frame(minHeight: 720)
        .foregroundStyle(Color(hex: 0x111111))
        .background(LinearGradient(colors: [.white, Color(hex: 0xE4EDDF), Color(hex: 0xE0EDF5)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
        .environment(\.colorScheme, .light)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 2
        rendered = renderer.uiImage
    }
}
