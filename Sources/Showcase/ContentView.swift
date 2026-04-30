import SwiftUI
import SkipFuse

struct ContentView: View {
    @State var viewModel = ViewModel()
    @State var showLibrary = false
    @State var showSettings = false
    @Namespace private var animationNamespace

    var body: some View {
        Group {
            if !viewModel.isAuthenticated {
                LoginView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                switch viewModel.loadState {
                case .idle, .loading:
                    LoadingView(status: viewModel.currentWorkflowProgress)

                case .failed(let error):
                    ErrorView(error: error, retryAction: {
                        Task { await viewModel.loadData() }
                    })

                case .loaded:
                    ZStack {
                        NavigationStack {
                            ScenarioGridView(animationNamespace: animationNamespace)
                                #if !os(macOS)
                                .navigationBarTitleDisplayMode(.inline)
                                #endif
                                .toolbar {
                                    ToolbarItem(placement: .principal) {
                                        LogoView(size: 48)
                                    }

                                    #if !os(macOS)
                                    ToolbarItem(placement: .topBarTrailing) {
                                        HStack(spacing: 20) {
                                            Button(action: { showLibrary = true }) {
                                                Image(systemName: "play.rectangle.on.rectangle")
                                                    .font(.system(size: 20, weight: .medium))
                                                    .foregroundStyle(.ink)
                                            }

                                            Button(action: { showSettings = true }) {
                                                Image(systemName: "gearshape")
                                                    .font(.system(size: 20, weight: .medium))
                                                    .foregroundStyle(.mid)
                                            }
                                        }
                                    }
                                    #endif
                                }
                                .toolbar(.visible, for: .navigationBar)
                                .toolbarBackground(.hidden, for: .navigationBar)
                        }
                        
                        if viewModel.isShowingDetail {
                            ScenarioDetailView(animationNamespace: animationNamespace)
                                .transition(.identity) // Geometry handles the motion
                        }
                    }
                    .tint(ScenarioGradient.primaryColor(for: viewModel.selectedScenario?.slug ?? ""))
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
        }
        .environment(viewModel)
        .animation(.spring(), value: viewModel.isAuthenticated)
        .task {
            await viewModel.checkAuth()
            if viewModel.isAuthenticated {
                await viewModel.loadData()
            }
        }
    }
}
