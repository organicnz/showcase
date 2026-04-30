import SwiftUI
#if os(iOS) || os(macOS)
import AVKit
#endif

#if os(iOS)
public struct NativeVideoPlayerView: UIViewControllerRepresentable {
    public let player: AVPlayer?
    public let videoGravity: AVLayerVideoGravity
    
    public init(player: AVPlayer?, videoGravity: AVLayerVideoGravity) {
        self.player = player
        self.videoGravity = videoGravity
    }
    
    public func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.videoGravity = videoGravity
        controller.showsPlaybackControls = false
        controller.allowsVideoFrameAnalysis = false // Optimization
        return controller
    }
    
    public func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
        uiViewController.videoGravity = videoGravity
    }
}
#elseif os(macOS)
public struct NativeVideoPlayerView: NSViewRepresentable {
    public let player: AVPlayer?
    public let videoGravity: AVLayerVideoGravity
    
    public init(player: AVPlayer?, videoGravity: AVLayerVideoGravity) {
        self.player = player
        self.videoGravity = videoGravity
    }
    
    public func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.player = player
        view.controlsStyle = .none
        return view
    }
    
    public func updateNSView(_ nsView: AVPlayerView, context: Context) {
        nsView.player = player
    }
}
#endif
