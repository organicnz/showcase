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
    @State internal var contentModeScale: ContentModeScale = .fit
    @State internal var isVideoLoading = true
    @State internal var hideControlsTask: Task<Void, Never>?
    @State internal var videoProgress: Double = 0
    @State internal var videoDuration: Double = 0
    @State internal var currentTime: Double = 0
    @State internal var timeObserver: Any?
    @State internal var isPlayerPlaying = false
    @State internal var isScrubbing = false
    @State internal var endObserver: NSObjectProtocol?
    @State internal var selectedMediaType: MediaType = .video
    
    enum MediaType {
        case video, photo
    }
    
    enum ContentModeScale {
        case fit, fill
    }
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        ZStack {
            // 1. Ambient Background (Deep backdrop)
            AmbientBackgroundView()
                .ignoresSafeArea()
                .overlay(Color.black.opacity(viewModel.contentMode == .video ? 0.95 : 0.6))
            
            // 2. Main Content
            Group {
                switch viewModel.contentMode {
                case .overview:
                    overviewContent
                case .video:
                    videoContent
                case .photo:
                    photoContent
                }
            }
            
            // 3. UI Layer (Interactive Overlays)
            VStack(spacing: 0) {
                // Top Navigation Bar
                topBar
                    .opacity(isControlsVisible ? 1 : 0)
                    .animation(.spring(response: 0.4), value: isControlsVisible)
                
                Spacer()
                
                // Bottom Cinematic Controls
                if viewModel.contentMode == .video {
                    bottomPlayerChrome
                        .opacity(isControlsVisible ? 1 : 0)
                        .offset(y: isControlsVisible ? 0 : 40)
                        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: isControlsVisible)
                }
            }
            .padding(.bottom, 40)
            .zIndex(9999) // Stay above the video
        }
        .ignoresSafeArea()
        #if !os(macOS)
        .persistentSystemOverlays(.hidden)
        #endif
        .onAppear {
            isControlsVisible = true
            if viewModel.contentMode == .video {
                loadCurrentVideo()
            }
            startHideControlsTimer()
        }
        .onDisappear { cleanupPlayer() }
        .onTapGesture {
            withAnimation(.spring(response: 0.4)) {
                isControlsVisible.toggle()
            }
            if isControlsVisible {
                startHideControlsTimer()
            }
        }
        .onChange(of: viewModel.contentMode) { _, newMode in
            if newMode == .video { loadCurrentVideo() } else { cleanupPlayer() }
        }
        .onChange(of: viewModel.currentVideo) { _, _ in
            if viewModel.contentMode == .video { loadCurrentVideo() }
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        ZStack(alignment: .top) {
            // Center: Liquid Glass Tab Picker (when not playing video)
            if viewModel.contentMode != .video {
                HStack(spacing: 8) {
                    mediaTypeTab(title: "Видео", type: .video)
                    mediaTypeTab(title: "Фото", type: .photo)
                }
                .padding(6)
                .background(.ultraThinMaterial.opacity(0.4))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 0.5))
            }
            
            HStack(alignment: .top) {
                // Left: Media metadata
                if viewModel.contentMode == .video, let video = viewModel.currentVideo {
                    mediaMetadataView(title: video.title ?? "Видео", index: viewModel.currentVideoIndex, total: viewModel.videoQueue.count)
                } else if viewModel.contentMode == .photo, let photo = viewModel.currentPhoto {
                    mediaMetadataView(title: photo.title ?? "Фото", index: viewModel.currentPhotoIndex, total: viewModel.photoQueue.count)
                } else {
                    Spacer()
                }
                
                Spacer()
                
                // Right: Controls
                HStack(spacing: 12) {
                    // Aspect ratio toggle (video mode only)
                    if viewModel.contentMode == .video {
                        aspectRatioButton
                    }
                    closeButton
                }
            }
        }
        .padding(.top, 40)
        .padding(.horizontal, 40)
    }
    
    @ViewBuilder
    private func mediaMetadataView(title: String, index: Int, total: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
            
            if total > 0 {
                Text("\(index + 1) из \(total)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .tracking(1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.08), lineWidth: 0.5)
        )
    }
    
    // MARK: - Components
    
    @ViewBuilder
    private var videoContent: some View {
        ZStack {
            if let video = viewModel.currentVideo, let _ = viewModel.videoURL(for: video) {
                VideoPlayerContainer(
                    player: player,
                    contentMode: contentModeScale == .fill ? .fill : .fit,
                    isVideoLoading: isVideoLoading
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .allowsHitTesting(false) // Allow taps to pass through to ZStack
                
                // Highlights overlay
                if let highlights = viewModel.currentVideo?.highlights, !highlights.isEmpty, !isControlsVisible {
                    HighlightsOverlay(highlights: highlights)
                        .padding(.bottom, 80)
                        .transition(.opacity)
                }
            } else {
                ProgressView().tint(.white)
            }
        }
    }
    
    @ViewBuilder
    private var overviewContent: some View {
        if let scenario = viewModel.selectedScenario {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(scenario.title)
                            .font(.displayLarge)
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 120)
                    .padding(.horizontal, 60)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 30) {
                        if selectedMediaType == .video {
                            ForEach(viewModel.videos[scenario.id] ?? []) { video in
                                MediaThumbnail(video: video, namespace: animationNamespace) {
                                    viewModel.currentVideo = video
                                    viewModel.contentMode = .video
                                    isControlsVisible = true
                                }
                            }
                        } else {
                            ForEach(viewModel.photos[scenario.id] ?? []) { photo in
                                MediaThumbnail(photo: photo, namespace: animationNamespace) {
                                    if let photos = viewModel.photos[scenario.id],
                                       let idx = photos.firstIndex(where: { $0.id == photo.id }) {
                                        viewModel.startPhotoGallery(with: photos, startingAt: idx)
                                    }
                                    viewModel.contentMode = .photo
                                    isControlsVisible = true
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 60)
                }
                .padding(.bottom, 100)
            }
        }
    }
    
    private func mediaTypeTab(title: String, type: MediaType) -> some View {
        Button(action: {
            HapticManager.shared.impact(style: .light)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                selectedMediaType = type
            }
        }) {
            Text(title.uppercased())
                .font(.system(size: 13, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(selectedMediaType == type ? .ink : .white.opacity(0.7))
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background {
                    if selectedMediaType == type {
                        Capsule()
                            .fill(.white)
                            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                            .matchedGeometryEffect(id: "TabSelection", in: animationNamespace)
                    }
                }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Close & Aspect Ratio Buttons
    
    private var closeButton: some View {
        Button(action: {
            HapticManager.shared.impact(style: .medium)
            if viewModel.contentMode != .overview {
                viewModel.contentMode = .overview
            } else {
                viewModel.isShowingDetail = false
            }
        }) {
            Image(systemName: "xmark")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1))
        }
    }
    
    private var aspectRatioButton: some View {
        Button(action: {
            HapticManager.shared.impact(style: .light)
            withAnimation(.spring(response: 0.3)) {
                contentModeScale = contentModeScale == .fill ? .fit : .fill
            }
        }) {
            Image(systemName: contentModeScale == .fill ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1))
        }
    }
    
    // MARK: - Bottom Player Chrome
    
    private var bottomPlayerChrome: some View {
        VStack(spacing: 0) {
            // Progress scrubber + time labels
            progressSection
            
            // Transport controls (prev / play-pause / next)
            transportControls
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(spacing: 8) {
            // Scrubber track
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(.white.opacity(0.15))
                        .frame(height: isScrubbing ? 8 : 4)
                    
                    // Filled progress
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.terracotta, Color.ochre],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * safeProgress), height: isScrubbing ? 8 : 4)
                    
                    // Thumb indicator
                    Circle()
                        .fill(.white)
                        .frame(width: isScrubbing ? 20 : 12, height: isScrubbing ? 20 : 12)
                        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                        .offset(x: max(0, geo.size.width * safeProgress - (isScrubbing ? 10 : 6)))
                        .opacity(isScrubbing || isControlsVisible ? 1 : 0)
                }
                .frame(height: 20)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isScrubbing = true
                            let fraction = max(0, min(1, value.location.x / geo.size.width))
                            videoProgress = fraction
                            startHideControlsTimer()
                        }
                        .onEnded { value in
                            let fraction = max(0, min(1, value.location.x / geo.size.width))
                            seekToFraction(fraction)
                            isScrubbing = false
                        }
                )
                .animation(.spring(response: 0.25), value: isScrubbing)
            }
            .frame(height: 20)
            
            // Time labels
            HStack {
                Text(formatTime(currentTime))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                
                Spacer()
                
                Text(formatTime(videoDuration))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Transport Controls
    
    private var transportControls: some View {
        HStack(spacing: 40) {
            // Queue position indicators (dots)
            queueIndicator
            
            Spacer()
            
            // Previous
            controlButton(icon: "backward.fill", size: 22) {
                if viewModel.contentMode == .video {
                    viewModel.playPreviousVideo()
                } else if viewModel.contentMode == .photo {
                    viewModel.showPreviousPhoto()
                }
            }
            
            // Play / Pause
            if viewModel.contentMode == .video {
                Button(action: {
                    HapticManager.shared.impact(style: .light)
                    togglePlayPause()
                    startHideControlsTimer()
                }) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.12))
                            .frame(width: 72, height: 72)
                        
                        Image(systemName: isPlayerPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                            .offset(x: isPlayerPlaying ? 0 : 2) // Optical alignment for play icon
                    }
                }
            }
            
            // Next
            controlButton(icon: "forward.fill", size: 22) {
                if viewModel.contentMode == .video {
                    viewModel.playNextVideo()
                } else if viewModel.contentMode == .photo {
                    viewModel.showNextPhoto()
                }
            }
            
            Spacer()
            
            // Remaining time badge
            if viewModel.contentMode == .video && videoDuration > 0 {
                Text("-\(formatTime(max(0, videoDuration - currentTime)))")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(minWidth: 60, alignment: .trailing)
            } else if viewModel.contentMode == .photo {
                Spacer().frame(minWidth: 60)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(.white.opacity(0.08), lineWidth: 0.5)
        )
    }
    
    // MARK: - Queue Indicator Dots
    
    private var queueIndicator: some View {
        let count = viewModel.contentMode == .video ? viewModel.videoQueue.count : viewModel.photoQueue.count
        let currentIdx = viewModel.contentMode == .video ? viewModel.currentVideoIndex : viewModel.currentPhotoIndex
        
        return HStack(spacing: 5) {
            if count > 1 {
                ForEach(0..<min(count, 8), id: \.self) { idx in
                    Circle()
                        .fill(idx == currentIdx ? Color.white : Color.white.opacity(0.25))
                        .frame(width: idx == currentIdx ? 7 : 5,
                               height: idx == currentIdx ? 7 : 5)
                        .animation(.spring(response: 0.3), value: currentIdx)
                }
                if count > 8 {
                    Text("…")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
        }
        .frame(minWidth: 60, alignment: .leading)
    }
    
    private func controlButton(icon: String, size: CGFloat = 24, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.shared.impact(style: .light)
            action()
            startHideControlsTimer()
        }) {
            Image(systemName: icon)
                .font(.system(size: size))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .contentShape(Circle())
        }
    }
    
    @ViewBuilder
    private var photoContent: some View {
        ZStack {
            if let photo = viewModel.currentPhoto, let url = viewModel.photoURL(for: photo) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: contentModeScale == .fill ? .fill : .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    } else if phase.error != nil {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                            Text("Ошибка загрузки фото")
                                .font(.labelCaps)
                        }
                        .foregroundStyle(.white.opacity(0.5))
                    } else {
                        ProgressView().tint(.white)
                    }
                }
                .id(photo.id)
                .animation(.spring(response: 0.4), value: photo.id)
            } else {
                Text("Фото не выбрано").foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.4)) {
                isControlsVisible.toggle()
            }
        }
    }
    
    // MARK: - Logic
    
    private var safeProgress: Double {
        guard videoProgress.isFinite, !videoProgress.isNaN else { return 0 }
        return max(0, min(1, videoProgress))
    }
    
    private func loadCurrentVideo() {
        if let video = viewModel.currentVideo, let url = viewModel.videoURL(for: video) {
            loadVideo(url: url)
        }
    }
    
    private func loadVideo(url: URL) {
        isVideoLoading = true
        videoProgress = 0
        currentTime = 0
        videoDuration = 0
        
        #if canImport(AVFoundation)
        cleanupPlayer()
        
        let item = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: item)
        self.player = newPlayer
        
        // Observe player status for loading indication
        observePlayerStatus(item: item)
        
        // Add periodic time observer for progress tracking
        addTimeObserver(player: newPlayer)
        
        // Observe end of video for auto-advance
        observeVideoEnd(player: newPlayer)
        
        newPlayer.play()
        isPlayerPlaying = true
        #endif
    }
    
    #if canImport(AVFoundation)
    private func observePlayerStatus(item: AVPlayerItem) {
        // Use KVO-free approach: poll until ready
        Task { @MainActor in
            // Wait for the item to become ready
            while item.status == .unknown {
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                if Task.isCancelled { return }
            }
            
            if item.status == .readyToPlay {
                let duration = item.duration.seconds
                if duration.isFinite && !duration.isNaN {
                    videoDuration = duration
                }
                withAnimation(.easeOut(duration: 0.3)) {
                    isVideoLoading = false
                }
            } else {
                isVideoLoading = false
            }
        }
    }
    
    private func addTimeObserver(player: AVPlayer) {
        // Remove existing observer
        if let existing = timeObserver {
            player.removeTimeObserver(existing)
            timeObserver = nil
        }
        
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak player] time in
            guard !isScrubbing else { return }
            
            let seconds = time.seconds
            guard seconds.isFinite, !seconds.isNaN else { return }
            
            self.currentTime = seconds
            
            if let duration = player?.currentItem?.duration.seconds,
               duration.isFinite, !duration.isNaN, duration > 0 {
                self.videoDuration = duration
                self.videoProgress = seconds / duration
            }
            
            // Update play state reactively
            self.isPlayerPlaying = (player?.rate ?? 0) > 0
        }
    }
    
    private func observeVideoEnd(player: AVPlayer) {
        // Remove existing observer
        if let existing = endObserver {
            NotificationCenter.default.removeObserver(existing)
            endObserver = nil
        }
        
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            Task { @MainActor in
                HapticManager.shared.impact(style: .soft)
                viewModel.playNextVideo()
            }
        }
    }
    #endif
    
    private func seekToFraction(_ fraction: Double) {
        #if canImport(AVFoundation)
        guard let player = player,
              let duration = player.currentItem?.duration.seconds,
              duration.isFinite, !duration.isNaN, duration > 0 else { return }
        
        let targetTime = CMTime(seconds: fraction * duration, preferredTimescale: 600)
        player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
            Task { @MainActor in
                self.currentTime = fraction * duration
                self.videoProgress = fraction
            }
        }
        #endif
    }
    
    private func togglePlayPause() {
        #if canImport(AVFoundation)
        guard let player = player else { return }
        if player.rate > 0 {
            player.pause()
            isPlayerPlaying = false
        } else {
            player.play()
            isPlayerPlaying = true
        }
        #endif
    }
    
    private func cleanupPlayer() {
        #if canImport(AVFoundation)
        if let player = player, let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
            endObserver = nil
        }
        player?.pause()
        player = nil
        isPlayerPlaying = false
        videoProgress = 0
        currentTime = 0
        videoDuration = 0
        #endif
    }
    
    private func startHideControlsTimer() {
        hideControlsTask?.cancel()
        hideControlsTask = Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            if !Task.isCancelled && isPlayerPlaying {
                withAnimation(.spring(response: 0.6)) {
                    isControlsVisible = false
                }
            }
        }
    }
    
    // MARK: - Formatting
    
    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite, !seconds.isNaN, seconds >= 0 else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
