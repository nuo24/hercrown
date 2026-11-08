import AVFoundation
import SwiftUI

/// The partner's supplied silent demonstration. Native player layer, without playback chrome.
struct OnboardingDemoView: UIViewRepresentable {
    let reducedMotion: Bool
    func makeUIView(context: Context) -> DemoPlayerView { DemoPlayerView() }
    func updateUIView(_ view: DemoPlayerView, context: Context) {
        if reducedMotion { view.player.pause() } else { view.player.play() }
    }
    static func dismantleUIView(_ view: DemoPlayerView, coordinator: ()) { view.player.pause() }
}
final class DemoPlayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    let player = AVQueuePlayer()
    private var looper: AVPlayerLooper?
    init() {
        super.init(frame: .zero)
        if let url = Bundle.main.url(forResource: "onboarding-demo", withExtension: "mp4") {
            looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
        }
        player.isMuted = true
        (layer as? AVPlayerLayer)?.player = player
        (layer as? AVPlayerLayer)?.videoGravity = .resizeAspect
        backgroundColor = .white
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
