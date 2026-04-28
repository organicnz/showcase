import SwiftUI

struct HighlightsOverlay: View {
    let highlights: [String]
    
    @State internal var currentIndex = 0
    @State internal var isVisible = false
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                if isVisible {
                    Text(highlights[currentIndex].uppercased())
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .kerning(4)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(.black.opacity(0.3))
                                .background(Capsule().stroke(.white.opacity(0.1), lineWidth: 0.5))
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                }
                
                Spacer()
            }
        }
        .onAppear {
            startCycling()
        }
    }
    
    private func startCycling() {
        guard !highlights.isEmpty else { return }
        isVisible = true
        
        Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                
                withAnimation(.easeInOut(duration: 0.8)) {
                    isVisible = false
                }
                
                try? await Task.sleep(nanoseconds: 800_000_000)
                
                currentIndex = (currentIndex + 1) % highlights.count
                withAnimation(.easeInOut(duration: 0.8)) {
                    isVisible = true
                }
            }
        }
    }
}
