import SwiftUI

struct ScenarioCard: View {
    let scenario: Scenario
    let action: () -> Void
    @Environment(ViewModel.self) var viewModel: ViewModel
    @State internal var isPressed = false

    var videoCount: Int {
        viewModel.videosForScenario(scenario).count
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
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
                        .frame(height: 180)

                    // Glass overlay for depth
                    RoundedRectangle(cornerRadius: CornerRadius.card)
                        .fill(.ultraThinMaterial)
                        .frame(height: 180)

                    // Icon and video count
                    VStack(spacing: 16) {
                        Image(systemName: viewModel.iconName(for: scenario.slug))
                            .font(.system(size: 50, weight: .light))
                            .foregroundStyle(.ink.opacity(0.8))

                        if videoCount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "play.circle.fill")
                                    .font(.caption)
                                Text("\(videoCount) видео")
                                    .font(.labelCaps)
                                    .tracking(1.2)
                                    .textCase(.uppercase)
                            }
                            .foregroundStyle(.ink.opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                        }
                    }

                    // Shimmer on press
                    if isPressed {
                        RoundedRectangle(cornerRadius: CornerRadius.card)
                            .fill(Color.terracotta.opacity(0.08))
                            .frame(height: 180)
                            .transition(.opacity)
                    }
                }

                // Title and description
                VStack(alignment: .leading, spacing: 4) {
                    Text(scenario.title)
                        .font(.displaySmall)
                        .foregroundStyle(.ink)
                        .lineLimit(2)

                    Text(viewModel.scenarioDescription(for: scenario))
                        .font(.bodySmall2)
                        .foregroundStyle(.mid)
                        .lineLimit(2)
                }
                .padding(.horizontal, 4)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isPressed ? Color.terracotta.opacity(0.5) : Color.glassStroke, lineWidth: isPressed ? 1.5 : 0.5)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}
