import SwiftUI
import SkipAV
#if canImport(AVFoundation)
import AVFoundation
#endif

struct ScenarioDetailView: View {
    @Environment(ViewModel.self) var viewModel: ViewModel
    let animationNamespace: Namespace.ID
    @State internal var player: AVPlayer?
    @State internal var isControlsVisible = true
    @State internal var isImmersiveMode = false
    @State internal var contentModeScale: ContentModeScale = .fill
    @Namespace private var animationNamespace
    
    enum ContentModeScale {
        case fit, fill
    }
    @State internal var seekFeedback: SeekFeedback? = nil
    
    struct SeekFeedback: Identifiable {
        let id = UUID()
        let direction: SeekDirection
        let amount: Int = 10
        
        enum SeekDirection {
            case forward, backward
        }
    }
    @State internal var hideControlsTask: Task<Void, Never>?
    @State internal var videoProgress: Double = 0
    @State internal var isVideoLoading = true
    @State internal var endOfPlaybackObserver: NSObjectProtocol?
    @State internal var timeObserver: Any?
    @State internal var isDraggingScrubber = false
    @State internal var dragOffset: CGFloat = 0

    var body: some View {
        @Bindable var viewModel = viewModel
        ZStack {
            // 1. Ambient Background based on scenario colors
            AmbientBackgroundView()
                .ignoresSafeArea()
                .overlay(
                    Color.black.opacity(viewModel.contentMode == .video ? 0.9 : 0.6)
                )
                .animation(.easeInOut(duration: 0.6), value: viewModel.contentMode)

            // 2. Main Content Layer (Video Player, Photos, Overview)
            Group {
                switch viewModel.contentMode {
                case .overview:
                    overviewContent
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                case .video:
                    // Only the player itself here
                    if let video = viewModel.currentVideo,
                       let _ = viewModel.videoURL(for: video) {
                        #if os(macOS) && !SKIP
                        VideoPlayerPlaceholder(video: video)
                        #else
                        VideoPlayerContainer(
                            player: player,
                            contentMode: contentModeScale == .fill ? .fill : .fit,
                            isVideoLoading: isVideoLoading
                        )
                        .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 1.05)), removal: .opacity))
                        .matchedGeometryEffect(id: video.id, in: animationNamespace)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                        #endif
                    } else {
                        videoEmptyState
                    }
                case .photo:
                    photoContent
                        .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.95)), removal: .opacity))
                }
            }

            // 3. Scrim Layer (Background for readability)
            if viewModel.contentMode == .video && isControlsVisible {
                VStack {
                    LinearGradient(colors: [.black.opacity(0.6), .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 180)
                    Spacer()
                    LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                        .frame(height: 250)
                }
                .ignoresSafeArea()
                .transition(.opacity)
                .allowsHitTesting(false) // Let hits pass to Interaction Layer
            }

            // 4. Interaction Layer (Full screen invisible tap catcher)
            if viewModel.contentMode == .video {
                Color.black.opacity(0.01)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 30)
                            .onEnded { value in
                                let horizontalDistance = value.translation.width
                                let verticalDistance = value.translation.height
                                
                                // Only handle horizontal swipes if not dragging a scrubber
                                if abs(horizontalDistance) > abs(verticalDistance) {
                                    if horizontalDistance > 100 {
                                        HapticManager.shared.impact(style: .medium)
                                        withAnimation { viewModel.playPreviousVideo() }
                                    } else if horizontalDistance < -100 {
                                        HapticManager.shared.impact(style: .medium)
                                        withAnimation { viewModel.playNextVideo() }
                                    }
                                }
                            }
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isControlsVisible.toggle()
                        }
                    }
                    .onTapGesture(count: 2) { location in seek(at: location) }
            }

            // 5. Controls & Navigation Layer (Top-most)
            VStack {
                // Top Bar (Close)
                HStack {
                    if isControlsVisible || viewModel.contentMode != .video {
                        closeButtonOverlay
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    Spacer()
                }
                .padding(.top, 60)
                .padding(.leading, 30)
                
                Spacer()
                
                // Cinematic Highlights (Contextual info)
                if viewModel.contentMode == .video, let video = viewModel.currentVideo, 
                   let highlights = video.highlights, !highlights.isEmpty {
                    HighlightsOverlay(highlights: highlights)
                        .padding(.bottom, isControlsVisible ? 20 : 60)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Bottom Controls & Immersive Toggle
                if viewModel.contentMode == .video, let video = viewModel.currentVideo {
                    VStack(spacing: 24) {
                        // Playback Controls
                        bottomControlsOverlay(video: video)
                        
                        HStack {
                            Spacer()
                            immersiveButtonOverlay
                        }
                        .padding(.trailing, 30)
                        .padding(.bottom, 60)
                    }
                }
            }
            .allowsHitTesting(true)
            .zIndex(999) 
        }
        .ignoresSafeArea(.all)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.contentMode)
        .overlay {
            if let feedback = seekFeedback {
                SeekFeedbackOverlay(feedback: feedback)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            isControlsVisible = true
            if viewModel.contentMode == .video {
                if let scenario = viewModel.selectedScenario {
                    AudioManager.shared.playAmbient(path: scenario.ambientAudioPath)
                }
                loadCurrentVideo()
                scheduleControlsHide()
            }
        }
        .onDisappear {
            cleanupPlayer()
            AudioManager.shared.stopAmbient()
        }
        .onChange(of: viewModel.contentMode) { _, newMode in
            HapticManager.shared.impact(style: .medium)
            if newMode == .video {
                if let scenario = viewModel.selectedScenario {
                    AudioManager.shared.playAmbient(path: scenario.ambientAudioPath)
                }
                loadCurrentVideo()
                isControlsVisible = true
                scheduleControlsHide()
            } else {
                cleanupPlayer()
                AudioManager.shared.stopAmbient()
            }
        }
        .onChange(of: viewModel.currentVideo) { _, newVideo in
            if viewModel.contentMode == .video, let video = newVideo, let url = viewModel.videoURL(for: video) {
                loadVideo(url: url)
            }
        }
    }

    private var isCompact: Bool {
        #if os(iOS)
        return true
        #else
        return false
        #endif
    }

    // MARK: - Overview Content

    @ViewBuilder
    private var overviewContent: some View {
        if let scenario = viewModel.selectedScenario {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(scenario.title)
                            .font(.system(size: isCompact ? 32 : 48, weight: .bold))
                            .foregroundStyle(.white)
                        
                        Text("Библиотека контента")
                            .font(.labelCaps)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.top, isCompact ? 100 : 120)
                    .padding(.horizontal, isCompact ? 24 : 40)

                    // Media Grid
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: isCompact ? 160 : 280), spacing: 20)], spacing: 20) {
                        // Videos first
                        ForEach(viewModel.videos[scenario.id] ?? []) { video in
                            MediaThumbnail(video: video, namespace: animationNamespace) {
                                HapticManager.shared.impact(style: .medium)
                                viewModel.currentVideo = video
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    viewModel.contentMode = .video
                                }
                            }
                        }
                        
                        // Then Photos
                        ForEach(viewModel.photos[scenario.id] ?? []) { photo in
                            MediaThumbnail(photo: photo, namespace: animationNamespace) {
                                HapticManager.shared.impact(style: .medium)
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    viewModel.contentMode = .photo
                                }
                            }
                        }
                    }
                    .padding(.horizontal, isCompact ? 24 : 40)
                    .padding(.bottom, 60)
                }
            }
        }
    }

    @ViewBuilder
    private var videoEmptyState: some View {
        VStack(spacing: 20) {
            EmptyStateView(
                "Загрузка видео...",
                systemImage: "video.slash",
                description: "Подождите, мы загружаем видео для этого сценария."
            )
            .foregroundStyle(.white)
            .colorScheme(.dark)
        }
    }

    // MARK: - Photo Content

    @ViewBuilder
    private var photoContent: some View {
        if let scenario = viewModel.selectedScenario {
            PhotoGalleryView(photos: viewModel.photos[scenario.id] ?? [])
                .environment(viewModel)
        }
    }

    // MARK: - Shared Overlays

    private var closeButtonOverlay: some View {
        Button(action: {
            HapticManager.shared.impact(style: .light)
            if viewModel.contentMode != .overview {
                withAnimation { viewModel.contentMode = .overview }
            } else {
                viewModel.stopPlayback()
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    viewModel.isShowingDetail = false
                }
            }
        }) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 54, height: 54)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.2), lineWidth: 0.5)
                    )
                
                Image(systemName: viewModel.contentMode == .overview ? "xmark" : "chevron.left")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white)
            }
            .shadow(color: .black.opacity(0.4), radius: 15, y: 8)
        }
        .transition(.opacity)
    }

    private var immersiveButtonOverlay: some View {
        Button(action: {
            HapticManager.shared.impact(style: .medium)
            withAnimation(.easeInOut(duration: 0.4)) {
                isImmersiveMode.toggle()
                isControlsVisible = !isImmersiveMode
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: isImmersiveMode ? "viewfinder.circle.fill" : "viewfinder.circle")
                Text(isImmersiveMode ? "Выйти" : "Во весь экран")
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .opacity(1.0) // FORCE VISIBLE
    }

    @ViewBuilder
    private func topBar(title: String, subtitle: String) -> some View {
        @Bindable var viewModel = viewModel
        HStack(alignment: .top) {
            Spacer()

            VStack(spacing: 16) {
                // The Top Switcher (Фото / Видео)
                Picker("", selection: $viewModel.contentMode) {
                    ForEach(ContentMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 280)
                .padding(4)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.1), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.4), radius: 20, y: 10)

                VStack(spacing: 4) {
                    Text(title.uppercased())
                        .font(.labelCaps)
                        .tracking(3)
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.bodyLarge)
                        .italic()
                        .foregroundStyle(.white.opacity(0.6))
                }
                .shadow(color: .black.opacity(0.5), radius: 10)
            }

            Spacer()
        }
        .padding()
        .overlay(alignment: .trailing) {
            if viewModel.contentMode == .video {
                HStack(spacing: 20) {
                    AirPlayView()
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 0.5))

                    Text("\(viewModel.currentVideoIndex + 1) / \(viewModel.videoQueue.count)")
                        .font(.labelCaps)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 0.5))
                }
                .padding(.trailing, 24)
                .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
            }
        }
    }

    // MARK: - Bottom Controls Overlay

    @ViewBuilder
    private func bottomControlsOverlay(video: Video) -> some View {
        if isControlsVisible {
            // Bottom Controls
            VStack(spacing: 16) {
                // Progress bar — premium interactive design
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.15))
                            .frame(height: isDraggingScrubber ? 6 : 2)

                        Capsule()
                            .fill(Color.terracotta)
                            .frame(width: geo.size.width * videoProgress, height: isDraggingScrubber ? 6 : 2)
                            .shadow(color: Color.terracotta.opacity(0.8), radius: isDraggingScrubber ? 6 : 4)
                    }
                    .contentShape(Rectangle().inset(by: -20)) // Larger hit area
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                isDraggingScrubber = true
                                hideControlsTask?.cancel()
                                let progress = max(0, min(1, value.location.x / geo.size.width))
                                videoProgress = progress
                                
                                // High-frequency seek for smooth scrubbing
                                #if canImport(AVFoundation)
                                if let duration = player?.currentItem?.duration.seconds, duration.isFinite {
                                    let targetTime = CMTime(seconds: duration * progress, preferredTimescale: 600)
                                    player?.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
                                }
                                #endif
                            }
                            .onEnded { _ in
                                isDraggingScrubber = false
                                scheduleControlsHide()
                                HapticManager.shared.impact(style: .light)
                            }
                    )
                }
                .frame(height: 10)
                .padding(.horizontal, 40)
                .animation(.spring(response: 0.3), value: isDraggingScrubber)
                .animation(.linear(duration: isDraggingScrubber ? 0.05 : 0.5), value: videoProgress)

                // Playback buttons
                HStack(spacing: 50) {
                    Button(action: { viewModel.playPreviousVideo() }) {
                        Image(systemName: "backward.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.8))
                            .shadow(radius: 4)
                    }
                    .disabled(viewModel.videoQueue.count <= 1)
                    .opacity(viewModel.videoQueue.count <= 1 ? 0.2 : 1)

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
                            // Subtle glowing halo
                            Circle()
                                .fill(Color.terracotta.opacity(viewModel.isPlaying ? 0.15 : 0.4))
                                .frame(width: viewModel.isPlaying ? 80 : 90, height: viewModel.isPlaying ? 80 : 90)
                                .blur(radius: 15)
                                .scaleEffect(viewModel.isPlaying ? 1.0 : (animate ? 1.2 : 1.0))
                                .animation(viewModel.isPlaying ? .default : .easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animate)

                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 64, height: 64)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(viewModel.isPlaying ? 0.2 : 0.5), lineWidth: 1)
                                )

                            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                    }

                    Button(action: { 
                        HapticManager.shared.impact(style: .medium)
                        viewModel.playNextVideo() 
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.8))
                            .shadow(radius: 4)
                    }
                    .disabled(viewModel.videoQueue.count <= 1)
                    .opacity(viewModel.videoQueue.count <= 1 ? 0.2 : 1)
                    
                    // New: Scale Mode Toggle
                    Button(action: {
                        HapticManager.shared.impact(style: .light)
                        withAnimation(.spring()) {
                            contentModeScale = contentModeScale == .fit ? .fill : .fit
                        }
                    }) {
                        Image(systemName: contentModeScale == .fit ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
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
                    Button(action: {
                        HapticManager.shared.impact(style: .medium)
                        withAnimation { viewModel.playNextVideo() }
                    }) {
                        HStack(spacing: 12) {
                            Text("ДАЛЕЕ")
                                .font(.system(size: 10, weight: .black))
                                .tracking(2)
                                .foregroundStyle(.white.opacity(0.4))
                            
                            Rectangle()
                                .fill(.white.opacity(0.2))
                                .frame(width: 1, height: 10)

                            Text(nextVideo.title ?? "Без названия")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.8))
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial.opacity(0.3))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(0.1), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 20)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onAppear { animate = true }
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
            try? await Task.sleep(for: .seconds(8))
            if !Task.isCancelled {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isControlsVisible = false
                }
            }
        }
    }

    // MARK: - Advanced Gestures

    private func seek(at location: CGPoint) {
        #if canImport(AVFoundation)
        guard let player = player, let currentItem = player.currentItem else { return }
        
        // Simple direction check: right half of screen is forward
        // In a real Skip app, we should pass the width from GeometryReader, 
        // but for now we'll use a rough estimate or a generic check.
        // On iPad, 512 is a safe 'middle' for most orientations.
        let isForward = location.x > 512 
        let seekInterval: Double = 10.0
        
        let currentTime = player.currentTime().seconds
        let newTime = isForward ? currentTime + seekInterval : currentTime - seekInterval
        let clampedTime = max(0, min(newTime, currentItem.duration.seconds))
        
        let targetTime = CMTime(seconds: clampedTime, preferredTimescale: 600)
        player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
        
        // Visual Feedback
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            seekFeedback = SeekFeedback(direction: isForward ? .forward : .backward)
        }
        
        // Auto-hide feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation {
                seekFeedback = nil
            }
        }
        
        // Haptic Feedback
        HapticManager.shared.impact(style: .medium)
        #endif
    }
}

struct SeekFeedbackOverlay: View {
    let feedback: ScenarioDetailView.SeekFeedback
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: feedback.direction == .forward ? "goforward.10" : "gobackward.10")
                .font(.system(size: 40, weight: .bold))
            Text(feedback.direction == .forward ? "+10 сек" : "-10 сек")
                .font(.bodyLarge)
                .fontWeight(.bold)
        }
        .foregroundStyle(.white)
        .padding(30)
        .background(.ultraThinMaterial)
        .clipShape(Circle())
        .shadow(color: .black.opacity(0.3), radius: 20)
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
