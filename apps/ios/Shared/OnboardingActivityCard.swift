import SwiftUI

/// Shared by the actual Live Activity and its explicitly labelled native design preview.
struct OnboardingActivityCard: View {
    let completedSteps: Int
    let totalSteps: Int
    private let ink = Color(red: 49 / 255, green: 34 / 255, blue: 43 / 255)
    private let muted = Color(red: 101 / 255, green: 79 / 255, blue: 91 / 255)
    private var progress: Double { min(1, max(0, Double(completedSteps) / Double(max(1, totalSteps)))) }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image("her-crown-thorns").resizable().scaledToFit().frame(width: 24, height: 24).accessibilityHidden(true)
                Text("Her Crown").font(.system(size: 12, weight: .semibold, design: .rounded))
                Spacer(minLength: 8)
                Text("A QUIET BEGINNING").font(.system(size: 8, weight: .medium, design: .rounded)).tracking(0.8).foregroundStyle(muted)
            }
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("A little space for the Word.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .lineLimit(1).minimumScaleFactor(0.8)
                    Text("Pick up where you left off.")
                        .font(.system(size: 12, design: .rounded)).foregroundStyle(muted)
                    Link(destination: URL(string: "hercrown://onboarding")!) {
                        HStack(spacing: 7) {
                            Text("Continue setup")
                            Image(systemName: "arrow.right").font(.system(size: 10, weight: .semibold))
                        }
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14).frame(minHeight: 36)
                        .background(ink, in: Capsule())
                    }
                    .padding(.top, 4)
                    .accessibilityLabel("Continue Her Crown setup")
                }
                Spacer(minLength: 0)
                Image("gift-open-book").resizable().scaledToFit()
                    .frame(width: 65, height: 70).rotationEffect(.degrees(-9))
                    .accessibilityHidden(true)
            }
            ProgressView(value: progress)
                .tint(ink).scaleEffect(x: 1, y: 0.7)
                .accessibilityLabel("Setup progress")
                .accessibilityValue("Step \(min(max(1, completedSteps + 1), max(1, totalSteps))) of \(max(1, totalSteps))")
        }
        .padding(14)
        .foregroundStyle(ink)
        .background(Color(red: 1, green: 249 / 255, blue: 251 / 255))
    }
}
