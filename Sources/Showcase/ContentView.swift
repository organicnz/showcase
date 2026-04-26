import SwiftUI
import SkipFuse

struct ContentView: View {
    @State var viewModel = ViewModel()
    @State var showLibrary = false
    @State var showSettings = false

    var body: some View {
        Group {
            switch viewModel.loadState {
            case .idle, .loading:
                LoadingView()

            case .failed(let error):
                ErrorView(error: error, retryAction: {
                    Task { await viewModel.loadData() }
                })

            case .loaded:
                NavigationStack {
                    ScenarioGridView()
                        #if !os(macOS)
                        .navigationBarTitleDisplayMode(.inline)
                        #endif
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                LogoView(size: 32)
                            }

                            #if !os(macOS)
                            ToolbarItem(placement: .topBarTrailing) {
                                HStack(spacing: 16) {
                                    Button(action: { showLibrary = true }) {
                                        Image(systemName: "play.rectangle.on.rectangle")
                                            .foregroundStyle(.ink)
                                    }

                                    Button(action: { showSettings = true }) {
                                        Image(systemName: "gearshape")
                                            .foregroundStyle(.mid)
                                    }
                                }
                            }
                            #else
                            ToolbarItem(placement: .automatic) {
                                HStack(spacing: 16) {
                                    Button(action: { showLibrary = true }) {
                                        Image(systemName: "play.rectangle.on.rectangle")
                                    }

                                    Button(action: { showSettings = true }) {
                                        Image(systemName: "gearshape")
                                    }
                                }
                            }
                            #endif
                        }
                        #if !os(macOS)
                        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                        #endif
                }
                .tint(.terracotta)
                .sheet(isPresented: $showLibrary) {
                    NavigationStack {
                        LibraryView()
                            .navigationTitle("Библиотека")
                            #if !os(macOS)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                            #endif
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Готово") { showLibrary = false }
                                }
                            }
                    }
                    .environment(viewModel)
                    .tint(.terracotta)
                }
                .sheet(isPresented: $showSettings) {
                    NavigationStack {
                        SettingsView()
                            .navigationTitle("Настройки")
                            #if !os(macOS)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                            #endif
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Готово") { showSettings = false }
                                }
                            }
                    }
                    .environment(viewModel)
                    .tint(.terracotta)
                }
            }
        }
        .environment(viewModel)
        .task {
            await viewModel.loadData()
        }
    }
}
