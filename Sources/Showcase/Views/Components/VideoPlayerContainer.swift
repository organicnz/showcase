import SwiftUI
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
                VideoPlayer(player: player)
                    .scaledToFill()
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
