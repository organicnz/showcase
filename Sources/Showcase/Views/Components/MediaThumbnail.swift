import SwiftUI

struct MediaThumbnail: View {
    var video: Video?
    var photo: Photo?
    var namespace: Namespace.ID
    let action: () -> Void

    @State internal var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Background Placeholder / Thumbnail
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial.opacity(0.3))
                
                // Content
                if let video = video {
                    videoThumbnailContent(video: video)
                } else if let photo = photo {
                    photoThumbnailContent(photo: photo)
                }
            }
            .matchedGeometryEffect(id: video?.id ?? photo?.id ?? UUID(), in: namespace)
            .aspectRatio(16/9, contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.1), lineWidth: 0.5)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }

    @ViewBuilder
    private func videoThumbnailContent(video: Video) -> some View {
        ZStack {
            // Placeholder color based on video title hash
            Color.terracotta.opacity(0.2)
            
            VStack {
                Spacer()
                HStack {
                    Image(systemName: "play.fill")
                        .font(.caption)
                    Text(video.title ?? "Видео")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Spacer()
                    if let dur = video.durationSec {
                        Text("\(dur) сек.")
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.black.opacity(0.3))
                            .clipShape(Capsule())
                    }
                }
                .foregroundStyle(.white)
                .padding(12)
                .background(
                    LinearGradient(colors: [.clear, .black.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                )
            }
            
            Image(systemName: "play.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.white.opacity(0.8))
                .shadow(radius: 10)
        }
    }

    @ViewBuilder
    private func photoThumbnailContent(photo: Photo) -> some View {
        ZStack {
            Color.ochre.opacity(0.2)
            
            VStack {
                Spacer()
                HStack {
                    Image(systemName: "photo")
                        .font(.caption)
                    Text(photo.title ?? "Фото")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(12)
                .background(
                    LinearGradient(colors: [.clear, .black.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                )
            }
        }
    }
}
