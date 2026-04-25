import SwiftUI

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
