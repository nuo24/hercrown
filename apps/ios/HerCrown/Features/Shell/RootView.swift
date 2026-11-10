import SwiftUI

/// Four tabs in the design's order (The Bible, Community, Discover, Home) above the bottom navigation. The Bible is the default.
struct RootView: View {
    @Environment(AppModel.self) private var app
    @State private var tab: AppTab = Self.startTab
    @State private var showingSettings = false

    // Debug-only review switches: `-hcSkipOnboarding YES -hcTab home`.
    #if DEBUG
    static let skipOnboarding = UserDefaults.standard.bool(forKey: "hcSkipOnboarding")
    static let startTab = AppTab(rawValue: UserDefaults.standard.string(forKey: "hcTab") ?? "") ?? .bible
    #else
    static let skipOnboarding = false
    static let startTab = AppTab.bible
    #endif

    var body: some View {
        Group {
            if app.onboardingCompleted || Self.skipOnboarding { tabs } else { OnboardingView() }
        }
        .onChange(of: app.onboardingCompleted) { _, complete in
            if complete { tab = .bible }
        }
        .environment(\.font, .ui(14))
        // Settings can switch accounts and replace the content underneath it.
        .fullScreenCover(isPresented: $showingSettings) { SettingsView().environment(app) }
    }

    private var tabs: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .bible: ReaderView(app: app)
                case .community: CommunityView(onExplore: { tab = .discover }, onOpenSettings: openSettings)
                case .discover: DiscoverView(onOpenSettings: openSettings)
                case .home: HomeView(onOpenSettings: openSettings)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            Dock(selection: $tab)
        }
        .onAppear {
            if let requested = app.requestedTab { tab = requested; app.requestedTab = nil }
        }
        .onChange(of: tab) { _, new in Task { await Analytics.shared.track("tab_viewed", ["tab": .string(new.rawValue)]) } }
        .onChange(of: app.requestedTab) { _, new in if let new { tab = new; app.requestedTab = nil } }
    }

    private func openSettings() { showingSettings = true }
}
