import SwiftUI

public struct LogoView: View {
    let size: CGFloat

    public init(size: CGFloat = 100) {
        self.size = size
    }

    private var playOuterSize: CGSize {
        CGSize(width: size * 0.44, height: size * 0.50)
    }

    private var playInnerSize: CGSize {
        CGSize(width: size * 0.20, height: size * 0.24)
    }

    public var body: some View {
        ZStack {
            // Glass Backdrop
            Circle()
                .fill(.thinMaterial)
                .overlay(
                    Circle()
                        .stroke(Color.glassStroke, lineWidth: 0.5)
                )

            // Outer Architectural Play Button
            PlayShape()
                .stroke(
                    LinearGradient(
                        colors: [.ochre, .terracotta],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: size > 50 ? 2.5 : 1.5, lineJoin: .round)
                )
                .frame(width: playOuterSize.width, height: playOuterSize.height)
                .offset(x: size * 0.04)

            // Inner Solid Play Button
            PlayShape()
                .fill(
                    LinearGradient(
                        colors: [.ochre, .terracotta],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: playInnerSize.width, height: playInnerSize.height)
                .offset(x: size * 0.04)
        }
        .frame(width: size, height: size)
    }
}

private struct PlayShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

