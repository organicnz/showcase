import SwiftUI
import AVKit
import SkipAV

struct VideoPlayerContainer: View {
    let player: AVPlayer?
    let contentMode: ContentMode
    let isVideoLoading: Bool
    
    enum ContentMode {
        case fit, fill
    }
    
    var body: some View {
        ZStack {
            if let player = player {
                Rectangle()
                    .fill(Color.black)
                    .overlay {
                        #if os(iOS) && !SKIP
                        NativeVideoPlayerView(player: player, videoGravity: contentMode == .fill ? .resizeAspectFill : .resizeAspect)
                        #elseif SKIP
                        SkipAV.VideoPlayer(player: player)
                        #else
                        NativeVideoPlayerView(player: player, videoGravity: contentMode == .fill ? .resizeAspectFill : .resizeAspect)
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
