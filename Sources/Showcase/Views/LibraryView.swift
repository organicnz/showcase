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
            let title = viewModel.scenarioTitle(for: scenario)
            return title.localizedCaseInsensitiveContains(searchText) ||
            scenario.slug.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            AmbientBackgroundView()
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.6))

            Group {
                if viewModel.hasVideos {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 32) {
                            ForEach(filteredScenarios) { scenario in
                                let videos = viewModel.videosForScenario(scenario)
                                if !videos.isEmpty {
                                    VStack(alignment: .leading, spacing: 16) {
                                        // Section Header
                                        HStack {
                                            Image(systemName: viewModel.iconName(for: scenario.slug))
                                                .foregroundStyle(.terracotta)
                                            Text(viewModel.scenarioTitle(for: scenario))
                                                .font(.bodyLarge)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.white)
                                            
                                            Spacer()
                                            
                                            Text("\(videos.count)")
                                                .font(.caption)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(.ultraThinMaterial)
                                                .clipShape(Capsule())
                                                .foregroundStyle(.white.opacity(0.6))
                                        }
                                        .padding(.horizontal, 20)

                                        // Video Grid
                                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                                            ForEach(videos) { video in
                                                VideoCard(video: video) {
                                                    viewModel.playVideo(video)
                                                    showVideoPlayer = true
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 24)
                    }
                    .searchable(text: $searchText, prompt: "Поиск сценариев")
                } else {
                    EmptyStateView(
                        "Нет видео",
                        systemImage: "play.rectangle.on.rectangle",
                        description: "Видео появятся здесь после загрузки в библиотеку"
                    )
                    .foregroundStyle(.white)
                }
            }
        }
        #if !os(macOS)
        .fullScreenCover(isPresented: $showVideoPlayer) {
            ScenarioDetailView()
                .environment(viewModel)
        }
        #else
        .sheet(isPresented: $showVideoPlayer) {
            ScenarioDetailView()
                .environment(viewModel)
        }
        #endif
    }
}
