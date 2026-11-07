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
                VStack(spacing: 0) {
                    Image.illustration("open-book").resizable().scaledToFit().frame(width: 68, height: 58).accessibilityHidden(true)
                    VerseQuote(ref: ref, translation: translation).padding(.top, 8)
                    Divider().padding(.top, 26)
                    VStack(spacing: 0) {
                        ForEach(StudyTool.allCases) { tool in
                            NavigationLink(value: tool) {
                                HStack(spacing: 16) {
                                    Image(systemName: tool.symbol).font(.system(size: 25)).frame(width: 25)
                                    Text(tool.title).font(.system(size: 17))
                                    Spacer()
                                    if !app.membership.premium { Text("Plus").font(.system(size: 11, weight: .semibold)).padding(.horizontal, 7).padding(.vertical, 3).background(Capsule().fill(Color.primary.opacity(0.08))) }
                                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(.tertiary)
                                }
                                .frame(minHeight: 76)
                                .padding(.horizontal, 4)
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
                                Text(widgetSet ? "Widget verse set" : "Set as your widget verse").font(.system(size: 16))
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
        VStack(spacing: 14) {
            Text(BibleStore.shared.label(ref)).font(.system(size: 22, weight: .semibold))
            Text(BibleStore.shared.text(translation, ref) ?? "").font(.serif(23, relativeTo: .title3)).lineSpacing(5.75)
            Text(BibleStore.offline[translation].map { translationName($0) } ?? "").font(.system(size: 12)).foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
    }
    private func translationName(_ abbreviation: String) -> String {
        ["KJV": "King James Version", "BSB": "Berean Standard Bible", "WEB": "World English Bible"][abbreviation] ?? abbreviation
    }
}

/// A locked study opens its placement directly, without a membership introduction or Settings detour.
struct PlusRequiredView: View {
    let tool: StudyTool
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ProgressView("Opening Plus…")
            .frame(maxWidth: .infinity, minHeight: 80)
            .task {
                app.presentPaywall(placement: "study_\(tool.rawValue)", onComplete: {
                    // Purchase/restore refreshes the server entitlement before this callback.
                    // The parent reloads the chosen study when Plus becomes active.
                    if !app.membership.premium { dismiss() }
                })
            }
    }
}
