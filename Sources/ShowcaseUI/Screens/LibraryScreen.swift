import SwiftUI
import ShowcaseCore

/// Library screen displaying all videos
public struct LibraryScreen: View {
    @State var viewModel: MainViewModel
    @State var allVideos: [Video] = []
    @State var selectedScenario: Scenario?
    @State var isLoading = false
    @State var errorMessage: String?
    @State var selectedVideos: [Video]?
    @State var navigateToPlayer = false
    
    public init(viewModel: MainViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Scenario filter picker
            if !viewModel.scenarios.isEmpty {
                Picker("Filter", selection: $selectedScenario) {
                    Text("All Scenarios").tag(nil as Scenario?)
                    ForEach(viewModel.scenarios) { scenario in
                        Text(scenario.title).tag(scenario as Scenario?)
                    }
                }
                .pickerStyle(.segmented)
                .padding(LiquidGlassTheme.Spacing.md)
            }
            
            // Video list
            if isLoading {
                ProgressView("Loading videos...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                ServiceStateView(
                    icon: "exclamationmark.triangle",
                    message: error,
                    action: { Task { await loadVideos() } }
                )
            } else if filteredVideos.isEmpty {
                ServiceStateView(
                    icon: "film",
                    message: "No videos available",
                    action: nil
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: LiquidGlassTheme.Spacing.md) {
                        ForEach(filteredVideos) { video in
                            VideoCard(video: video) {
                                selectedVideos = [video]
                                navigateToPlayer = true
                            }
                        }
                    }
                    .padding(LiquidGlassTheme.Spacing.md)
                }
            }
        }
        .navigationTitle("Library")
        .navigationDestination(isPresented: $navigateToPlayer) {
            if let videos = selectedVideos {
                PlayerScreen(videos: videos)
            }
        }
        .task {
            await loadVideos()
        }
    }
    
    private var filteredVideos: [Video] {
        guard let selectedScenario = selectedScenario else {
            return allVideos
        }
        return allVideos.filter { $0.scenarioId == selectedScenario.id }
    }
    
    private func loadVideos() async {
        isLoading = true
        errorMessage = nil
        
        // For now, load videos from all scenarios
        var videos: [Video] = []
        for scenario in viewModel.scenarios {
            if let scenarioVideos = await viewModel.selectScenario(scenario) {
                videos.append(contentsOf: scenarioVideos)
            }
        }
        
        allVideos = videos
        isLoading = false
    }
}
