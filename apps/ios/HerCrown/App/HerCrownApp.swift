import SwiftUI

@main
struct HerCrownApp: App {
    @State private var app = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                .preferredColorScheme(colorScheme)
                .task {
                    // Load her translation off the main thread, then sign in / sync.
                    let translation = app.preferences.translation
                    await Task.detached(priority: .userInitiated) { BibleStore.shared.preload(translation) }.value
                    await app.start()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .background { Task { await Analytics.shared.flush() } }
                }
        }
    }

    private var colorScheme: ColorScheme? {
        switch app.preferences.appearance {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }
}
