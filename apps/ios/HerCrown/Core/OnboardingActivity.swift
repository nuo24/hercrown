import ActivityKit
import Foundation

@MainActor
final class OnboardingActivity {
    static let shared = OnboardingActivity()
    private let defaults = UserDefaults.standard
    private let attemptedKey = "hc.onboardingActivityStarted"
    private var reportedUnavailable = false

    func update(step: Int) async {
        guard !defaults.bool(forKey: "hc.onboardingCompleted") else { await finish(); return }
        let state = OnboardingActivityAttributes.ContentState(completedSteps: min(max(step, 0), 13), totalSteps: 14)
        let existing = Activity<OnboardingActivityAttributes>.activities
        if !existing.isEmpty {
            for activity in existing where activity.activityState == .active || activity.activityState == .stale {
                await activity.update(ActivityContent(state: state, staleDate: activity.attributes.startedAt.addingTimeInterval(2 * 3600)))
            }
            return
        }
        // A dismissed or expired card stays dismissed. Never restart it on every app open.
        guard !defaults.bool(forKey: attemptedKey) else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            if !reportedUnavailable {
                reportedUnavailable = true
                await Analytics.shared.track("onboarding_activity_unavailable")
            }
            return
        }
        do {
            let now = Date()
            _ = try Activity.request(attributes: OnboardingActivityAttributes(startedAt: now),
                content: ActivityContent(state: state, staleDate: now.addingTimeInterval(2 * 3600)), pushType: nil)
            defaults.set(true, forKey: attemptedKey)
            await Analytics.shared.track("onboarding_activity_started")
        } catch {
            if !reportedUnavailable {
                reportedUnavailable = true
                await Analytics.shared.track("onboarding_activity_unavailable")
            }
        }
    }

    func finish() async {
        let activities = Activity<OnboardingActivityAttributes>.activities
        for activity in activities { await activity.end(nil, dismissalPolicy: .immediate) }
        if !activities.isEmpty { await Analytics.shared.track("onboarding_activity_ended") }
    }
}
