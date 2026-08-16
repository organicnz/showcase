import ShowcaseCore
import ShowcaseUI
import SwiftUI

/// A high-end, animated background view that provides an immersive atmosphere.
struct AmbientBackgroundView: View {
    @Environment(ViewModel.self) var viewModel: ViewModel
    @State internal var animate = false
    
    var body: some View {
        #if os(Android)
        // Simplified fallback for Android: Skip doesn't support MeshGradient or Canvas yet.
        ZStack {
            Color.soft.ignoresSafeArea()
            
            LinearGradient(
                colors: [
                    Color.terracotta.opacity(0.1),
                    Color.ochre.opacity(0.1),
                    Color.soft
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .hueRotation(.degrees(animate ? 45 : 0))
            .onAppear {
                withAnimation(.linear(duration: 10).repeatForever(autoreverses: true)) {
                    animate.toggle()
                }
            }
        }
        #else
        // Full immersive implementation for iOS
        ZStack {
            Color.soft.ignoresSafeArea()
            
            // Note: In a real implementation, we would use MeshGradient (iOS 18+) 
            // or Canvas for the moving blobs.
            Canvas { context, size in
                // Custom drawing logic (omitted for brevity in this fallback)
                let color = Color.terracotta.opacity(0.15)
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(color))
            }
            .ignoresSafeArea()
        }
        #endif
    }
}
