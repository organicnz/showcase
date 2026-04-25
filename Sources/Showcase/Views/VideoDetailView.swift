import SwiftUI
import SkipAV
import AVFoundation

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
