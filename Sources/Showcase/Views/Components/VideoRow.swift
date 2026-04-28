import SwiftUI

struct VideoCard: View {
    let video: Video
    let action: () -> Void
    @Environment(ViewModel.self) var viewModel: ViewModel
    @State internal var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Thumbnail Area
                ZStack {
                    if let url = viewModel.videoThumbnailURL(for: video) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            } else if phase.error != nil {
                                fallbackThumbnail
                            } else {
                                ZStack {
                                    fallbackThumbnail
                                    ProgressView().tint(.white)
                                }
                            }
                        }
                    } else {
                        fallbackThumbnail
                    }
                    
                    // Glass Overlay
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        )

                    Image(systemName: "play.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                        .padding(16)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 10)
                }

                // Info Area
                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title ?? "Без названия")
                        .font(.bodyLarge)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        
                    if let subtitle = video.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.bodySmall2)
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(2)
                    }

                    HStack {
                        if let duration = video.durationSec {
                            Text(formatDuration(duration))
                                .font(.labelCaps)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Text("#\(video.orderIndex)")
                            .font(.labelCaps)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }

    private func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return "\(mins):\(String(format: "%02d", secs))"
    }

    private var fallbackThumbnail: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [Color.ochre.opacity(0.1), Color.terracotta.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 120)
    }
}
