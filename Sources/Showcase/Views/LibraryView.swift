import SwiftUI

struct LibraryView: View {
    @Environment(ViewModel.self) var viewModel: ViewModel
    @State internal var showVideoPlayer = false
    @State internal var searchText = ""
    @Namespace internal var animationNamespace

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
                                let photos = viewModel.photos[scenario.id] ?? []
                                
                                if !videos.isEmpty || !photos.isEmpty {
                                    VStack(alignment: .leading, spacing: 24) {
                                        // Section Header
                                        HStack {
                                            Image(systemName: viewModel.iconName(for: scenario))
                                                .foregroundStyle(.terracotta)
                                            Text(viewModel.scenarioTitle(for: scenario))
                                                .font(.bodyLarge)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.white)
                                            
                                            Spacer()
                                            
                                            Text("\(videos.count + photos.count)")
                                                .font(.caption)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(.ultraThinMaterial)
                                                .clipShape(Capsule())
                                                .foregroundStyle(.white.opacity(0.6))
                                        }
                                        .padding(.horizontal, 20)

                                        if !videos.isEmpty {
                                            VStack(alignment: .leading, spacing: 12) {
                                                Text("Видео")
                                                    .font(.labelCaps)
                                                    .foregroundStyle(.white.opacity(0.5))
                                                    .padding(.horizontal, 20)
                                                
                                                // Video Grid
                                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                                                    ForEach(videos) { video in
                                                        VideoCard(video: video) {
                                                            viewModel.playVideo(video)
                                                            viewModel.contentMode = .video
                                                            showVideoPlayer = true
                                                        }
                                                    }
                                                }
                                                .padding(.horizontal, 20)
                                            }
                                        }
                                        
                                        if !photos.isEmpty {
                                            VStack(alignment: .leading, spacing: 12) {
                                                Text("Фотографии")
                                                    .font(.labelCaps)
                                                    .foregroundStyle(.white.opacity(0.5))
                                                    .padding(.horizontal, 20)
                                                
                                                // Photo Grid
                                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                                                    ForEach(photos) { photo in
                                                        MediaThumbnail(photo: photo, namespace: animationNamespace) {
                                                            if let idx = photos.firstIndex(where: { $0.id == photo.id }) {
                                                                viewModel.startPhotoGallery(with: photos, startingAt: idx)
                                                            }
                                                            viewModel.contentMode = .photo
                                                            showVideoPlayer = true
                                                        }
                                                    }
                                                }
                                                .padding(.horizontal, 20)
                                            }
                                        }
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
        .overlay {
            if showVideoPlayer {
                ScenarioDetailView(animationNamespace: animationNamespace)
                    .environment(viewModel)
                    .transition(.opacity)
            }
        }
        #else
        .sheet(isPresented: $showVideoPlayer) {
            ScenarioDetailView(animationNamespace: animationNamespace)
                .environment(viewModel)
        }
        #endif
    }
}
