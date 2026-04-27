import SwiftUI

struct ScenarioCard: View {
    let scenario: Scenario
    let action: () -> Void
    @Environment(ViewModel.self) var viewModel: ViewModel
    #if !os(macOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    @State internal var isPressed = false

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
            VStack(alignment: .leading, spacing: isCompact ? 8 : 12) {
                // Card Image Area
                ZStack {
                    // Background gradient — warm brand palette
                    RoundedRectangle(cornerRadius: CornerRadius.card)
                        .fill(
                            LinearGradient(
                                colors: viewModel.gradientColors(for: scenario.slug),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: imageHeight)

                    // Glass overlay for depth
                    RoundedRectangle(cornerRadius: CornerRadius.card)
                        .fill(.ultraThinMaterial)
                        .frame(height: imageHeight)

                    // Icon and video count
                    VStack(spacing: isCompact ? 10 : 16) {
                        Image(systemName: viewModel.iconName(for: scenario.slug))
                            .font(.system(size: isCompact ? 36 : 50, weight: .light))
                            .foregroundStyle(.ink.opacity(0.8))
                            .shadow(color: .ink.opacity(0.15), radius: 8, y: 4)

                        if videoCount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "play.circle.fill")
                                    .font(.caption2)
                                Text("\(videoCount) видео")
                                    .font(.labelCaps)
                                    .tracking(1.2)
                                    .textCase(.uppercase)
                            }
                            .foregroundStyle(.ink.opacity(0.7))
                            .padding(.horizontal, isCompact ? 8 : 12)
                            .padding(.vertical, isCompact ? 4 : 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                        }
                    }

                    // Shimmer on press
                    if isPressed {
                        RoundedRectangle(cornerRadius: CornerRadius.card)
                            .fill(Color.terracotta.opacity(0.08))
                            .frame(height: imageHeight)
                            .transition(.opacity)
                    }
                }

                // Title and description
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.scenarioTitle(for: scenario))
                        .font(isCompact ? .body : .displaySmall)
                        .foregroundStyle(.ink)
                        .lineLimit(2)

                    Text(viewModel.scenarioDescription(for: scenario))
                        .font(.bodySmall2)
                        .foregroundStyle(.mid)
                        .lineLimit(isCompact ? 1 : 2)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
            }
            .padding(isCompact ? 6 : 10)
            .background(
                RoundedRectangle(cornerRadius: isCompact ? 14 : 18)
                    .fill(Color.cardSurface)
                    .shadow(color: .ink.opacity(isPressed ? 0.02 : 0.06), radius: isPressed ? 8 : 16, y: isPressed ? 4 : 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: isCompact ? 14 : 18)
                    .stroke(isPressed ? Color.terracotta.opacity(0.5) : Color.cardBorder, lineWidth: 1.5)
                    .blendMode(.overlay)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .rotation3DEffect(.degrees(isPressed ? 2 : 0), axis: (x: 1, y: 0, z: 0))
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

