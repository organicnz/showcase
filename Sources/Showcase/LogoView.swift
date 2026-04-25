import SwiftUI

public struct LogoView: View {
    public init() {}
    
    public var body: some View {
        ZStack {
            // Glass Backdrop
            Circle()
                .fill(.thinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.2), lineWidth: 0.5)
                )
            
            // Premium Golden Banana Shape
            ZStack {
                BananaShape()
                    .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-15))
            }
            .opacity(0.9)
            
            // Play Icon (Showcase Indicator)
            Image(systemName: "play.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .shadow(radius: 2)
                .offset(x: 2, y: 2)
        }
        .frame(width: 100, height: 100)
    }
}

private struct BananaShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // A simple curved banana-like shape
        path.move(to: CGPoint(x: rect.minX + 10, y: rect.minY + 10))
        path.addCurve(to: CGPoint(x: rect.maxX - 10, y: rect.maxY - 10),
                      control1: CGPoint(x: rect.maxX, y: rect.minY),
                      control2: CGPoint(x: rect.maxX, y: rect.midY))
        path.addCurve(to: CGPoint(x: rect.minX + 10, y: rect.minY + 10),
                      control1: CGPoint(x: rect.midX, y: rect.maxY),
                      control2: CGPoint(x: rect.minX, y: rect.midY))
        return path
    }
}
