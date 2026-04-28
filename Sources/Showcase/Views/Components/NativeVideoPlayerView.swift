import SwiftUI
import AVKit

#if os(iOS)
struct NativeVideoPlayerView: UIViewControllerRepresentable {
    let player: AVPlayer?
    let videoGravity: AVLayerVideoGravity
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.videoGravity = videoGravity
        controller.showsPlaybackControls = false
        controller.allowsVideoFrameAnalysis = false // Optimization
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
        uiViewController.videoGravity = videoGravity
    }
}
#elseif os(macOS)
struct NativeVideoPlayerView: NSViewRepresentable {
    let player: AVPlayer?
    let videoGravity: AVLayerVideoGravity
    
    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.player = player
        view.controlsStyle = .none
        return view
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        nsView.player = player
    }
}
#endif
