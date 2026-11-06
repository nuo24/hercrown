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
        .onChange(of: tab) { _, new in Task { await Analytics.shared.track("tab_viewed", ["tab": .string(new.rawValue)]) } }
        .onChange(of: app.requestedTab) { _, new in if let new { tab = new; app.requestedTab = nil } }
    }

    private func openSettings() { showingSettings = true }
}

/// Community is an honest empty state until its direction is decided (docs/progress.md).
struct CommunityView: View {
    let onExplore: () -> Void
    let onOpenSettings: () -> Void
    @Environment(AppModel.self) private var app
    @Environment(\.colorScheme) private var scheme
    @State private var showingSaved = false

    var body: some View {
        ZStack(alignment: .top) {
            AppGradient()
            ScrollView {
                VStack(spacing: 0) {
                    HStack(spacing: 4) {
                        Text("Community").font(.serif(34, relativeTo: .largeTitle)).tracking(-0.65)
                            .foregroundStyle(Theme.text(scheme))
                            .accessibilityAddTraits(.isHeader)
                        Spacer()
                        PageIconButton(glyph: "bookmark", label: "Saved passages") { showingSaved = true }
                        PageIconButton(glyph: "gear", label: "Settings", action: onOpenSettings)
                    }
                    .padding(EdgeInsets(top: 20, leading: 20, bottom: 18, trailing: 20))

                    VStack(spacing: 0) {
                        Image.illustration("community").resizable().scaledToFit()
                            .frame(width: 156, height: 156).accessibilityHidden(true)
                        Text("Coming soon").font(.serif(34, relativeTo: .largeTitle))
                            .foregroundStyle(Theme.text(scheme)).padding(.top, 36)
                        Text("A place to connect, share encouragement,\nand grow in faith together.")
                            .font(.ui(14)).frame(minHeight: 22.4).padding(.top, 8)
                        Text("We’re making a little space for community.").font(.ui(12)).padding(.top, 12)
                        Button("Explore Scripture", action: onExplore)
                            .font(.ui(14, weight: .medium))
                            .foregroundStyle(Theme.canvas(scheme))
                            .frame(maxWidth: 240, minHeight: 48)
                            .background(Theme.text(scheme), in: RoundedRectangle(cornerRadius: 8))
                            .buttonStyle(.plain)
                            .padding(.top, 24)
                    }
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.muted(scheme))
                    .padding(.horizontal, 32)
                    .padding(.top, 48)
                }
                .padding(.bottom, 108)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
        }
        .sheet(isPresented: $showingSaved) { SavedSheet(translation: app.preferences.translation) }
    }
}
