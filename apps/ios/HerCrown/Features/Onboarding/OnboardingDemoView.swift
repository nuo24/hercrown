import AVFoundation
import SwiftUI

/// Native playback of the supplied recording, with an explicit control when autoplay is suppressed.
struct OnboardingDemoView: View {
    let reducedMotion: Bool
    let isActive: Bool
    @StateObject private var playback = DemoPlayback()
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            DemoPlayerLayer(player: playback.player)
            if let error = playback.error {
                Text(error).font(.ui(11)).padding(12).frame(maxWidth: .infinity).background(.white)
            } else {
                Button {
                    if playback.playing { playback.pause() } else { playback.play() }
                } label: {
                    Image(systemName: playback.playing ? "pause.fill" : "play.fill")
                        .font(.system(size: 13)).frame(width: 44, height: 44)
                        .background(.regularMaterial, in: Circle())
                }.buttonStyle(.plain).padding(5)
                    .accessibilityLabel(playback.playing ? "Pause demonstration" : "Play demonstration")
            }
        }
        .onAppear { playback.setActive(isActive, autoplay: !reducedMotion) }
        .onChange(of: isActive) { _, active in playback.setActive(active, autoplay: !reducedMotion) }
        .onChange(of: reducedMotion) { _, reduced in playback.setActive(isActive, autoplay: !reduced) }
        .onDisappear { playback.pause() }
    }
}

@MainActor final class DemoPlayback: ObservableObject {
    let player = AVQueuePlayer()
    @Published var playing = false
    @Published var error: String?
    private var looper: AVPlayerLooper?
    private var status: NSKeyValueObservation?
    private var wantsPlayback = false
    init() {
        player.isMuted = true
        player.automaticallyWaitsToMinimizeStalling = false
        guard let url = Bundle.main.url(forResource: "onboarding-demo", withExtension: "mp4") else {
            error = "The demonstration could not load."; return
        }
        let item = AVPlayerItem(url: url)
        // The supplied 10.52-second recording ends with a long still hold.
        // Loop its first four seconds, which contain the actual scrolling demonstration.
        looper = AVPlayerLooper(player: player, templateItem: item, timeRange: CMTimeRange(start: .zero, duration: CMTime(seconds: 4, preferredTimescale: 600)))
        status = player.observe(\.currentItem, options: [.initial, .new]) { [weak self] _, _ in
            Task { @MainActor in
                guard let self else { return }
                if self.player.currentItem?.status == .failed { self.error = "The demonstration could not play." }
                else if self.wantsPlayback { self.player.play() }
            }
        }
    }
    func setActive(_ active: Bool, autoplay: Bool) { if active && autoplay { play() } else { pause() } }
    func play() { wantsPlayback = true; playing = true; player.play() }
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
