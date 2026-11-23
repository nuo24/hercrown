import ActivityKit
import SwiftUI
import WidgetKit

struct OnboardingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: OnboardingActivityAttributes.self) { context in
            OnboardingActivityCard(completedSteps: context.state.completedSteps, totalSteps: context.state.totalSteps)
                .activityBackgroundTint(Color(red: 1, green: 249 / 255, blue: 251 / 255))
                .activitySystemActionForegroundColor(Color(red: 49 / 255, green: 34 / 255, blue: 43 / 255))
                .widgetURL(URL(string: "hercrown://onboarding"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image("her-crown-thorns").resizable().scaledToFit().frame(width: 24, height: 24)
                        Text("Her Crown").font(.caption.weight(.semibold))
                    }.accessibilityElement(children: .combine)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Label("Continue setup", systemImage: "arrow.right").font(.caption2)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("A little space for the Word.").font(.system(size: 13, weight: .medium, design: .rounded))
                        ProgressView(value: Double(context.state.completedSteps), total: Double(max(1, context.state.totalSteps)))
                    }
                }
            } compactLeading: {
                Image("her-crown-thorns").resizable().scaledToFit().frame(width: 20, height: 20).accessibilityLabel("Her Crown")
            } compactTrailing: {
                Image(systemName: "arrow.right")
            } minimal: {
                Image("her-crown-thorns").resizable().scaledToFit().accessibilityLabel("Her Crown")
            }
            .widgetURL(URL(string: "hercrown://onboarding"))
            .keylineTint(.white)
        }
    }
}
