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
        Group {
            if viewModel.hasVideos {
                List {
                    ForEach(filteredScenarios) { scenario in
                        Section {
                            let videos = viewModel.videosForScenario(scenario)
                            if videos.isEmpty {
                                HStack {
                                    Image(systemName: "video.slash")
                                        .foregroundStyle(.mid)
                                    Text("Нет доступных видео")
                                        .foregroundStyle(.mid)
                                }
                                .padding(.vertical, 8)
                            } else {
                                ForEach(videos) { video in
                                    VideoRow(video: video) {
                                        viewModel.playVideo(video)
                                        showVideoPlayer = true
                                    }
                                    .listRowBackground(Color.white.opacity(0.6))
                                }
                            }
                        } header: {
                            HStack {
                                Image(systemName: viewModel.iconName(for: scenario.slug))
                                    .foregroundStyle(.terracotta)
                                Text(viewModel.scenarioTitle(for: scenario))
                                Spacer()
                                Text("\(viewModel.videosForScenario(scenario).count)")
                                    .font(.caption)
                                    .foregroundStyle(.mid)
                            }
                        }
                    }
                }
                #if !os(macOS)
                .scrollContentBackground(.hidden)
                #endif
                .background(Color.soft.ignoresSafeArea())
                .searchable(text: $searchText, prompt: "Поиск сценариев")
            } else {
                EmptyStateView(
                    "Нет видео",
                    systemImage: "play.rectangle.on.rectangle",
                    description: "Видео появятся здесь после загрузки в библиотеку"
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
}
