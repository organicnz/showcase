import SwiftUI
#if canImport(AVFoundation)
import AVFoundation
#endif

struct MediaThumbnail: View {
    var video: Video?
    var photo: Photo?
    var namespace: Namespace.ID
    let action: () -> Void

    @Environment(ViewModel.self) var viewModel: ViewModel
    @State internal var isPressed = false
    @State internal var previewPlayer: AVPlayer?

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
        .onAppear {
            if let video = video {
                setupPreviewPlayer(for: video)
            }
            previewPlayer?.play()
        }
        .onDisappear {
            previewPlayer?.pause()
        }
    }
    
    private func setupPreviewPlayer(for video: Video) {
        guard previewPlayer == nil else { return }
        
        let publicUrl = SupabaseManager.shared.getPublicVideoURL(for: video.storagePath)
        print("DEBUG MediaThumbnail: storagePath='\(video.storagePath)', publicURL=\(String(describing: publicUrl))")
        
        guard let url = publicUrl else {
            return
        }
        
        #if canImport(AVFoundation)
        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.actionAtItemEnd = .none
        newPlayer.isMuted = true // Always mute gallery thumbnails
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak newPlayer] _ in
            Task { @MainActor in
                newPlayer?.seek(to: .zero)
                newPlayer?.play()
            }
        }
        
        newPlayer.play()
        self.previewPlayer = newPlayer
        #endif
    }

    @ViewBuilder
    private func videoThumbnailContent(video: Video) -> some View {
        ZStack {
            // Background image or video
            if let player = previewPlayer {
                VideoPlayerContainer(player: player, contentMode: .fill, isVideoLoading: false)
            } else if let url = viewModel.videoThumbnailURL(for: video) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if phase.error != nil {
                        Color.terracotta.opacity(0.2)
                    } else {
                        ZStack {
                            Color.terracotta.opacity(0.2)
                            ProgressView().tint(.white)
                        }
                    }
                }
            } else {
                Color.terracotta.opacity(0.2)
            }
            
            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Image(systemName: "play.fill")
                                .font(.caption)
                            Text(video.title ?? "Видео")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .lineLimit(1)
                        }
                        if let subtitle = video.subtitle, !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.7))
                                .lineLimit(1)
                        }
                    }
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
                    LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom)
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
            // Background image
            if let url = viewModel.photoURL(for: photo) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if phase.error != nil {
                        Color.ochre.opacity(0.2)
                    } else {
                        ZStack {
                            Color.ochre.opacity(0.2)
                            ProgressView().tint(.white)
                        }
                    }
                }
            } else {
                Color.ochre.opacity(0.2)
            }
            
            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Image(systemName: "photo")
                                .font(.caption)
                            Text(photo.title ?? "Фото")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .lineLimit(1)
                        }
                        if let subtitle = photo.subtitle, !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.7))
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(12)
                .background(
                    LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                )
            }
        }
    }
}
