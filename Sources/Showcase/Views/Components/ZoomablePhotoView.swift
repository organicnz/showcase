import ShowcaseCore
import ShowcaseUI
import SwiftUI

/// A high-performance, zoomable photo view with pinch-to-zoom and double-tap-to-reset.
/// Provides a bleeding-edge gallery experience for luxury showcase assets.
struct ZoomablePhotoView: View {
    let url: URL
    @State internal var scale: CGFloat = 1.0
    @State internal var lastScale: CGFloat = 1.0
    @State internal var offset: CGSize = .zero
    @State internal var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView().tint(.white)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        #if !os(Android)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale *= delta
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0)) {
                                        if scale < 1.0 {
                                            scale = 1.0
                                            offset = .zero
                                        }
                                    }
                                }
                        )
                        #endif
                        #if !os(Android)
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    if scale > 1.0 {
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0)) {
                                        if scale <= 1.0 {
                                            offset = .zero
                                            lastOffset = .zero
                                        }
                                    }
                                }
                        )
                        #endif
                        .onTapGesture(count: 2) {
                            withAnimation(.spring(duration: 0.5, bounce: 0, blendDuration: 0)) {
                                if scale > 1.0 {
                                    scale = 1.0
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = 2.0
                                }
                            }
                        }
                case .failure:
                    Image(systemName: "photo.badge.exclamationmark")
                        .foregroundStyle(.white.opacity(0.3))
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}
