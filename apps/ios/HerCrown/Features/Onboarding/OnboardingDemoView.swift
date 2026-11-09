import AVFoundation
import SwiftUI

/// Native playback of the supplied recording, without visible playback controls. Reduce Motion keeps it paused.
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
        .onAppear { playback.setActive(isActive, autoplay: !reducedMotion) }
        .onChange(of: isActive) { _, active in playback.setActive(active, autoplay: !reducedMotion) }
        .onChange(of: reducedMotion) { _, reduced in playback.setActive(isActive, autoplay: !reduced) }
        .onDisappear { playback.setActive(false, autoplay: false) }
    }
}

@MainActor final class DemoPlayback: ObservableObject {
    let player = AVQueuePlayer()
    @Published var playing = false
    @Published var error: String?
    private var looper: AVPlayerLooper?
    private var status: NSKeyValueObservation?
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
        status = player.observe(\.currentItem, options: [.initial, .new]) { [weak self] _, _ in
            Task { @MainActor in
                guard let self else { return }
                if self.player.currentItem?.status == .failed { self.error = "The demonstration could not play." }
                else if self.wantsPlayback { self.player.playImmediately(atRate: 1.5) }
            }
        }
    }
    func setActive(_ active: Bool, autoplay: Bool) {
        let entering = active && !self.active
        self.active = active
        if !active {
            activation = UUID()
            pause()
        } else if entering {
            // Await an exact rewind before allowing the looper or autoplay to advance.
            pause()
            let request = UUID()
            activation = request
            player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in
                Task { @MainActor in
                    guard let self, finished, self.active, self.activation == request else { return }
                    if autoplay { self.play() }
                }
            }
        } else if !autoplay {
            pause()
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
