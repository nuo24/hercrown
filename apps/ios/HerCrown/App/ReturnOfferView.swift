import SwiftUI

struct ReturnOfferView: View {
    let firstYear: String
    let renewal: String
    var savings = "$10"
    var busy = false
    let onClaim: () -> Void
    let onClose: () -> Void

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 0) {
            Text("Her Crown Plus")
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.4)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .trailing) {
                    IconButton(systemName: "xmark", label: "Close offer", action: onClose)
                        .disabled(busy)
                }
                .frame(minHeight: 48)
                .padding(.horizontal, 24)

            ScrollView {
                VStack(spacing: 14) {
                    Image.illustration("open-book")
                        .resizable().scaledToFit().frame(width: 100, height: 88)
                        .accessibilityHidden(true)

                    Text("A little more room to grow.")
                        .font(.serif(32, relativeTo: .title))
                        .accessibilityAddTraits(.isHeader)
                    Text("Reading plans and every study tool, made for your daily walk.")
                        .font(.ui(14))
                        .foregroundStyle(Theme.muted(scheme))
                        .frame(maxWidth: 275)

                    VStack(spacing: 6) {
                        Text("Save \(savings) on your first year")
                            .font(.ui(12, weight: .medium))
                        Text("\(firstYear) for your first year")
                            .font(.serif(23, relativeTo: .title3))
                        Text("Then \(renewal)/year. Auto-renews until canceled.")
                            .font(.ui(12))
                            .foregroundStyle(Theme.muted(scheme))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.border(scheme)))
                    .padding(.top, 10)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: 430)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
            }

            VStack(spacing: 4) {
                Button(action: onClaim) {
                    if busy { ProgressView() }
                    else { Text("Claim my first year") }
                }
                .buttonStyle(CapsuleButtonStyle())
                Button("Keep reading", action: onClose)
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted(scheme))
                    .frame(maxWidth: .infinity, minHeight: 44)
                HStack(spacing: 16) {
                    Link("Terms", destination: AppConfig.apiBaseURL.appending(path: "legal/terms"))
                    Link("Privacy", destination: AppConfig.apiBaseURL.appending(path: "legal/privacy"))
                }
                .font(.caption)
                .foregroundStyle(Theme.muted(scheme))
                .padding(.bottom, 8)
            }
            .disabled(busy)
            .frame(maxWidth: 430)
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 6)
        }
        .foregroundStyle(Theme.text(scheme))
        .background(Theme.canvas(scheme).ignoresSafeArea())
    }
}
