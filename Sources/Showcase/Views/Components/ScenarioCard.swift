import SwiftUI

struct ScenarioCard: View {
    let scenario: Scenario
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(height: 150)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.largeTitle)
                            .foregroundStyle(Color.accentColor)
                    )
                
                Text(scenario.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(scenario.slug)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
