import ActivityKit
import SwiftUI
import WidgetKit

struct OnboardingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: OnboardingActivityAttributes.self) { context in
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Her Crown", systemImage: "book.closed")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Text("Continue setup").font(.system(size: 12, weight: .medium))
                }
                Text("Your little space for the Word.").font(.custom("Baskerville", size: 23))
                Text("Pick up where you left off.").font(.system(size: 13)).foregroundStyle(.secondary)
                ProgressView(value: Double(context.state.completedSteps), total: Double(context.state.totalSteps))
                    .tint(.primary)
                    .accessibilityLabel("Setup progress")
                    .accessibilityValue("Step \(context.state.completedSteps + 1) of \(context.state.totalSteps)")
            }
            .padding(18)
            .activityBackgroundTint(Color(white: 0.97))
            .activitySystemActionForegroundColor(.black)
            .foregroundStyle(.black)
            .widgetURL(URL(string: "hercrown://onboarding"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) { Image(systemName: "book.closed").accessibilityLabel("Her Crown") }
                DynamicIslandExpandedRegion(.trailing) { Text("Continue setup").font(.caption) }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("A little space for the Word.").font(.headline)
                        ProgressView(value: Double(context.state.completedSteps), total: Double(context.state.totalSteps))
                    }
                }
            } compactLeading: {
                Image(systemName: "book.closed")
            } compactTrailing: {
                Image(systemName: "arrow.right")
            } minimal: {
                Image(systemName: "book.closed")
            }
            .widgetURL(URL(string: "hercrown://onboarding"))
            .keylineTint(.white)
        }
    }
}
