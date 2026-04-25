import SwiftUI

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
