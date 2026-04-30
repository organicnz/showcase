import SwiftUI
import ShowcaseCore

/// Card component for scenario display
public struct ScenarioCard: View {
    let scenario: Scenario
    let onTap: () -> Void
    
    public init(scenario: Scenario, onTap: @escaping () -> Void) {
        self.scenario = scenario
        self.onTap = onTap
    }
    
    public var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: LiquidGlassTheme.Spacing.md) {
                // Placeholder for scenario thumbnail
                RoundedRectangle(cornerRadius: LiquidGlassTheme.CornerRadius.medium)
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay(
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.8))
                    )
                
                Text(scenario.title)
                    .font(Typography.title3)
                    .foregroundColor(LiquidGlassTheme.Colors.primary)
                    .lineLimit(2)
            }
            .padding(LiquidGlassTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: LiquidGlassTheme.CornerRadius.large)
                    .fill(LiquidGlassTheme.Materials.ultraThin)
            )
        }
        .buttonStyle(.plain)
    }
}
