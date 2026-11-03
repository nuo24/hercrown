import SwiftUI

/// Four tabs in the design's order (The Bible, Community, Discover, Home) above the floating dock. The Bible is the default.
struct RootView: View {
    @Environment(AppModel.self) private var app
    @State private var tab: AppTab = Self.startTab

    // Debug-only review switches: `-hcSkipOnboarding YES -hcTab home`.
    #if DEBUG
    static let skipOnboarding = UserDefaults.standard.bool(forKey: "hcSkipOnboarding")
    static let startTab = AppTab(rawValue: UserDefaults.standard.string(forKey: "hcTab") ?? "") ?? .bible
    #else
    static let skipOnboarding = false
    static let startTab = AppTab.bible
    #endif

    var body: some View {
        if app.onboardingCompleted || Self.skipOnboarding { tabs } else { OnboardingView() }
    }

    private var tabs: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .bible: ReaderView(app: app)
                case .community: CommunityView(onExplore: { tab = .discover })
                case .discover: UpcomingTab(title: "Discover", artwork: "lantern", note: "Discover arrives in the next build.")
                case .home: UpcomingTab(title: "Home", artwork: "cosmos", note: "Home arrives in the next build.")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            Dock(selection: $tab).padding(.bottom, 2)
        }
        .onChange(of: tab) { _, new in Task { await Analytics.shared.track("tab_viewed", ["tab": .string(new.rawValue)]) } }
    }
}

/// Community is an honest empty state until its direction is decided (docs/progress.md).
struct CommunityView: View {
    let onExplore: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            AppGradient()
            VStack(spacing: 14) {
                Image("community").resizable().scaledToFit().frame(width: 156, height: 156).accessibilityHidden(true)
                Text("Community").font(.serif(30, relativeTo: .largeTitle)).foregroundStyle(Theme.text(scheme))
                Text("A place to connect and grow together.").font(.system(size: 15)).foregroundStyle(Theme.muted(scheme))
                Text("Community is coming soon.").font(.system(size: 13)).foregroundStyle(Theme.muted(scheme))
                Button("Explore Scripture", action: onExplore).buttonStyle(CapsuleButtonStyle()).frame(width: 240).padding(.top, 8)
            }
            .padding(.bottom, 80)
        }
    }
}

private struct UpcomingTab: View {
    let title: String
    let artwork: String
    let note: String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            AppGradient()
            VStack(spacing: 14) {
                Image(artwork).resizable().scaledToFit().frame(height: 130).accessibilityHidden(true)
                Text(title).font(.serif(30)).foregroundStyle(Theme.text(scheme))
                Text(note).font(.system(size: 14)).foregroundStyle(Theme.muted(scheme))
            }
            .padding(.bottom, 80)
        }
    }
}
