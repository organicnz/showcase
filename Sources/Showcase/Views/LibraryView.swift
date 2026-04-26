import SwiftUI

struct LibraryView: View {
    @Environment(ViewModel.self) var viewModel: ViewModel
    @State internal var showVideoPlayer = false
    @State internal var searchText = ""
    
    var filteredScenarios: [Scenario] {
        if searchText.isEmpty {
            return viewModel.scenarios
        }
        return viewModel.scenarios.filter { scenario in
            scenario.title.localizedCaseInsensitiveContains(searchText) ||
            scenario.slug.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        Group {
            if viewModel.hasVideos {
                List {
                    ForEach(filteredScenarios) { scenario in
                        Section {
                            let videos = viewModel.videosForScenario(scenario)
                            if videos.isEmpty {
                                HStack {
                                    Image(systemName: "video.slash")
                                        .foregroundStyle(.secondary)
                                    Text("No videos available")
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 8)
                            } else {
                                ForEach(videos) { video in
                                    VideoRow(video: video) {
                                        viewModel.playVideo(video)
                                        showVideoPlayer = true
                                    }
                                }
                            }
                        } header: {
                            HStack {
                                Image(systemName: scenarioIcon(for: scenario.slug))
                                    .foregroundStyle(Color.accentColor)
                                Text(scenario.title)
                                Spacer()
                                Text("\(viewModel.videosForScenario(scenario).count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search scenarios")
            } else {
                ContentUnavailableView(
                    "No Videos Yet",
                    systemImage: "play.rectangle.on.rectangle",
                    description: Text("Videos will appear here once they are uploaded to the library")
                )
            }
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
    
    private func scenarioIcon(for slug: String) -> String {
        switch slug {
        case "family": return "figure.2.and.child.holdinghands"
        case "wellness": return "leaf.fill"
        case "guests": return "building.2.fill"
        case "investor": return "chart.line.uptrend.xyaxis"
        case "architecture": return "building.columns.fill"
        default: return "sparkles"
        }
    }
}
