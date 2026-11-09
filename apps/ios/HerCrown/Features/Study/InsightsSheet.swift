import SwiftUI

/// The study sheet from the reader's lens (bible.insights): the verse, then the four study tools and "Widget verse".
struct InsightsSheet: View {
    let ref: VerseRef
    let translation: String
    let onOpen: (VerseRef) -> Void
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var widgetSet = false
    @State private var path: [StudyTool]

    init(ref: VerseRef, translation: String, initialTool: StudyTool? = nil, onOpen: @escaping (VerseRef) -> Void) {
        self.ref = ref
        self.translation = translation
        self.onOpen = onOpen
        #if DEBUG
        let reviewTool = UserDefaults.standard.string(forKey: "hcOpenStudy").flatMap(StudyTool.init)
        _path = State(initialValue: (reviewTool ?? initialTool).map { [$0] } ?? [])
        #else
        _path = State(initialValue: initialTool.map { [$0] } ?? [])
        #endif
    }

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
            .sheetControls(back: { dismiss() }, done: { dismiss() })
            .navigationDestination(for: StudyTool.self) { tool in
                Group {
                    switch tool {
                    case .explain, .deeper: AIStudyView(ref: ref, translation: translation, tool: tool)
                    case .original: OriginalLanguageView(ref: ref, translation: translation)
                    case .related: RelatedVersesView(ref: ref, translation: translation) { r in dismiss(); onOpen(r) }
                    }
                }
                .sheetControls(back: { if !path.isEmpty { path.removeLast() } }, done: { dismiss() })
                .toolbar(.hidden, for: .navigationBar)
                .task { await Analytics.shared.track("study_opened", ["tool": .string(tool.rawValue)]) }
            }
            .toolbar(.hidden, for: .navigationBar)
            .background(Theme.canvas(scheme))
        }
    }
}

/// The verse being studied, always from our Bibles.
struct VerseQuote: View {
    let ref: VerseRef
    let translation: String
    @State private var passage: OnlineBible.Passage?
    var body: some View {
        VStack(spacing: 14) {
            Text(passage?.label ?? BibleStore.shared.label(ref)).font(.system(size: 22, weight: .semibold))
            ScriptureText(text: passage?.text ?? BibleStore.shared.text(translation, ref) ?? "", reference: ref.description, translation: translation).font(.serif(23, relativeTo: .title3)).lineSpacing(5.75)
            Text(BibleStore.names[translation] ?? translation.uppercased()).font(.system(size: 12)).foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .task(id: "\(translation)|\(ref)") {
            passage = nil
            if BibleStore.online[translation] != nil { passage = try? await OnlineBible.passage(translation, ref: ref) }
        }
    }
    private func translationName(_ abbreviation: String) -> String {
        ["KJV": "King James Version", "BSB": "Berean Standard Bible", "WEB": "World English Bible"][abbreviation] ?? abbreviation
    }
}

/// A locked tool offers an explicit paywall action after the free insights menu.
struct PlusRequiredView: View {
    let tool: StudyTool
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 14) {
            Image.illustration("open-book").resizable().scaledToFit().frame(width: 72, height: 64).accessibilityHidden(true)
            Text("A little deeper with Plus.").font(.serif(25))
            Text("\(tool.title) is part of Her Crown Plus. Reading the Bible stays free.")
                .font(.ui(13)).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button("Explore Her Crown Plus") {
                app.presentPaywall(placement: "study_\(tool.rawValue)")
            }.buttonStyle(CapsuleButtonStyle())
        }.frame(maxWidth: .infinity).padding(.vertical, 16)
    }
}
