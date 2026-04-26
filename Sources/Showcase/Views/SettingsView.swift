import SwiftUI

struct SettingsView: View {
    @Environment(ViewModel.self) var viewModel: ViewModel
    @State internal var showingReloadAlert = false
    
    var totalVideos: Int {
        viewModel.videos.values.flatMap { $0 }.count
    }
    
    var body: some View {
        Form {
            Section("App Information") {
                LabeledContent("Name", value: "Meshchersky Park Showcase")
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Build", value: "Swift 6.3 + SKIP")
            }
            
            Section("Content Statistics") {
                LabeledContent("Scenarios", value: "\(viewModel.scenarios.count)")
                LabeledContent("Total Videos", value: "\(totalVideos)")
                
                if !viewModel.scenarios.isEmpty {
                    ForEach(viewModel.scenarios) { scenario in
                        let count = viewModel.videosForScenario(scenario).count
                        LabeledContent(scenario.title, value: "\(count) videos")
                            .font(.caption)
                    }
                }
            }
            
            Section("Display") {
                HStack {
                    Image(systemName: "airplayvideo")
                        .foregroundStyle(.blue)
                    Text("External Display")
                    Spacer()
                    Text("Ready")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Image(systemName: "wifi")
                        .foregroundStyle(.blue)
                    Text("Network Status")
                    Spacer()
                    Text("Connected")
                        .foregroundStyle(.green)
                }
            }
            
            Section("Data Management") {
                Button(action: {
                    showingReloadAlert = true
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Reload Content")
                    }
                }
                
                Button(action: {
                    Task {
                        await viewModel.loadData()
                    }
                }) {
                    HStack {
                        Image(systemName: "icloud.and.arrow.down")
                        Text("Sync from Server")
                    }
                }
            }
            
            Section("Support") {
                Link(destination: URL(string: "https://supabase.com/dashboard/project/smyfjmdjzfwdehynwfep")!) {
                    HStack {
                        Image(systemName: "link")
                        Text("Supabase Dashboard")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                LabeledContent("Developer", value: "Тарлан Исаев")
                LabeledContent("Client", value: "ООО «СПК-М»")
            }
            
            Section("About") {
                Text("Premium sales office presentation player for Meshchersky Park residential complex in Moscow.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .alert("Reload Content", isPresented: $showingReloadAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reload") {
                Task {
                    await viewModel.loadData()
                }
            }
        } message: {
            Text("This will reload all scenarios and videos from the server.")
        }
    }
}
