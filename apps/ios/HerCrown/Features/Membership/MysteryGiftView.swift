import SwiftUI
import StoreKit
import UIKit

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
    @State private var paperInFlight = false
    @State private var paperFlight = 0.0
    @State private var paperUnfold = 0.0
    @State private var paperSettled = 0.0
    @State private var invitationFade = 0.0
    @State private var offerSnapshot: UIImage?
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
                        .overlay(Circle().stroke(Theme.border(scheme)))
                        .frame(width: 44, height: 44)
                }.accessibilityLabel("Continue with free reading").disabled(busy)
            }.padding(.horizontal, 22).padding(.top, 8)
            ZStack {
                if revealed {
                    page(isOffer: true)
                } else {
                    page(isOffer: false)
                        .opacity(1 - invitationFade)
                        .allowsHitTesting(!opening)
                }
            }
            .overlayPreferenceValue(GiftLetterBounds.self) { anchor in
                GeometryReader { geometry in
                    ZStack {
                    Color.clear
                    if !revealed, paperInFlight, let anchor {
                        GiftUnfoldingSheet(source: geometry[anchor], target: geometry.size,
                            flight: paperFlight, unfolding: paperUnfold, settled: paperSettled) {
                                if let offerSnapshot {
                                    Image(uiImage: offerSnapshot).resizable()
                                } else {
                                    page(isOffer: true)
                                }
                            }
                            .transition(.identity)
                    }
                    }
                .onAppear { prepareOfferSnapshot(size: geometry.size) }
                .onChange(of: geometry.size) { _, size in prepareOfferSnapshot(size: size) }
                .onChange(of: scheme) { _, _ in prepareOfferSnapshot(size: geometry.size) }
                #if DEBUG
                .task {
                    if isPreview, ProcessInfo.processInfo.arguments.contains("--preview-mystery-gift-animate") {
                        try? await Task.sleep(for: .milliseconds(1000))
                        revealOffer()
                    }
                }
                #endif
                }
                .allowsHitTesting(false)
            }

        }
        .ignoresSafeArea(.container, edges: .bottom)
        .foregroundStyle(Theme.text(scheme)).background { GiftPaperMaterial().ignoresSafeArea() }.buttonStyle(.plain)
        .interactiveDismissDisabled(busy)
        .onDisappear { revealTask?.cancel() }
        .sheet(item: $legal) { page in SafariView(url: page.url) }
        .alert("Her Crown Plus", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(message ?? "") }
    }
    @MainActor private func prepareOfferSnapshot(size: CGSize) {
        guard size.width > 0, size.height > 0, !opening else { return }
        offerSnapshot = renderOfferSnapshot(size: size)
    }
    @MainActor func renderOfferSnapshot(size: CGSize) -> UIImage? {
        // Render once before the tap, from the same concrete layout as the interactive offer.
        let renderer = ImageRenderer(content: pageContents(isOffer: true, size: size)
            .background(GiftPaperMaterial())
            .frame(width: size.width, height: size.height)
            .foregroundStyle(Theme.text(scheme)).buttonStyle(.plain)
            .environment(\.colorScheme, scheme))
        renderer.scale = 3
        return renderer.uiImage
    }
    private func page(isOffer: Bool) -> some View {
        GeometryReader { geometry in
            ScrollView {
                pageContents(isOffer: isOffer, size: geometry.size)
            }
        }
    }
    // The moving paper and the interactive page render this exact same layout.
    // ImageRenderer must receive concrete dimensions, not a ScrollView/GeometryReader snapshot.
    private func pageContents(isOffer: Bool, size: CGSize) -> some View {
        VStack(spacing: 0) {
            hero(revealed: isOffer, foldedAspect: size.height / (size.width * 3),
                 width: min(430, size.width) - 44).padding(.top, isOffer ? 0 : 42)
            if isOffer { reveal } else { invitation }
            Spacer(minLength: 24)
            footer(revealed: isOffer)
        }
        .padding(.horizontal, 22).padding(.bottom, isOffer ? 14 : 12)
        .frame(maxWidth: 430).frame(maxWidth: .infinity)
        .frame(minHeight: size.height, alignment: .top)
    }
    private func hero(revealed: Bool, foldedAspect: Double, width: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Image("gift-cloud-bank").resizable().scaledToFit()
                .frame(width: width * 1.2, height: revealed ? 140 : 210)
                .opacity(0.75).offset(x: -width * 0.1)
            Image("gift-cosmos").resizable().scaledToFit()
                .frame(width: 70, height: revealed ? 78 : 80)
                .rotationEffect(.degrees(-16))
                .offset(x: width * 0.15, y: revealed ? 45 : 100)
            Group {
                if revealed {
                    Image("gift-open-book").resizable().scaledToFit()
                } else {
                    GiftEnvelopeIllustration(progress: flapProgress, letterLift: letterLift,
                        paperInFlight: paperInFlight, foldedAspect: foldedAspect, offerSnapshot: offerSnapshot)
                        .contentShape(Rectangle()).onTapGesture(perform: revealOffer)
                }
            }
            .frame(width: revealed ? 158 : 200, height: revealed ? 140 : 205)
            .rotationEffect(.degrees(-7))
            .offset(x: (width - (revealed ? 158 : 200)) / 2)
        }
        .frame(width: width, height: revealed ? 150 : 220, alignment: .topLeading)
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
                (Text("25% off\n").font(.serif(36)) + Text("your first year.").font(.serif(36, italic: true))).tracking(-0.7)
                Text("Get Her Crown Plus for less with a one-time\ndiscount on your annual plan.")
                    .font(.ui(15)).lineSpacing(4).foregroundStyle(Theme.muted(scheme))
                VStack(spacing: 12) {
                    Text("Her Crown Plus · Annual").font(.ui(12, weight: .medium))
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(terms.original).strikethrough().font(.ui(16)).foregroundStyle(Theme.muted(scheme))
                        Text(terms.firstYear).font(.serif(39)).tracking(-1)
                            .lineLimit(1).minimumScaleFactor(0.8).layoutPriority(1)
                        Text("for the first year").font(.ui(10)).foregroundStyle(Theme.muted(scheme))
                    }
                    Divider()
                    Text("You save \(terms.saving) on your first year.")
                        .font(.ui(11)).foregroundStyle(Theme.muted(scheme))
                }.padding(.horizontal, 18).padding(.vertical, 20).frame(maxWidth: .infinity)
                    .background(Theme.surface(scheme), in: RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.border(scheme), lineWidth: 1))
                    .padding(.top, 6)
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
            } else if let terms {
                Text("Then \(terms.renewal)/year. Auto-renews until canceled. No free trial.")
                    .font(.ui(9)).foregroundStyle(Theme.muted(scheme))
                    .multilineTextAlignment(.center).padding(.bottom, 8)
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
                withAnimation(.timingCurve(0.22, 0.65, 0.25, 1, duration: 0.56)) { flapProgress = 1 }
                do { try await Task.sleep(for: .milliseconds(580)) } catch { return }
                guard !Task.isCancelled else { return }
                withAnimation(.timingCurve(0.2, 0.7, 0.25, 1, duration: 0.3)) { letterLift = 1 }
                do { try await Task.sleep(for: .milliseconds(320)) } catch { return }
                guard !Task.isCancelled else { return }
                // Hand off the same folded-size sheet at its measured position, with no fade or resizing.
                paperInFlight = true
                do { try await Task.sleep(for: .milliseconds(20)) } catch { return }
                guard !Task.isCancelled else { return }
                withAnimation(.timingCurve(0.25, 0.1, 0.2, 1, duration: 0.45)) {
                    paperFlight = 1; invitationFade = 1
                }
                do { try await Task.sleep(for: .milliseconds(280)) } catch { return }
                guard !Task.isCancelled else { return }
                withAnimation(.timingCurve(0.3, 0.05, 0.2, 1, duration: 0.68)) { paperUnfold = 1 }
                do { try await Task.sleep(for: .milliseconds(480)) } catch { return }
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.32)) { paperSettled = 1 }
                do { try await Task.sleep(for: .milliseconds(350)) } catch { return }
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
            .background(Theme.accent(scheme), in: Capsule())
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}
