import SwiftUI

@main
struct BibleScrollApp: App {
    @StateObject private var library = ScriptureLibrary()
    @AppStorage("appearance") private var appearance = "system"
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(library)
                .preferredColorScheme(appearance == "system" ? nil : appearance == "dark" ? .dark : .light)
                .tint(.primary)
        }
    }
}
