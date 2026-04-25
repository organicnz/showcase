import SwiftUI
import SkipFuse
import SkipAV
import AVFoundation

struct ContentView: View {
    @State var viewModel = ViewModel()
    @State var selectedTab: Int = 0

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView()
            } else if let error = viewModel.error {
                ErrorView(error: error, retryAction: {
                    Task { await viewModel.loadData() }
                })
            } else {
                TabView(selection: $selectedTab) {
                    NavigationStack {
                        ScenarioGridView()
                            .navigationTitle("Scenarios")
                    }
                    .tabItem { Label("Scenarios", systemImage: "square.grid.2x2.fill") }
                    .tag(0)

                    NavigationStack {
                        LibraryView()
                            .navigationTitle("Library")
                    }
                    .tabItem { Label("Library", systemImage: "play.rectangle.on.rectangle.fill") }
                    .tag(1)

                    NavigationStack {
                        SettingsView()
                            .navigationTitle("Settings")
                    }
                    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                    .tag(2)
                }
            }
        }
        .environment(viewModel)
        .task {
            await viewModel.loadData()
        }
    }
}

struct ScenarioGridView: View {
    @Environment(ViewModel.self) var viewModel: ViewModel
    
    let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(viewModel.scenarios) { scenario in
                    ScenarioCard(scenario: scenario) {
                        viewModel.selectScenario(scenario)
                    }
                }
            }
            .padding()
        }
    }
}

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

struct LibraryView: View {
    @Environment(ViewModel.self) var viewModel: ViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.scenarios) { scenario in
                Section(header: Text(scenario.title)) {
                    if let videos = viewModel.videos[scenario.id] {
                        ForEach(videos) { video in
                            VideoRow(video: video)
                        }
                    } else {
                        Text("No videos").foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

struct VideoRow: View {
    let video: Video
    @Environment(ViewModel.self) var viewModel: ViewModel
    
    var body: some View {
        NavigationLink(destination: VideoDetailView(video: video)) {
            HStack {
                Image(systemName: "play.circle.fill")
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading) {
                    Text(video.title ?? "Untitled Video")
                        .font(.body)
                    if let duration = video.durationSec {
                        Text("\(duration) sec")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

struct VideoDetailView: View {
    let video: Video
    @Environment(ViewModel.self) var viewModel: ViewModel
    
    var body: some View {
        VStack {
            if let url = viewModel.videoURL(for: video) {
                #if os(macOS) && !SKIP
                Text("Video Player Placeholder (macOS)")
                    .frame(maxWidth: 800, maxHeight: 400)
                    .background(Color.black)
                #else
                VideoPlayer(player: AVPlayer(url: url))
                    .frame(maxWidth: 800, maxHeight: 400)
                #endif
            } else {
                ContentUnavailableView("Video Unavailable", systemImage: "video.slash")
            }
            
            Form {
                Section("Details") {
                    LabeledContent("Scenario ID", value: video.scenarioId.uuidString)
                    LabeledContent("Order", value: "\(video.orderIndex)")
                    LabeledContent("Active", value: video.isActive ? "Yes" : "No")
                }
            }
        }
        .navigationTitle(video.title ?? "Video")
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading Showcase...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }
}

struct ErrorView: View {
    let error: Error
    let retryAction: () -> Void
    
    var body: some View {
        ContentUnavailableView {
            Label("Connection Error", systemImage: "wifi.exclamationmark")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            Button("Retry", action: retryAction)
                .buttonStyle(.borderedProminent)
        }
    }
}

struct SettingsView: View {
    var body: some View {
        Form {
            Section("App Info") {
                Text("Meshchersky Park Showcase")
                Text("Version 1.0.0 (Swift 6.3)")
            }
            Section("Mirroring") {
                Text("AirPlay Status: Connected")
            }
        }
    }
}
