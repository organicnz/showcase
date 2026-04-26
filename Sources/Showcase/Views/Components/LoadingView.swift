import SwiftUI

struct LoadingView: View {
    @State internal var isPulsing = false
    @State internal var textOpacity: Double = 0.3

    var body: some View {
        VStack(spacing: 30) {
            // Animated Logo with pulsing effect
            ZStack {
                // Outer ring pulse — terracotta accent
                Circle()
                    .stroke(Color.terracotta.opacity(0.2), lineWidth: 2)
                    .frame(width: 140, height: 140)
                    .scaleEffect(isPulsing ? 1.2 : 0.9)
                    .opacity(isPulsing ? 0 : 0.6)
                    .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: false), value: isPulsing)

                // Glass circle
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)

                // Icon — terracotta to ochre gradient
                Image(systemName: "building.2.fill")
                    .font(.system(size: 50, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.terracotta, .ochre],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(isPulsing ? 1.05 : 0.95)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isPulsing)
            }

            VStack(spacing: 12) {
                Text("Мещерский парк")
                    .font(.displaySmall)
                    .foregroundStyle(.ink)

                Text("Загрузка витрины...")
                    .font(.bodyLarge)
                    .foregroundStyle(.mid)
                    .opacity(textOpacity)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: textOpacity)

                ProgressView()
                    .tint(.terracotta)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.soft.ignoresSafeArea())
        .onAppear {
            isPulsing = true
            textOpacity = 1.0
        }
    }
}
