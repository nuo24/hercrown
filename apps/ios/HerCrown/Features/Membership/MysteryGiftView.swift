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
    @State private var opening = false
    @State private var flapProgress = 0.0
    @State private var letterLift = 0.0
    @State private var paperExpanded = false
    @State private var paperSettled = false
    @State private var offerInk = 0.0
    @Namespace private var paperNamespace
    @State private var revealTask: Task<Void, Never>?
    @State private var busy = false
    @State private var message: String?
    @State private var legal: LegalPage?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Her Crown Plus").font(.ui(12, weight: .medium))
                    if isPreview { Text("Design preview · purchases disabled").font(.ui(8)).foregroundStyle(Theme.muted(scheme)) }
                }
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark").font(.system(size: 12, weight: .semibold)).frame(width: 32, height: 32)
                        .background(Theme.surface(scheme), in: Circle()).overlay(Circle().stroke(Theme.border(scheme)))
                        .frame(width: 44, height: 44)
                }.accessibilityLabel("Continue with free reading").disabled(busy)
            }.padding(.horizontal, 22).padding(.top, 8)
            ZStack {
                if revealed {
                    page(isOffer: true)
                } else {
                    page(isOffer: false)
                        .opacity(paperExpanded ? 0 : 1)
                        .allowsHitTesting(!opening)
                    if paperExpanded {
                        GeometryReader { geometry in
                            ZStack {
                                // The paper itself travels from the envelope to this exact surface.
                                Theme.canvas(scheme)
                                    .overlay {
                                        GiftLetterPaper().opacity(paperSettled ? 0 : 1)
                                    }
                                    .overlay {
                                        LinearGradient(colors: [.clear, .black.opacity(0.10), .white.opacity(0.22), .clear],
                                            startPoint: .top, endPoint: .bottom)
                                            .frame(height: 26).opacity(paperSettled ? 0 : 1)
                                    }
                                    .matchedGeometryEffect(id: "gift-offer-paper", in: paperNamespace)
                                page(isOffer: true).opacity(offerInk)
                                    .allowsHitTesting(false)
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height)
                        }.transition(.identity).zIndex(5)
                    }
                }
            }

        }
        .ignoresSafeArea(.container, edges: .bottom)
        .foregroundStyle(Theme.text(scheme)).background(Theme.canvas(scheme).ignoresSafeArea()).buttonStyle(.plain)
        .interactiveDismissDisabled(busy)
        .onDisappear { revealTask?.cancel() }
        .sheet(item: $legal) { page in SafariView(url: page.url) }
        .alert("Her Crown Plus", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(message ?? "") }
    }
    private func page(isOffer: Bool) -> some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    hero(revealed: isOffer).padding(.top, isOffer ? 0 : 42)
                    if isOffer { reveal } else { invitation }
                    Spacer(minLength: 24)
                    footer(revealed: isOffer)
                }
                .padding(.horizontal, 22).padding(.bottom, isOffer ? 14 : 12)
                .frame(maxWidth: 430).frame(maxWidth: .infinity)
                .frame(minHeight: geometry.size.height, alignment: .top)
            }
        }
    }
    private func hero(revealed: Bool) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Image("gift-cloud-bank").resizable().scaledToFit()
                    .frame(width: geometry.size.width * 1.2, height: revealed ? 140 : 210)
                    .opacity(0.75).offset(x: -geometry.size.width * 0.1)
                Image("gift-cosmos").resizable().scaledToFit()
                    .frame(width: 70, height: revealed ? 78 : 80)
                    .rotationEffect(.degrees(-16))
                    .offset(x: geometry.size.width * 0.15, y: revealed ? 45 : 100)
                Group {
                    if revealed {
                        Image("gift-open-book").resizable().scaledToFit()
                    } else {
                        GiftEnvelopeIllustration(progress: flapProgress, letterLift: letterLift,
                                paperExpanded: paperExpanded, paperNamespace: paperNamespace)
                            .contentShape(Rectangle())
                            .onTapGesture(perform: revealOffer)
                    }
                }
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
            (Text("We have a gift\n") + Text("for you.").italic()).font(.serif(38)).tracking(-0.7)
            Text("Before you continue with free reading, we’d like to share a special offer with you.")
                .font(.ui(14, weight: .medium)).lineSpacing(4).foregroundStyle(Theme.muted(scheme)).frame(maxWidth: 290)
        }.multilineTextAlignment(.center).padding(.top, 18)
    }
    private var reveal: some View {
        VStack(spacing: 12) {
            Text("YOUR ONE-TIME OFFER").font(.ui(10, weight: .medium)).tracking(1.3).foregroundStyle(Theme.muted(scheme)).padding(.top, 14)
            if let terms {
                (Text("25% off\n").font(.serif(36, weight: .semibold)) + Text("your first year.").font(.serif(36, italic: true))).tracking(-0.7)
                Text("Get Her Crown Plus for less with a one-time\ndiscount on your annual plan.")
                    .font(.ui(15)).lineSpacing(4).foregroundStyle(Theme.muted(scheme))
                VStack(spacing: 12) {
                    Text("Her Crown Plus · Annual").font(.ui(12, weight: .medium))
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(terms.original).strikethrough().font(.ui(16)).foregroundStyle(Theme.muted(scheme))
                        Text(terms.firstYear).font(.serif(39)).tracking(-1)
                        Text("for the first year").font(.ui(10)).foregroundStyle(Theme.muted(scheme))
                    }
                    Divider()
                    Text("You save \(terms.saving) on your first year.").font(.ui(11)).foregroundStyle(Theme.muted(scheme))
                    Text("Then \(terms.renewal)/year. Auto-renews until canceled. No free trial.")
                        .font(.ui(10)).foregroundStyle(Theme.muted(scheme))
                }.padding(.horizontal, 18).padding(.vertical, 24).frame(maxWidth: .infinity, minHeight: 160).background(Theme.surface(scheme), in: RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.border(scheme))).padding(.top, 6)
            } else {
                Text("This offer isn’t available right now.").font(.serif(30))
                Text("You can continue with free Bible reading.").font(.ui(14)).foregroundStyle(Theme.muted(scheme))
            }
        }.multilineTextAlignment(.center)
    }
    private func footer(revealed: Bool) -> some View {
        VStack(spacing: 0) {
            if !revealed {
                Button("Reveal your offer", action: revealOffer)
                    .buttonStyle(GiftOfferButtonStyle()).disabled(opening)
            } else if terms != nil {
                Button { perform(onPurchase) } label: {
                    if busy { ProgressView() } else { Text("Continue with 25% off") }
                }.buttonStyle(GiftOfferButtonStyle()).disabled(busy || isPreview)
                .accessibilityHint(isPreview ? "Design preview. Purchases are disabled." : "")
            }
            Button(action: onClose) {
                Text("Continue with free reading").font(.ui(12))
                    .offset(y: revealed ? 0 : -4)
                    .frame(maxWidth: .infinity, minHeight: revealed ? 34 : 44)
                    .contentShape(Rectangle())
            }.foregroundStyle(Theme.muted(scheme)).disabled(busy)
            if revealed {
                HStack(spacing: 18) {
                    Button("Restore purchases") { perform(onRestore) }.disabled(busy || isPreview)
                    Button("Terms") { legal = .terms }
                    Button("Privacy") { legal = .privacy }
                }.font(.ui(10)).foregroundStyle(Theme.muted(scheme)).frame(minHeight: 24)
            }
        }
    }
    private func revealOffer() {
        guard !opening, !revealed else { return }
        revealTask = Task { @MainActor in
            if reduceMotion {
                withAnimation(.easeOut(duration: 0.15)) { revealed = true }
            } else {
                opening = true
                withAnimation(.timingCurve(0.22, 0.65, 0.25, 1, duration: 0.62)) { flapProgress = 1 }
                do { try await Task.sleep(for: .milliseconds(650)) } catch { return }
                guard !Task.isCancelled else { return }
                withAnimation(.timingCurve(0.2, 0.7, 0.25, 1, duration: 0.38)) { letterLift = 1 }
                do { try await Task.sleep(for: .milliseconds(400)) } catch { return }
                guard !Task.isCancelled else { return }
                withAnimation(.timingCurve(0.3, 0.05, 0.2, 1, duration: 0.65)) { paperExpanded = true }
                do { try await Task.sleep(for: .milliseconds(180)) } catch { return }
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.48)) { paperSettled = true }
                do { try await Task.sleep(for: .milliseconds(250)) } catch { return }
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.3)) { offerInk = 1 }
                do { try await Task.sleep(for: .milliseconds(340)) } catch { return }
                guard !Task.isCancelled else { return }
                // Replace the finished paper with the identical interactive offer, without a visual swap.
                var transaction = Transaction(); transaction.disablesAnimations = true
                withTransaction(transaction) { revealed = true }
            }
            if !isPreview { await Analytics.shared.track("mystery_gift_revealed") }
        }
    }
    private func perform(_ action: @escaping () async -> String?) {
        guard !busy, !isPreview else { return }
        busy = true
        Task { message = await action(); busy = false }
    }
}

/// Reference footer: 46-point primary, followed by free reading and optional legal links.
private struct GiftOfferButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.ui(13, weight: .medium))
            .foregroundStyle(Theme.pink(scheme) ? Color(hex: 0xFFF9FB) : scheme == .dark ? Color(hex: 0x131313) : .white)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(Theme.text(scheme), in: Capsule())
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}
