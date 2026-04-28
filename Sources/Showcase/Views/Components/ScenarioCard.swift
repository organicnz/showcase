import SwiftUI
#if canImport(AVFoundation)
import AVFoundation
#endif

struct ScenarioCard: View {
    let scenario: Scenario
    let namespace: Namespace.ID
    let action: () -> Void
    @Environment(ViewModel.self) var viewModel: ViewModel
    #if !os(macOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    @State internal var isPressed = false
    @State internal var previewPlayer: AVPlayer?

    var videoCount: Int {
        viewModel.videosForScenario(scenario).count
    }

    /// Whether the current device has a compact width (iPhone portrait, etc.)
    private var isCompact: Bool {
        #if os(macOS)
        return false
        #else
        return horizontalSizeClass == .compact
        #endif
    }

    /// Card image area height — shorter on iPhone to fit 2-column grid
    private var imageHeight: CGFloat {
        isCompact ? 120 : 180
    }

    var body: some View {
        Button(action: action) {
            Group {
                if isCompact {
                    VStack(alignment: .leading, spacing: 12) {
                        imageAreaWithBackground
                        textSection
                            .padding(.horizontal, 4)
                    }
                    .padding(12)
                } else {
                    HStack(spacing: 24) {
                        imageAreaWithBackground
                            .frame(width: 280)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            textSection
                            
                            Spacer()
                            
                            HStack {
                                Spacer()
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 24, weight: .light))
                                    .foregroundStyle(ScenarioGradient.primaryColor(for: scenario.slug).opacity(0.8))
                            }
                        }
                        .padding(.vertical, 16)
                        .padding(.trailing, 16)
                    }
                    .padding(16)
                }
            }
            .background(
                ZStack {
                    // Premium Ambient Glow
                    RoundedRectangle(cornerRadius: CornerRadius.modal)
                        .fill(ScenarioGradient.primaryColor(for: scenario.slug).opacity(isPressed ? 0.15 : 0.05))
                        .blur(radius: isPressed ? 20 : 10)
                        .padding(-4)

                    RoundedRectangle(cornerRadius: CornerRadius.modal)
                        .fill(Color.cardSurface.opacity(0.4))
                }
                .shadow(color: .ink.opacity(0.04), radius: 30, y: 15)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.modal)
                    .stroke(isPressed ? ScenarioGradient.primaryColor(for: scenario.slug).opacity(0.6) : Color.cardBorder.opacity(0.5), lineWidth: isPressed ? 2 : 1)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        #if !os(macOS)
        .hoverEffect(.highlight)
        #endif
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onAppear {
            setupPreviewPlayer()
            previewPlayer?.play()
        }
        .onDisappear {
            previewPlayer?.pause()
        }
        .onChange(of: viewModel.userSettings?.autoPlayAudio) { _, newValue in
            let shouldPlayAudio = newValue ?? true
            previewPlayer?.isMuted = !shouldPlayAudio
        }
    }

    private func setupPreviewPlayer() {
        guard previewPlayer == nil else { return }
        
        // Find the first video for this scenario
        guard let firstVideo = viewModel.videosForScenario(scenario).first,
              let url = SupabaseManager.shared.getPublicVideoURL(for: firstVideo.storagePath) else {
            return
        }
        
        #if canImport(AVFoundation)
        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.actionAtItemEnd = .none
        
        // Mute if autoPlayAudio is false in user settings
        let shouldPlayAudio = viewModel.userSettings?.autoPlayAudio ?? true
        newPlayer.isMuted = !shouldPlayAudio
        
        // Ensure seamless looping
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak newPlayer] _ in
            Task { @MainActor in
                newPlayer?.seek(to: .zero)
                newPlayer?.play()
            }
        }
        
        newPlayer.play()
        self.previewPlayer = newPlayer
        #endif
    }

    private var imageAreaWithBackground: some View {
        imageArea
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.card + 4)
                    .fill(Color.cardSurface)
                    .shadow(color: .ink.opacity(isPressed ? 0.02 : 0.08), radius: isPressed ? 8 : 20, y: isPressed ? 4 : 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.card + 4)
                    .stroke(isPressed ? Color.terracotta.opacity(0.5) : Color.cardBorder, lineWidth: 1.5)
                    .blendMode(.overlay)
            )
    }

    // MARK: - Components

    private var imageArea: some View {
        ZStack {
            if let player = previewPlayer {
                VideoPlayerContainer(player: player, contentMode: .fill, isVideoLoading: false)
                    .frame(height: imageHeight)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
            } else if let url = viewModel.scenarioImageURL(for: scenario) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: imageHeight)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
                    } else if phase.error != nil {
                        // Fallback gradient on error
                        fallbackGradient
                    } else {
                        // Loading state
                        ZStack {
                            fallbackGradient
                            ProgressView().tint(.white)
                        }
                    }
                }
            } else {
                fallbackGradient
            }

            // Glass overlay for depth (more subtle when image exists)
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .fill(.ultraThinMaterial.opacity(previewPlayer != nil || viewModel.scenarioImageURL(for: scenario) != nil ? 0.3 : 0.8))
                .frame(height: imageHeight)
        }
        .matchedGeometryEffect(id: "card_\(scenario.id)", in: namespace)
        .overlay(alignment: .topTrailing) {
            // Corner Icon
            Image(systemName: viewModel.iconName(for: scenario))
                .font(.system(size: isCompact ? 16 : 22, weight: .light))
                .foregroundStyle(ScenarioGradient.primaryColor(for: scenario.slug))
                .padding(isCompact ? 8 : 12)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .padding(8)
        }
        .overlay(alignment: .bottomTrailing) {
            // Video count pill
            if videoCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "play.circle.fill")
                        .font(.caption2)
                    Text("\(videoCount) видео")
                        .font(.labelCaps)
                        .tracking(1.2)
                        .textCase(.uppercase)
                }
                .foregroundStyle(.ink.opacity(0.8))
                .padding(.horizontal, isCompact ? 8 : 12)
                .padding(.vertical, isCompact ? 4 : 6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(8)
            }
        }
    }

    private var textSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.scenarioTitle(for: scenario))
                .font(isCompact ? .body : .displaySmall)
                .foregroundStyle(.ink)
                .lineLimit(2)

            Text(viewModel.scenarioDescription(for: scenario))
                .font(isCompact ? .bodySmall2 : .bodyLarge)
                .foregroundStyle(.ink.opacity(0.7))
                .lineLimit(isCompact ? 1 : 2)
        }
    }
    
    private var fallbackGradient: some View {
        RoundedRectangle(cornerRadius: CornerRadius.card)
            .fill(
                LinearGradient(
                    colors: viewModel.gradientColors(for: scenario.slug),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: imageHeight)
    }
}

