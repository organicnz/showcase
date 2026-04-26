import SwiftUI
import SkipFuse

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
                            #if !os(macOS)
                            .navigationBarTitleDisplayMode(.inline)
                            #endif
                    }
                    .tabItem {
                        Label("Scenarios", systemImage: "square.grid.2x2.fill")
                    }
                    .tag(0)

                    NavigationStack {
                        LibraryView()
                            .navigationTitle("Library")
                            #if !os(macOS)
                            .navigationBarTitleDisplayMode(.inline)
                            #endif
                    }
                    .tabItem {
                        Label("Library", systemImage: "play.rectangle.on.rectangle.fill")
                    }
                    .tag(1)

                    NavigationStack {
                        SettingsView()
                            .navigationTitle("Settings")
                            #if !os(macOS)
                            .navigationBarTitleDisplayMode(.inline)
                            #endif
                    }
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(2)
                }
                .accentColor(Color.accentColor)
            }
        }
        .environment(viewModel)
        .task {
            await viewModel.loadData()
        }
        .refreshable {
            await viewModel.loadData()
        }
    }
}
