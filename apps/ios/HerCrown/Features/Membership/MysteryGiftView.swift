import SwiftUI
import StoreKit

struct MysteryGiftView: View {
    let terms: MysteryGiftTerms?
    var isPreview = false
    let onPurchase: () async -> String?
    let onRestore: () async -> String?
    let onClose: () -> Void
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed: Bool = {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("--preview-mystery-gift-revealed")
        #else
        false
        #endif
    }()
    @State private var busy = false
    @State private var message: String?
    @State private var legal: LegalPage?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Her Crown Plus").font(.ui(12, weight: .medium))
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark").font(.system(size: 12, weight: .semibold)).frame(width: 32, height: 32)
                        .background(Theme.surface(scheme), in: Circle()).overlay(Circle().stroke(Theme.border(scheme)))
                        .frame(width: 44, height: 44)
                }.accessibilityLabel("Continue with free reading").disabled(busy)
            }.padding(.horizontal, 22).padding(.top, 8)
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        hero.padding(.top, revealed ? 0 : 42)
                        if revealed { reveal } else { invitation }
                        Spacer(minLength: 24)
                        footer
                    }
                    .padding(.horizontal, 22).padding(.bottom, revealed ? 16 : 4)
                    .frame(maxWidth: 430).frame(maxWidth: .infinity)
                    .frame(minHeight: geometry.size.height, alignment: .top)
                }
            }
        }
        .foregroundStyle(Theme.text(scheme)).background(Theme.canvas(scheme).ignoresSafeArea()).buttonStyle(.plain)
        .interactiveDismissDisabled(busy)
        .sheet(item: $legal) { page in SafariView(url: page.url) }
        .alert("Her Crown Plus", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(message ?? "") }
    }
    private var hero: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Image("gift-cloud-bank").resizable().scaledToFit()
                    .frame(width: geometry.size.width * 1.2, height: revealed ? 140 : 210)
                    .opacity(0.75).offset(x: -geometry.size.width * 0.1)
                Image("gift-cosmos").resizable().scaledToFit()
                    .frame(width: 70, height: revealed ? 78 : 80)
                    .rotationEffect(.degrees(-16))
                    .offset(x: geometry.size.width * 0.15, y: revealed ? 45 : 100)
                Image(revealed ? "gift-open-book" : "gift-prayer-envelope").resizable().scaledToFit()
                    .frame(width: revealed ? 158 : 200, height: revealed ? 140 : 205)
                    .rotationEffect(.degrees(-7))
                    .offset(x: (geometry.size.width - (revealed ? 158 : 200)) / 2)
            }
        }
        .frame(height: revealed ? 150 : 220)
        .accessibilityHidden(true)
    }
    private var invitation: some View {
        VStack(spacing: 12) {
            (Text("We have a gift\n") + Text("for you.").italic()).font(.serif(38, weight: .semibold)).tracking(-0.7)
            Text("Before you continue with free reading, we’d like to share a special offer with you.")
                .font(.ui(14, weight: .medium)).lineSpacing(4).foregroundStyle(Theme.muted(scheme)).frame(maxWidth: 290)
        }.multilineTextAlignment(.center).padding(.top, 18)
    }
    private var reveal: some View {
        VStack(spacing: 12) {
            Text("YOUR ONE-TIME OFFER").font(.ui(10, weight: .medium)).tracking(1.3).foregroundStyle(Theme.muted(scheme)).padding(.top, 14)
            if let terms {
                (Text("25% off\n") + Text("your first year.").italic()).font(.serif(36)).tracking(-0.7)
                Text("Get Her Crown Plus for less with a one-time discount on your annual plan.")
                    .font(.ui(14)).lineSpacing(4).foregroundStyle(Theme.muted(scheme))
                VStack(spacing: 12) {
                    Text("Her Crown Plus · Annual").font(.ui(12, weight: .medium))
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(terms.original).strikethrough().font(.ui(16)).foregroundStyle(Theme.muted(scheme))
                        Text(terms.firstYear).font(.serif(39)).tracking(-1)
                        Text("for the first year").font(.ui(10)).foregroundStyle(Theme.muted(scheme))
                    }
                    Divider()
                    Text("You save \(terms.saving) on your first year.").font(.ui(11)).foregroundStyle(Theme.muted(scheme))
                }.padding(18).frame(maxWidth: .infinity).background(Theme.surface(scheme), in: RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.border(scheme))).padding(.top, 6)
            } else {
                Text("This offer isn’t available right now.").font(.serif(30))
                Text("You can continue with free Bible reading.").font(.ui(14)).foregroundStyle(Theme.muted(scheme))
            }
        }.multilineTextAlignment(.center)
    }
    private var footer: some View {
        VStack(spacing: 0) {
            if revealed, let terms {
                Text("\(terms.firstYear) for the first year, then \(terms.renewal) per year. No free trial with this offer. Payment is charged to your Apple Account when confirmed. Renews automatically unless canceled at least 24 hours before renewal. Manage or cancel in App Store account settings.")
                    .font(.ui(10)).lineSpacing(3).foregroundStyle(Theme.muted(scheme)).multilineTextAlignment(.center).padding(.bottom, 12)
            }
            if !revealed {
                Button("Reveal your offer") {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { revealed = true }
                    if !isPreview { Task { await Analytics.shared.track("mystery_gift_revealed") } }
                }.buttonStyle(CapsuleButtonStyle())
            } else if terms != nil {
                Button { perform(onPurchase) } label: {
                    if busy { ProgressView() } else { Text("Continue with 25% off") }
                }.buttonStyle(CapsuleButtonStyle()).disabled(busy || isPreview)
                .accessibilityHint(isPreview ? "Design preview. Purchases are disabled." : "")
            }
            Button("Continue with free reading", action: onClose).font(.ui(12)).foregroundStyle(Theme.muted(scheme)).frame(minHeight: 44).disabled(busy)
            if revealed {
                HStack(spacing: 18) {
                    Button("Restore purchases") { perform(onRestore) }.disabled(busy || isPreview)
                    Button("Terms") { legal = .terms }
                    Button("Privacy") { legal = .privacy }
                }.font(.ui(10)).foregroundStyle(Theme.muted(scheme)).frame(minHeight: 44)
            }
        }
        .overlay(alignment: .top) {
            if isPreview {
                Text("Design preview · purchases disabled").font(.ui(9))
                    .foregroundStyle(Theme.muted(scheme)).offset(y: -20)
                    .allowsHitTesting(false)
            }
        }
    }
    private func perform(_ action: @escaping () async -> String?) {
        guard !busy, !isPreview else { return }
        busy = true
        Task { message = await action(); busy = false }
    }
}
