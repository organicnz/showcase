import SwiftUI

struct LoadingView: View {
    @State internal var isAnimating = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Animated Logo
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .shadow(color: .black.opacity(0.1), radius: 20)
                
                Image(systemName: "building.2.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isAnimating)
            }
            
            VStack(spacing: 12) {
                Text("Meshchersky Park")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Loading showcase...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                ProgressView()
                    .padding(.top, 8)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}
