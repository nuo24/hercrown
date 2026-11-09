import AVFoundation
import SwiftUI

/// Native muted playback of the supplied recording, without visible playback controls.
struct OnboardingDemoView: View {
    let reducedMotion: Bool
    let isActive: Bool
    @StateObject private var playback = DemoPlayback()
    var body: some View {
        ZStack(alignment: .center) {
            DemoPlayerLayer(player: playback.player)
                .overlay(alignment: .top) {
                    HStack(spacing: 4) {
                        Text("9:41").font(.system(size: 6, weight: .semibold))
                        Spacer(minLength: 0)
                        Capsule().fill(.black).frame(width: 51, height: 13)
                        Spacer(minLength: 0)
                        Image(systemName: "wifi").font(.system(size: 6))
                        Image(systemName: "battery.100").font(.system(size: 7))
                    }.padding(.horizontal, 10).frame(height: 25).background(.white)
                        .allowsHitTesting(false).accessibilityHidden(true)
                }
            if let error = playback.error {
                Text(error).font(.ui(11)).padding(12).frame(maxWidth: .infinity).background(.white)
            }
        }
        .onAppear { playback.setActive(isActive, autoplay: true) }
        .onChange(of: isActive) { _, active in playback.setActive(active, autoplay: true) }
        .onChange(of: reducedMotion) { _, reduced in playback.setActive(isActive, autoplay: true) }
        .onDisappear { playback.setActive(false, autoplay: false) }
    }
}

@MainActor final class DemoPlayback: ObservableObject {
    let player = AVQueuePlayer()
    @Published var playing = false
    @Published var error: String?
    private var looper: AVPlayerLooper?
    private var currentItemObservation: NSKeyValueObservation?
    private var status: NSKeyValueObservation?
    private var needsRewind = true
    private var seeking = false
    private var wantsPlayback = false
    private var active = false
    private var activation = UUID()
    init() {
        player.isMuted = true
        player.automaticallyWaitsToMinimizeStalling = false
        guard let url = Bundle.main.url(forResource: "onboarding-demo", withExtension: "mp4") else {
            error = "The demonstration could not load."; return
        }
        let item = AVPlayerItem(url: url)
        // The supplied reader, notes and study demonstration keeps its complete sequence.
        looper = AVPlayerLooper(player: player, templateItem: item)
        currentItemObservation = player.observe(\.currentItem, options: [.initial, .new]) { [weak self] _, _ in
            Task { @MainActor in self?.observeCurrentItem() }
        }
    }
    private func observeCurrentItem() {
        status = player.currentItem?.observe(\.status, options: [.initial, .new]) { [weak self] _, _ in
            Task { @MainActor in self?.startWhenReady() }
        }
    }
    func setActive(_ active: Bool, autoplay: Bool) {
        let entering = active && !self.active
        self.active = active
        wantsPlayback = active && autoplay
        if !active {
            activation = UUID()
            seeking = false
            needsRewind = true
            player.pause(); playing = false
            return
        }
        if entering { needsRewind = true }
        if !wantsPlayback { player.pause(); playing = false }
        startWhenReady()
    }
    private func startWhenReady() {
        guard let item = player.currentItem else { return }
        if item.status == .failed { error = "The demonstration could not play."; return }
        // A seek before readiness can return false on a physical device. Wait for
        // the item-status transition instead of abandoning autoplay permanently.
        guard active, item.status == .readyToPlay, !seeking else { return }
        guard needsRewind else { if wantsPlayback { play() }; return }
        seeking = true
        let request = UUID()
        activation = request
        player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in
            Task { @MainActor in
                guard let self, self.activation == request else { return }
                self.seeking = false
                guard self.active else { return }
                self.needsRewind = !finished
                if finished { if self.wantsPlayback { self.play() } }
                else { self.startWhenReady() }
            }
        }
    }
    func play() { wantsPlayback = true; playing = true; player.playImmediately(atRate: 1.5) }
    func pause() { wantsPlayback = false; playing = false; player.pause() }
}
private struct DemoPlayerLayer: UIViewRepresentable {
    let player: AVQueuePlayer
    func makeUIView(context: Context) -> DemoLayerView { let v = DemoLayerView(); v.playerLayer.player = player; return v }
    func updateUIView(_ view: DemoLayerView, context: Context) { view.playerLayer.player = player }
}
private final class DemoLayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    override init(frame: CGRect) { super.init(frame: frame); playerLayer.videoGravity = .resizeAspect; backgroundColor = .white }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
