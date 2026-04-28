import SwiftUI

struct LoadingView: View {
    @State internal var isAnimate = false
    @State internal var textOpacity: Double = 0
    private let startDate = Date()

    var body: some View {
        ZStack {
            // Ambient Shimmer Background
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSince(startDate)
                let phase = sin(time * 0.5)
                
                LinearGradient(
                    colors: [
                        .soft,
                        .terracotta.opacity(0.05 + 0.05 * phase),
                        .soft
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }

            VStack(spacing: 40) {
                // Animated Jewel Logo
                ZStack {
                    // Multi-layer pulse
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(Color.terracotta.opacity(0.1), lineWidth: 1)
                            .frame(width: 120, height: 120)
                            .scaleEffect(isAnimate ? 2.5 : 0.8)
                            .opacity(isAnimate ? 0 : 0.4)
                            .animation(.easeOut(duration: 3).repeatForever(autoreverses: false).delay(Double(i) * 0.8), value: isAnimate)
                    }

                    LogoView(size: 100)
                        .shadow(color: .black.opacity(0.05), radius: 20)
                        .scaleEffect(isAnimate ? 1.0 : 0.9)
                }

                VStack(spacing: 16) {
                    Text("Мещерский парк")
                        .font(.displaySmall)
                        .tracking(2)
                        .foregroundStyle(.ink)
                        .opacity(textOpacity)

                    Text("Загрузка витрины...")
                        .font(.labelCaps)
                        .foregroundStyle(.mid)
                        .opacity(textOpacity * 0.6)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.5, dampingFraction: 0.8)) {
                isAnimate = true
            }
            withAnimation(.easeIn(duration: 1.2).delay(0.5)) {
                textOpacity = 1.0
            }
        }
    }
}
