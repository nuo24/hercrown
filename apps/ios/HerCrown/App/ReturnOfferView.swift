import SwiftUI

struct ReturnOfferView: View {
    let firstYear: String
    let renewal: String
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
                VStack(spacing: 18) {
                    invitationArt
                        .padding(.bottom, 8)

                    Text("A little room to grow.")
                        .font(.serif(37, italic: true, relativeTo: .title))
                        .accessibilityAddTraits(.isHeader)
                    Text("Save $10 on your first year")
                        .font(.headline)
                    Text("Make more room for the Word with guided reading and thoughtful study.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted(scheme))
                        .frame(maxWidth: 270)

                    VStack(spacing: 5) {
                        Text("\(firstYear) for your first year")
                            .font(.serif(24, relativeTo: .title3))
                        Text("Then \(renewal)/year. Auto-renews until canceled.")
                            .font(.footnote)
                            .foregroundStyle(Theme.muted(scheme))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .surfaceCard(radius: 18)
                    .padding(.top, 8)
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
        .background {
            LinearGradient(colors: scheme == .dark ? [Color(hex: 0x202A26), Color(hex: 0x17191B)] :
                [Color(hex: 0xE4EDDF), Color(hex: 0xFCFAF4), Color(hex: 0xE0EDF5)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
        }
    }

    private var invitationArt: some View {
        ZStack {
            Image("cloud-bank")
                .resizable()
                .scaledToFit()
                .frame(width: 300)
                .opacity(scheme == .dark ? 0.25 : 0.75)
                .offset(y: 26)
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(hex: 0xFCF6E6))
                .frame(width: 146, height: 108)
                .rotationEffect(.degrees(-9))
                .shadow(color: .black.opacity(0.12), radius: 18, y: 9)
            Image("open-book")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 132)
                .offset(x: 6, y: 3)
            Image("cosmos")
                .resizable()
                .scaledToFit()
                .frame(width: 78, height: 80)
                .offset(x: -64, y: 43)
        }
        .frame(height: 188)
        .accessibilityHidden(true)
    }
}
