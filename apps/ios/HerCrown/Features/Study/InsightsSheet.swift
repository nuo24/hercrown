import SwiftUI

/// The study sheet from the reader's lens (bible.insights): the verse, then the four study tools and "Widget verse".
struct InsightsSheet: View {
    let ref: VerseRef
    let translation: String
    let onOpen: (VerseRef) -> Void
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var widgetSet = false
    @State private var path: [StudyTool] = {
        #if DEBUG
        // Review switch: `-hcOpenStudy explain|deeper|original|related` opens that tool directly.
        if let tool = UserDefaults.standard.string(forKey: "hcOpenStudy").flatMap(StudyTool.init) { return [tool] }
        #endif
        return []
    }()

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Image("open-book").resizable().scaledToFit().frame(width: 68, height: 58).accessibilityHidden(true)
                    VerseQuote(ref: ref, translation: translation)
                    VStack(spacing: 0) {
                        ForEach(StudyTool.allCases) { tool in
                            NavigationLink(value: tool) {
                                HStack(spacing: 14) {
                                    Image(systemName: tool.symbol).font(.system(size: 18)).frame(width: 24)
                                    Text(tool.title).font(.system(size: 16))
                                    Spacer()
                                    if !app.membership.premium { Text("Plus").font(.system(size: 11, weight: .semibold)).padding(.horizontal, 7).padding(.vertical, 3).background(Capsule().fill(Color.primary.opacity(0.08))) }
                                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 15)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            Divider()
                        }
                        Button {
                            app.updatePreferences(["widgetRef": ref.description]) { $0.widgetRef = ref.description }
                            widgetSet = true
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: widgetSet ? "checkmark.circle" : "square.grid.2x2").font(.system(size: 18)).frame(width: 24)
                                Text(widgetSet ? "Set as your widget verse" : "Widget verse").font(.system(size: 16))
                                Spacer()
                            }
                            .padding(.vertical, 15)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(24)
            }
            .navigationDestination(for: StudyTool.self) { tool in
                Group {
                    switch tool {
                    case .explain, .deeper: AIStudyView(ref: ref, translation: translation, tool: tool)
                    case .original: OriginalLanguageView(ref: ref, translation: translation)
                    case .related: RelatedVersesView(ref: ref, translation: translation) { r in dismiss(); onOpen(r) }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .task { await Analytics.shared.track("study_opened", ["tool": .string(tool.rawValue)]) }
            }
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

/// The verse being studied, always from our Bibles.
struct VerseQuote: View {
    let ref: VerseRef
    let translation: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(BibleStore.shared.label(ref)).font(.serif(26, relativeTo: .title2))
            Text(BibleStore.shared.text(translation, ref) ?? "").font(.serif(20, relativeTo: .title3)).foregroundStyle(.primary.opacity(0.9))
            Text(BibleStore.offline[translation].map { translationName($0) } ?? "").font(.system(size: 12)).foregroundStyle(.secondary)
        }
    }
    private func translationName(_ abbreviation: String) -> String {
        ["KJV": "King James Version", "BSB": "Berean Standard Bible", "WEB": "World English Bible"][abbreviation] ?? abbreviation
    }
}

/// Shown instead of a study when she isn't on Plus. The paywall itself (Superwall) opens from here once it's wired.
struct PlusRequiredView: View {
    let tool: StudyTool
    @Environment(AppModel.self) private var app
    var body: some View {
        VStack(spacing: 14) {
            Image("butterfly").resizable().scaledToFit().frame(width: 90).accessibilityHidden(true)
            Text("Go deeper with Plus").font(.serif(26))
            Text("\(tool.title) is part of Her Crown Plus, along with reading plans and every study tool. Reading the Bible stays free.")
                .multilineTextAlignment(.center).foregroundStyle(.secondary)
            Button("See Her Crown Plus") { app.presentPaywall(placement: "study_\(tool.rawValue)") }
                .buttonStyle(CapsuleButtonStyle()).padding(.top, 6)
        }
        .padding(28)
    }
}
