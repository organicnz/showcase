import SwiftUI
import SkipAV
import AVFoundation

struct VideoPlayerView: View {
    @Environment(ViewModel.self) var viewModel: ViewModel
    @Environment(\.dismiss) var dismiss
    @State internal var player: AVPlayer?
    @State internal var isControlsVisible = true
    @State internal var hideControlsTask: Task<Void, Never>?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let video = viewModel.currentVideo,
               let url = viewModel.videoURL(for: video) {
                
                // Video Player
                #if os(macOS) && !SKIP
                VideoPlayerPlaceholder(video: video)
                #else
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        setupPlayer(url: url)
                    }
                    .onDisappear {
                        cleanupPlayer()
                    }
                #endif
                
                // Tablet Controls Overlay
                if isControlsVisible {
                    VStack {
                        // Top Bar
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.white)
                                    .shadow(radius: 4)
                            }
                            
                            Spacer()
                            
                            Text(video.title ?? "Video")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .shadow(radius: 4)
                            
                            Spacer()
                            
                            Text("\(viewModel.currentVideoIndex + 1)/\(viewModel.videoQueue.count)")
                                .font(.caption)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                        .padding()
                        
                        Spacer()
                        
                        // Bottom Controls
                        HStack(spacing: 40) {
                            Button(action: { viewModel.playPreviousVideo() }) {
                                Image(systemName: "backward.fill")
                                    .font(.title)
                                    .foregroundStyle(.white)
                                    .shadow(radius: 4)
                            }
                            .disabled(viewModel.videoQueue.count <= 1)
                            
                            Button(action: { 
                                if viewModel.isPlaying {
                                    player?.pause()
                                    viewModel.isPlaying = false
                                } else {
                                    player?.play()
                                    viewModel.isPlaying = true
                                }
                            }) {
                                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(.white)
                                    .shadow(radius: 4)
                            }
                            
                            Button(action: { viewModel.playNextVideo() }) {
                                Image(systemName: "forward.fill")
                                    .font(.title)
                                    .foregroundStyle(.white)
                                    .shadow(radius: 4)
                            }
                            .disabled(viewModel.videoQueue.count <= 1)
                        }
                        .padding(.bottom, 40)
                    }
                    .transition(.opacity)
                }
            } else {
                ContentUnavailableView(
                    "No Video Selected",
                    systemImage: "video.slash",
                    description: Text("Select a scenario to start playing videos")
                )
            }
        }
        .onTapGesture {
            toggleControls()
        }
        #if !os(macOS)
        .statusBar(hidden: !isControlsVisible)
        #endif
    }
    
    private func setupPlayer(url: URL) {
        player = AVPlayer(url: url)
        player?.play()
        
        // Auto-play next video when current finishes
        #if !SKIP
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { _ in
            viewModel.playNextVideo()
            if let nextVideo = viewModel.currentVideo,
               let nextURL = viewModel.videoURL(for: nextVideo) {
                setupPlayer(url: nextURL)
            }
        }
        #endif
        
        scheduleControlsHide()
    }
    
    private func cleanupPlayer() {
        player?.pause()
        player = nil
        hideControlsTask?.cancel()
    }
    
    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isControlsVisible.toggle()
        }
        
        if isControlsVisible {
            scheduleControlsHide()
        }
    }
    
    private func scheduleControlsHide() {
        hideControlsTask?.cancel()
        hideControlsTask = Task {
            try? await Task.sleep(for: .seconds(3))
            if !Task.isCancelled {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isControlsVisible = false
                }
            }
        }
    }
}

#if os(macOS) && !SKIP
struct VideoPlayerPlaceholder: View {
    let video: Video
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "play.rectangle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.white.opacity(0.5))
            
            Text("Video Player")
                .font(.title)
                .foregroundStyle(.white)
            
            Text(video.title ?? "Untitled")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))
            
            Text("Video playback is available on iOS/iPadOS and Android")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}
#endif
