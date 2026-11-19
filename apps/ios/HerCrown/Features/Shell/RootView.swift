import SwiftUI
import StoreKit

/// Four tabs in the design's order (The Bible, Community, Discover, Home) above the bottom navigation. The Bible is the default.
struct RootView: View {
    @Environment(AppModel.self) private var app
    @State private var tab: AppTab = Self.startTab
    @State private var showingSettings = false
    @State private var review = ReviewPrompter.shared
    @Environment(\.requestReview) private var requestReview
    @Environment(\.scenePhase) private var scenePhase
    @State private var feedbackInvitation = false
    @State private var feedbackForm = false

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
        .sheet(isPresented: $feedbackInvitation, onDismiss: {
            if feedbackForm { feedbackForm = false; showingFeedback = true }
        }) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Help shape Her Crown.").font(.serif(28))
                Text("Is there something we could make better? Your suggestions and bug reports are welcome.")
                    .font(.ui(15)).foregroundStyle(.secondary)
                Button("Share feedback") { feedbackForm = true; feedbackInvitation = false }
                    .buttonStyle(CapsuleButtonStyle())
                Button("Not now") { feedbackInvitation = false }
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .padding(26).presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingFeedback) { NavigationStack { FeedbackView().environment(app) } }
        .task(id: "\(tab.rawValue)-\(review.revision)-\(scenePhase)-\(showingSettings)") {
            guard canOfferPrompt else { return }
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled, canOfferPrompt else { return }
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
            if review.history.canRequestReview(now: .now, version: version) {
                review.requestedReview(version: version)
                await Analytics.shared.track("review_requested")
                requestReview() // Apple decides whether to display its native, unbiased rating dialog.
            } else if review.history.canRequestFeedback(now: .now) {
                review.requestedFeedback()
                await Analytics.shared.track("feedback_prompt_viewed")
                feedbackInvitation = true
            }
        }
    }

    @State private var showingFeedback = false
    private var canOfferPrompt: Bool {
        app.onboardingCompleted && tab == .home && scenePhase == .active
            && !showingSettings && !feedbackInvitation && !showingFeedback
            && !app.checkingPaywall && !app.showExistingAppleSubscription
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
