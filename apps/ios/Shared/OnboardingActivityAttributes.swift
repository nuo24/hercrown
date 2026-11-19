import ActivityKit
import Foundation

/// Shared with the widget extension. Never put onboarding answers or personal details on the Lock Screen.
struct OnboardingActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var completedSteps: Int
        var totalSteps: Int
    }
    let startedAt: Date
}
