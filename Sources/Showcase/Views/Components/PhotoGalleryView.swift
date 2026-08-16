import ShowcaseCore
import ShowcaseUI
import SwiftUI

struct PhotoGalleryView: View {
    @Environment(ViewModel.self) var viewModel: ViewModel
    let photos: [Photo]
    
    @State internal var selection = 0
    
    var body: some View {
        if photos.isEmpty {
            VStack(spacing: 24) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 80, weight: .ultraLight))
                    .foregroundStyle(Color.terracotta.opacity(0.6))
                    #if !os(Android)
                    .symbolEffect(.bounce, value: true)
                    #endif

                VStack(spacing: 12) {
                    Text("Галерея наполняется")
                        .font(.displaySmall)
                        .foregroundStyle(.white)
                    
                    Text("Скоро здесь появятся уникальные кадры этого сценария.")
                        .font(.bodyLarge)
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ZStack(alignment: .bottom) {
                TabView(selection: $selection) {
                    ForEach(0..<photos.count, id: \.self) { index in
                        let photo = photos[index]
                        ZStack {
                            if let url = viewModel.photoURL(for: photo) {
                                ZoomablePhotoView(url: url)
                            }
                        }
                        .tag(index)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                #if !os(macOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif
                .ignoresSafeArea()
                .onChange(of: selection) { _, _ in
                    HapticManager.shared.impact(style: .light)
                }

                // Custom Premium Indicator
                if photos.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(0..<photos.count, id: \.self) { index in
                            Capsule()
                                .fill(selection == index ? Color.terracotta : Color.white.opacity(0.3))
                                .frame(width: selection == index ? 24 : 6, height: 6)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0), value: selection)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 0.5))
                    .padding(.bottom, 40)
                    .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                }
            }
        }
    }
}

#if !os(Android)
#Preview {
    PhotoGalleryView(photos: [])
        .background(Color.black)
        .environment(ViewModel())
}
#endif
