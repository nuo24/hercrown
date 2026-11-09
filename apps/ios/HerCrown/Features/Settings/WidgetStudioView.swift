import SwiftUI

/// Uses the same passage the Home Screen widget will display, including the chosen-verse preference.
struct WidgetStudioView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var passage: WidgetPassage?
    @State private var failed = false
    @State private var attempt = 0
    var body: some View {
        Group {
            if let passage {
                VerseSnapshotView(text: passage.text, reference: passage.label, translation: passage.translation.uppercased(), widgetMode: true)
            } else if failed {
                VStack(spacing: 18) {
                    Text("Your widget verse couldn’t load.").font(.serif(24))
                    Text("Open a Bible passage and choose ‘Set as your widget verse’, or reconnect and try again.").font(.ui(13)).multilineTextAlignment(.center)
                    Button("Try again") { attempt += 1 }.buttonStyle(CapsuleButtonStyle())
                }.padding(24)
            } else { ProgressView() }
        }.safeAreaInset(edge: .top) {
            if passage == nil && failed {
                HStack {
                    Button { dismiss() } label: { Image(systemName: "arrow.left").frame(width: 44, height: 44) }
                    Text("Widget Studio").font(.serif(26))
                    Spacer()
                    Button("Done") { dismiss() }.font(.ui(14)).frame(minHeight: 44)
                }.buttonStyle(.plain).padding(.horizontal, 16)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Theme.canvas(scheme))
            .toolbar(.hidden, for: .navigationBar)
            .task(id: attempt) {
                let owner = app.me?.user.id
                // Open immediately with the saved verse for this owner and edition; don't
                // hold the Studio behind an online refresh when a matching widget is present.
                WidgetDesignStore.activate(owner: owner)
                if let cached = WidgetBridge.current, cached.translation.lowercased() == app.preferences.translation.lowercased() {
                    passage = cached
                    return
                }
                await WidgetBridge.refresh(translation: app.preferences.translation, userID: owner)
                guard !Task.isCancelled, owner == app.me?.user.id else { return }
                passage = WidgetBridge.current
                failed = passage == nil
            }
    }
}
