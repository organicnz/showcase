import SwiftUI

struct AmbientBackgroundView: View {
    @Environment(ViewModel.self) var viewModel: ViewModel
    @State internal var animate = false
    private let startDate = Date()

    var body: some View {
        ZStack {
            #if os(iOS)
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSince(startDate)
                
                if #available(iOS 18.0, *) {
                    meshGradient(time: time, colors: viewModel.currentThemeColors)
                        .ignoresSafeArea()
                } else {
                    canvasGradient(time: time, colors: viewModel.currentThemeColors)
                        .ignoresSafeArea()
                }
            }
            #else
            fallbackImage
            #endif

            // Glass Overlay
            Color.soft.opacity(0.2)
                .ignoresSafeArea()
                .overlay(.ultraThinMaterial)
        }
    }

    @available(iOS 18.0, *)
    private func meshGradient(time: Double, colors: [Color]) -> some View {
        let t = Float(time * 0.5)
        let baseColors = colors.count >= 3 ? colors : [Color.ink, Color.terracotta, Color.ochre]
        
        return MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.5 + 0.1 * sin(t), 0.5 + 0.1 * cos(t)], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1]
            ],
            colors: [
                baseColors[0], baseColors[1], baseColors[2],
                baseColors[1], baseColors[0].opacity(0.8), baseColors[2],
                baseColors[2], baseColors[0], baseColors[1]
            ]
        )
        .blur(radius: 40)
        .animation(.easeInOut(duration: 2.0), value: colors)
    }

    private func canvasGradient(time: Double, colors: [Color]) -> some View {
        let baseColors = colors.count >= 2 ? colors : [Color.ink, Color.terracotta]
        
        return Canvas { context, size in
            let t = time * 0.3
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(baseColors[0].opacity(0.8)))
            
            // Draw organic "blobs" with Metal-like blending
            for i in 0..<3 {
                let x = size.width * (0.5 + 0.3 * sin(t + Double(i)))
                let y = size.height * (0.5 + 0.3 * cos(t * 0.8 + Double(i)))
                let rect = CGRect(x: x - 200, y: y - 200, width: 400, height: 400)
                
                context.fill(
                    Circle().path(in: rect),
                    with: .radialGradient(
                        Gradient(colors: [baseColors[min(i, baseColors.count - 1)].opacity(0.4), .clear]),
                        center: CGPoint(x: x, y: y),
                        startRadius: 0,
                        endRadius: 200
                    )
                )
            }
        }
        .blur(radius: 60)
        .animation(.easeInOut(duration: 2.0), value: colors)
    }

    private var fallbackImage: some View {
        Image("ImmersiveBG", bundle: .module)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .scaleEffect(animate ? 1.1 : 1.0)
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 15).repeatForever(autoreverses: true)) {
                    animate = true
                }
            }
    }
}
