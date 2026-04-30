import SwiftUI
#if os(iOS) || os(macOS)
import AVKit
#endif
import ShowcaseCore

/// Fullscreen video player with tablet controls
public struct PlayerScreen: View {
    @State var viewModel = PlayerViewModel()
    @Environment(\.dismiss) var dismiss
    let videos: [Video]
    
    public init(videos: [Video]) {
        self.videos = videos
    }
    
    public var body: some View {
        ZStack {
            // Video player (mirrored to external display)
            Color.black
                .ignoresSafeArea()
            
            if case .playing(let video, _, _) = viewModel.playbackState,
               let url = video.videoURL {
                VideoPlayerContainer(
                    player: viewModel.player,
                    contentMode: .fit,
                    isVideoLoading: false
                )
            }
            
            if case .loading = viewModel.playbackState {
                ProgressView()
                    .tint(.white)
            }
            
            // Tablet-only controls overlay
            VStack {
                Spacer()
                
                PlaybackControls(
                    state: viewModel.playbackState,
                    onPlayPause: {
                        if case .playing = viewModel.playbackState {
                            viewModel.pause()
                        } else {
                            viewModel.resume()
                        }
                    },
                    onNext: { viewModel.playNext() },
                    onStop: {
                        viewModel.stop()
                        dismiss()
                    }
                )
                .padding(LiquidGlassTheme.Spacing.lg)
            }
        }
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
        .task {
            await viewModel.startPlayback(videos: videos)
        }
        .onDisappear {
            viewModel.stop()
        }
    }
}
