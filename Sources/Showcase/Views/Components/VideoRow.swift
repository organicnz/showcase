import SwiftUI

struct VideoRow: View {
    let video: Video
    let action: () -> Void
    @Environment(ViewModel.self) var viewModel: ViewModel
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Thumbnail placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor.opacity(0.2))
                        .frame(width: 80, height: 60)
                    
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                }
                
                // Video info
                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title ?? "Untitled Video")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 12) {
                        if let duration = video.durationSec {
                            Label("\(duration)s", systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Label("Order \(video.orderIndex)", systemImage: "number")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
