import SwiftUI

/// A card component representing a lifestyle scenario in the Meshchersky Park showcase.
///
/// `ScenarioCard` implements the **Liquid Glass** design language, featuring:
/// - Adaptive layout for compact (iPhone) and regular (iPad) size classes.
/// - Ambient glow effects matching the scenario's brand colors.
/// - Glassmorphism overlays using `ultraThinMaterial`.
/// - Smooth spring-animated press states.
struct ScenarioCard: View {
    /// The scenario data model.
    let scenario: Scenario
    
    /// The namespace used for smooth `matchedGeometryEffect` transitions.
    let namespace: Namespace.ID
    
    /// The action to perform when the card is tapped.
    let action: () -> Void
    
    @Environment(ViewModel.self) var viewModel: ViewModel
    
    #if !os(macOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    
    /// Internal state to track if the card is currently being pressed.
    @State internal var isPressed = false

    /// The number of videos associated with this scenario.
    var videoCount: Int {
        viewModel.videosForScenario(scenario).count
    }

    /// Whether the current device has a compact width (iPhone portrait, etc.).
    private var isCompact: Bool {
        #if os(macOS)
        return false
        #else
        return horizontalSizeClass == .compact
        #endif
    }

    /// The cinematic aspect ratio for the card's visual area.
    /// Uses 16:9 for iPad and 4:3 for iPhone to optimize grid density.
    private var imageAspectRatio: CGFloat {
        isCompact ? (4.0 / 3.0) : (16.0 / 9.0)
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.selection()
            action()
        }) {
            VStack(alignment: .leading, spacing: isCompact ? 12 : 16) {
                imageAreaWithBackground
                
                textSection
                    .padding(.horizontal, isCompact ? 4 : 8)
                    .padding(.bottom, isCompact ? 0 : 8)
            }
            .padding(isCompact ? 12 : 16)
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
            if pressing {
                HapticManager.shared.impact(style: .light)
            }
            isPressed = pressing
        }, perform: {})
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
            if let url = viewModel.scenarioImageURL(for: scenario) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        Color.clear
                            .aspectRatio(imageAspectRatio, contentMode: .fit)
                            .overlay(
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            )
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
                .fill(.ultraThinMaterial.opacity(viewModel.scenarioImageURL(for: scenario) != nil ? 0.3 : 0.8))
                .aspectRatio(imageAspectRatio, contentMode: .fit)
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
            .aspectRatio(imageAspectRatio, contentMode: .fit)
    }
}

