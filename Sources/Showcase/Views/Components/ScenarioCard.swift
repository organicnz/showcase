import SwiftUI

struct ScenarioCard: View {
    let scenario: Scenario
    let action: () -> Void
    @Environment(ViewModel.self) var viewModel: ViewModel
    @State internal var isPressed = false
    
    var videoCount: Int {
        viewModel.videosForScenario(scenario).count
    }
    
    var scenarioIcon: String {
        switch scenario.slug {
        case "family": return "figure.2.and.child.holdinghands"
        case "wellness": return "leaf.fill"
        case "guests": return "building.2.fill"
        case "investor": return "chart.line.uptrend.xyaxis"
        case "architecture": return "building.columns.fill"
        default: return "sparkles"
        }
    }
    
    var scenarioGradient: LinearGradient {
        switch scenario.slug {
        case "family":
            return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "wellness":
            return LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "guests":
            return LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "investor":
            return LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "architecture":
            return LinearGradient(colors: [.indigo, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [.gray, .gray.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Card Image Area with Liquid Glass Effect
                ZStack {
                    // Background gradient
                    RoundedRectangle(cornerRadius: 20)
                        .fill(scenarioGradient)
                        .frame(height: 180)
                    
                    // Glass overlay
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .frame(height: 180)
                    
                    // Icon
                    VStack {
                        Image(systemName: scenarioIcon)
                            .font(.system(size: 50))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 10)
                        
                        if videoCount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "play.circle.fill")
                                    .font(.caption)
                                Text("\(videoCount) videos")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .shadow(radius: 4)
                        }
                    }
                    
                    // Shimmer effect on press
                    if isPressed {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.white.opacity(0.2))
                            .frame(height: 180)
                    }
                }
                
                // Title and description
                VStack(alignment: .leading, spacing: 4) {
                    Text(scenario.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    Text(scenarioDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .padding(.horizontal, 4)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
    
    var scenarioDescription: String {
        switch scenario.slug {
        case "family": return "School, playground, safety, community"
        case "wellness": return "Spa, forest walks, no city noise"
        case "guests": return "Hotel room booking instead of guest suite"
        case "investor": return "Liquidity, limited supply, unique location"
        case "architecture": return "Materials, light, panoramic glazing"
        default: return scenario.slug
        }
    }
}
