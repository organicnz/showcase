import SwiftUI
import ShowcaseCore

/// Main screen displaying scenario grid
public struct MainScreen: View {
    @State var viewModel: MainViewModel
    @State var selectedVideos: [Video]?
    @State var navigateToPlayer = false
    
    public init(viewModel: MainViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    public var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView("Loading scenarios...")
                    .foregroundColor(LiquidGlassTheme.Colors.primary)
            } else if let error = viewModel.errorMessage {
                ServiceStateView(
                    icon: "wifi.slash",
                    message: error,
                    action: { Task { await viewModel.loadScenarios() } }
                )
            } else if viewModel.scenarios.isEmpty {
                ServiceStateView(
                    icon: "film",
                    message: "No scenarios available",
                    action: nil
                )
            } else {
                ScenarioGrid(
                    scenarios: viewModel.scenarios,
                    onSelect: { scenario in
                        Task {
                            if let videos = await viewModel.selectScenario(scenario) {
                                selectedVideos = videos
                                navigateToPlayer = true
                            }
                        }
                    }
                )
            }
        }
        .navigationTitle("Showcase")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                LogoView(size: 40)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: LibraryScreen(viewModel: viewModel)) {
                    Image(systemName: "square.grid.2x2")
                        .foregroundColor(LiquidGlassTheme.Colors.primary)
                }
            }
        }
        .navigationDestination(isPresented: $navigateToPlayer) {
            if let videos = selectedVideos {
                PlayerScreen(videos: videos)
            }
        }
        .task {
            await viewModel.loadScenarios()
        }
        .toolbar(.visible, for: .navigationBar)
        .navigationBarHidden(false)
    }
}

/// Grid layout for scenarios
struct ScenarioGrid: View {
    let scenarios: [Scenario]
    let onSelect: (Scenario) -> Void
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 300), spacing: LiquidGlassTheme.Spacing.lg)
            ], spacing: LiquidGlassTheme.Spacing.lg) {
                ForEach(scenarios) { scenario in
                    ScenarioCard(scenario: scenario) {
                        onSelect(scenario)
                    }
                }
            }
            .padding(LiquidGlassTheme.Spacing.lg)
        }
    }
}
