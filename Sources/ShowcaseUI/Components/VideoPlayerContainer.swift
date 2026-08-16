import SwiftUI
#if (os(iOS) || os(macOS)) && !SKIP
import AVKit
#endif
import SkipAV

public struct VideoPlayerContainer: View {
    public let player: AVPlayer?
    public let contentMode: ContentMode
    public let isVideoLoading: Bool
    
    public enum ContentMode {
        case fit, fill
    }
    
    public init(player: AVPlayer?, contentMode: ContentMode, isVideoLoading: Bool) {
        self.player = player
        self.contentMode = contentMode
        self.isVideoLoading = isVideoLoading
    }
    
    public var body: some View {
        ZStack {
            if let player = player {
                Rectangle()
                    .fill(Color.black)
                    .overlay {
                        #if os(Android) || SKIP_BRIDGE || SKIP
                        SkipAV.VideoPlayer(player: player)
                        #elseif os(iOS) || os(macOS)
                        NativeVideoPlayerView(player: player, videoGravity: contentMode == .fill ? .resizeAspectFill : .resizeAspect)
                        #else
                        Color.black
                        #endif
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            }
            
            if isVideoLoading {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            }
        }
    }
}
