import SwiftUI

struct ScenarioGridView: View {
    @Environment(ViewModel.self) var viewModel: ViewModel
    @State internal var showVideoPlayer = false
    
    let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Logo Header
                LogoView()
                    .padding(.top, 20)
                
                // Welcome Text
                VStack(spacing: 8) {
                    Text("Meshchersky Park")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Select a lifestyle scenario")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 8)
                
                // Scenario Grid
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(viewModel.scenarios) { scenario in
                        ScenarioCard(scenario: scenario) {
                            viewModel.selectScenario(scenario)
                            showVideoPlayer = true
                        }
                    }
                }
                .padding(.horizontal)
                
                // Empty State
                if viewModel.scenarios.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView(
                        "No Scenarios Available",
                        systemImage: "square.grid.2x2",
                        description: Text("Scenarios will appear here once they are added")
                    )
                    .padding(.top, 60)
                }
            }
            .padding(.bottom, 40)
        }
        #if !os(macOS)
        .fullScreenCover(isPresented: $showVideoPlayer) {
            VideoPlayerView()
                .environment(viewModel)
        }
        #else
        .sheet(isPresented: $showVideoPlayer) {
            VideoPlayerView()
                .environment(viewModel)
        }
        #endif
    }
}
