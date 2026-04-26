import SwiftUI
import SkipAV
#if canImport(AVFoundation)
import AVFoundation
#endif

struct VideoPlayerView: View {
    @Environment(ViewModel.self) var viewModel: ViewModel
    @Environment(\.dismiss) var dismiss
    @State internal var player: AVPlayer?
    @State internal var isControlsVisible = true
    @State internal var hideControlsTask: Task<Void, Never>?
    @State internal var videoProgress: Double = 0
    @State internal var isVideoLoading = true
    @State internal var endOfPlaybackObserver: NSObjectProtocol?
    @State internal var timeObserver: Any?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let video = viewModel.currentVideo,
               let _ = viewModel.videoURL(for: video) {

                // Video Player
                #if os(macOS) && !SKIP
                VideoPlayerPlaceholder(video: video)
                #else
                if let player = player {
                    VideoPlayer(player: player)
                        .ignoresSafeArea()
                }
                #endif

                // Loading Indicator
                if isVideoLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(1.5)
                }

                // Tablet Controls Overlay
                controlsOverlay(video: video)

            } else {
                EmptyStateView(
                    "Видео не выбрано",
                    systemImage: "video.slash",
                    description: "Выберите сценарий для воспроизведения видео"
                )
            }
        }
        .onTapGesture {
            toggleControls()
        }
        .onAppear {
            loadCurrentVideo()
        }
        .onDisappear {
            cleanupPlayer()
        }
        .onChange(of: viewModel.currentVideo) { _, newVideo in
            if let video = newVideo, let url = viewModel.videoURL(for: video) {
                loadVideo(url: url)
            }
        }
    }

    // MARK: - Controls Overlay

    @ViewBuilder
    private func controlsOverlay(video: Video) -> some View {
        if isControlsVisible {
            VStack {
                // Top Bar
                HStack {
                    Button(action: {
                        viewModel.stopPlayback()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.9))
                            .shadow(radius: 4)
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text(video.title ?? "Видео")
                            .font(.headline)
                            .foregroundStyle(.white)

                        if let scenario = viewModel.selectedScenario {
                            Text(scenario.title)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .shadow(radius: 4)

                    Spacer()

                    HStack(spacing: 16) {
                        AirPlayView()
                            .frame(width: 44, height: 44)

                        Text("\(viewModel.currentVideoIndex + 1)/\(viewModel.videoQueue.count)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                }
                .padding()

                Spacer()

                // Bottom Controls
                VStack(spacing: 16) {
                    // Progress bar — always visible
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.white.opacity(0.3))
                                .frame(height: 3)

                            Capsule()
                                .fill(Color.terracotta)
                                .frame(width: geo.size.width * videoProgress, height: 3)
                                .animation(.linear(duration: 0.5), value: videoProgress)
                        }
                    }
                    .frame(height: 3)
                    .padding(.horizontal, 40)

                    // Playback buttons
                    HStack(spacing: 40) {
                        Button(action: { viewModel.playPreviousVideo() }) {
                            Image(systemName: "backward.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                                .shadow(radius: 4)
                        }
                        .disabled(viewModel.videoQueue.count <= 1)
                        .opacity(viewModel.videoQueue.count <= 1 ? 0.4 : 1)

                        Button(action: {
                            if viewModel.isPlaying {
                                player?.pause()
                                viewModel.isPlaying = false
                            } else {
                                player?.play()
                                viewModel.isPlaying = true
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 64, height: 64)

                                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.white)
                            }
                            .shadow(radius: 8)
                        }

                        Button(action: { viewModel.playNextVideo() }) {
                            Image(systemName: "forward.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                                .shadow(radius: 4)
                        }
                        .disabled(viewModel.videoQueue.count <= 1)
                        .opacity(viewModel.videoQueue.count <= 1 ? 0.4 : 1)
                    }

                    // Duration label
                    if let duration = video.durationSec {
                        Text("\(duration) сек.")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    // Up next preview (spec §4.3)
                    if viewModel.videoQueue.count > 1 {
                        let nextIndex = (viewModel.currentVideoIndex + 1) % viewModel.videoQueue.count
                        let nextVideo = viewModel.videoQueue[nextIndex]
                        HStack(spacing: 8) {
                            Text("Далее:")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.4))
                            Text(nextVideo.title ?? "Без названия")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial.opacity(0.5))
                        .clipShape(Capsule())
                    }
                }
                .padding(.bottom, 40)
            }
            .transition(.opacity)
            .background(
                // Gradient scrim for readability
                VStack {
                    LinearGradient(colors: [.black.opacity(0.6), .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 120)
                    Spacer()
                    LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                        .frame(height: 180)
                }
                .ignoresSafeArea()
            )
        }
    }

    // MARK: - Player Management

    private func loadCurrentVideo() {
        guard let video = viewModel.currentVideo,
              let url = viewModel.videoURL(for: video) else { return }
        loadVideo(url: url)
    }

    private func loadVideo(url: URL) {
        isVideoLoading = true
        videoProgress = 0

        // Remove previous observers
        removeObservers()

        // Reuse player if exists, otherwise create
        if let existingPlayer = player {
            let item = AVPlayerItem(url: url)
            existingPlayer.replaceCurrentItem(with: item)
            existingPlayer.play()
        } else {
            let newPlayer = AVPlayer(url: url)
            player = newPlayer
            newPlayer.play()
        }

        isVideoLoading = false
        viewModel.isPlaying = true

        // Observe end of playback for auto-advance
        #if canImport(AVFoundation)
        endOfPlaybackObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { [viewModel] _ in
            MainActor.assumeIsolated {
                viewModel.playNextVideo()
            }
        }

        // Track progress for scrubber bar
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak player] time in
            guard let currentItem = player?.currentItem,
                  currentItem.duration.seconds.isFinite,
                  currentItem.duration.seconds > 0 else { return }
            MainActor.assumeIsolated {
                self.videoProgress = time.seconds / currentItem.duration.seconds
            }
        }
        #endif

        scheduleControlsHide()
    }

    private func cleanupPlayer() {
        player?.pause()
        removeObservers()
        player = nil
        hideControlsTask?.cancel()
    }

    private func removeObservers() {
        #if canImport(AVFoundation)
        if let observer = endOfPlaybackObserver {
            NotificationCenter.default.removeObserver(observer)
            endOfPlaybackObserver = nil
        }
        if let observer = timeObserver, let player = player {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
        #endif
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
            try? await Task.sleep(for: .seconds(4))
            if !Task.isCancelled {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isControlsVisible = false
                }
            }
        }
    }
}

// MARK: - macOS Placeholder

#if os(macOS) && !SKIP
struct VideoPlayerPlaceholder: View {
    let video: Video

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "play.rectangle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.white.opacity(0.5))

            Text("Видеоплеер")
                .font(.title)
                .foregroundStyle(.white)

            Text(video.title ?? "Без названия")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))

            Text("Воспроизведение доступно на iOS/iPadOS и Android")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}
#endif
