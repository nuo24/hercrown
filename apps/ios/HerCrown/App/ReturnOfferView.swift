import SwiftUI

struct ReturnOfferView: View {
    let firstYear: String
    let renewal: String
    var busy = false
    let onClaim: () -> Void
    let onClose: () -> Void
    let onRestore: () -> Void

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed: Bool = {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("--preview-return-offer-revealed")
        #else
        false
        #endif
    }()

    var body: some View {
        Group {
            if revealed { offer }
            else { invitation }
        }
        .buttonStyle(.plain)
        .foregroundStyle(Theme.text(scheme))
        .background(Theme.canvas(scheme).ignoresSafeArea())
    }

    private var invitation: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Her Crown Plus").font(.ui(12, weight: .medium))
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark").font(.system(size: 16))
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Continue with free reading")
            }
            Spacer(minLength: 16)
            Image.illustration("prayer-envelope")
                .resizable().scaledToFit()
                .frame(maxWidth: 270, maxHeight: 230)
                .accessibilityHidden(true)
            VStack(spacing: 12) {
                Text("A little room to grow.")
                    .font(.serif(34, relativeTo: .largeTitle))
                    .accessibilityAddTraits(.isHeader)
                Text("An invitation to go deeper,\nat a gentler price.")
                    .font(.ui(15)).lineSpacing(4)
                    .foregroundStyle(Theme.muted(scheme))
            }
            .multilineTextAlignment(.center)
            Spacer(minLength: 16)
            Button("Reveal your invitation") {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.35)) { revealed = true }
            }
            .buttonStyle(CapsuleButtonStyle())
            Button("Continue with free reading", action: onClose)
                .font(.ui(13)).foregroundStyle(Theme.muted(scheme))
                .frame(minHeight: 44)
        }
        .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 24)
        .frame(maxWidth: 430).frame(maxWidth: .infinity)
        .transition(.opacity)
    }

    private var offer: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Button {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.35)) { revealed = false }
                    } label: {
                        Label("Back", systemImage: "arrow.left")
                            .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    Spacer()
                    Button(action: onClose) {
                        Text("Done")
                            .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
                            .contentShape(Rectangle())
                    }
                }
                .font(.ui(12, weight: .medium))

                Text("Her Crown Plus")
                    .font(.ui(12, weight: .medium))
                    .foregroundStyle(Theme.muted(scheme))

                introduction
                    .padding(.top, 4)
                    .padding(.bottom, 32)

                VStack(alignment: .leading, spacing: 14) {
                    benefit("journal", "Read with a little guidance")
                    benefit("magnifier", "Explore deeper understanding")
                    benefit("intention-heart", "Make space for your faith")
                }

                planCard
                    .padding(.top, 24)
                    .padding(.bottom, 24)

                Button(action: onClaim) {
                    Group {
                        if busy { ProgressView().tint(Theme.canvas(scheme)) }
                        else { Text("Continue") }
                    }
                    .font(.ui(15, weight: .medium))
                    .foregroundStyle(Theme.canvas(scheme))
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Theme.accent(scheme), in: RoundedRectangle(cornerRadius: 8))
                }

                Text("\(firstYear) for your first year, then \(renewal)/year. Apple charges your account at confirmation. Renews automatically until canceled. Manage or cancel in Apple Settings.")
                    .font(.ui(11, relativeTo: .footnote))
                    .lineSpacing(2)
                    .foregroundStyle(Theme.muted(scheme))
                    .padding(.top, 16)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) { readingActions }
                        .fixedSize(horizontal: true, vertical: false)
                    VStack(alignment: .leading, spacing: 0) { readingActions }
                }
                .font(.ui(12, weight: .medium))
                .padding(.top, 16)

                HStack(spacing: 16) {
                    Link("Terms", destination: AppConfig.apiBaseURL.appending(path: "legal/terms"))
                    Link("Privacy", destination: AppConfig.apiBaseURL.appending(path: "legal/privacy"))
                }
                .font(.ui(11))
                .foregroundStyle(Theme.muted(scheme))
            }
            .frame(maxWidth: 430, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity)
        }
        .disabled(busy)
        .transition(.opacity)
    }

    private var introduction: some View {
        VStack(spacing: 12) {
            Image.illustration("open-book")
                .resizable().scaledToFit().frame(width: 88, height: 88)
                .accessibilityHidden(true)
            Text("A little more room to grow.")
                .font(.serif(30, relativeTo: .title))
                .accessibilityAddTraits(.isHeader)
            Text("Reading plans and every study tool, made for your daily walk.")
                .font(.ui(14))
                .lineSpacing(4)
                .foregroundStyle(Theme.muted(scheme))
                .frame(maxWidth: 330)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    private var planCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "largecircle.fill.circle")
                .font(.system(size: 18))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text("A gentle invitation · \(firstYear)")
                    .font(.ui(16, weight: .medium))
                Text("Billed once per year · one-time offer")
                    .font(.ui(12))
                    .foregroundStyle(Theme.muted(scheme))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(Theme.surface(scheme), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.text(scheme), lineWidth: 2))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isSelected)
    }

    @ViewBuilder
    private var readingActions: some View {
        Button("Continue with free reading", action: onClose)
            .frame(minHeight: 44)
        Button("Restore Purchases", action: onRestore)
            .frame(minHeight: 44)
    }

    private func benefit(_ asset: String, _ title: String) -> some View {
        HStack(spacing: 14) {
            Image.illustration(asset)
                .resizable().scaledToFit().frame(width: 40, height: 40)
                .accessibilityHidden(true)
            Text(title).font(.ui(14))
        }
    }
}
