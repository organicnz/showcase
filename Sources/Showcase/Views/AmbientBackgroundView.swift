import SwiftUI

/// A high-end, animated background view that provides an immersive atmosphere.
///
/// `AmbientBackgroundView` uses a multi-layered rendering strategy:
/// 1. **MeshGradient (iOS 18+)**: Uses the latest native Metal-backed mesh for fluid color blending.
/// 2. **Liquid Canvas (Fallback)**: A custom `Canvas` implementation that renders 6 layers of
///    moving radial gradients with organic offset math.
/// 3. **Static Image (Fallback)**: A high-quality static asset used if dynamic rendering is unavailable.
///
/// The colors are dynamically derived from the `viewModel.currentThemeColors`, ensuring the
/// background matches the brand palette of the selected scenario.
struct AmbientBackgroundView: View {
    @Environment(ViewModel.self) var viewModel: ViewModel
    
    /// Internal state for simple fallback animations.
    @State internal var animate = false
    
    /// The reference date used to drive the time-based animations.
    private let startDate = Date()

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                TimelineView(.animation) { timeline in
                    let time = timeline.date.timeIntervalSince(startDate)
                    let colors = viewModel.currentThemeColors
                    
                    #if os(iOS) || os(macOS)
                    #if !SKIP
                    if #available(iOS 18.0, macOS 15.0, *) {
                        meshGradient(time: time, colors: colors)
                            .ignoresSafeArea()
                    } else {
                        // MODERN RENDERING: High-end Liquid Canvas
                        liquidCanvas(time: time, colors: colors)
                            .ignoresSafeArea()
                    }
                    #else
                    liquidCanvas(time: time, colors: colors)
                        .ignoresSafeArea()
                    #endif
                    #else
                    fallbackImage
                    #endif
                }
            }

            // Glass Overlay
            Color.soft.opacity(0.15)
                .ignoresSafeArea()
                .overlay(.ultraThinMaterial)
        }
    }

    #if os(iOS) || os(macOS)
    /// Renders a fluid mesh using iOS 18+ MeshGradient.
    ///
    /// - Parameters:
    ///   - time: The current animation time.
    ///   - colors: The theme colors to blend.
    @available(iOS 18.0, macOS 15.0, *)
    private func meshGradient(time: Double, colors: [Color]) -> some View {
        #if !SKIP
        let t = Float(time * 0.4)
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
        #else
        return EmptyView()
        #endif
    }
    #endif

    /// Renders a custom organic motion background using the SwiftUI Canvas.
    ///
    /// - Parameters:
    ///   - time: The current animation time.
    ///   - colors: The theme colors to use for the radial gradients.
    ///
    /// This method creates 6 layers of "blobs" that move using sine/cosine offsets,
    /// creating a liquid-like appearance without requiring specialized shaders.
    private func liquidCanvas(time: Double, colors: [Color]) -> some View {
        let baseColors = colors.count >= 2 ? colors : [Color.ink, Color.terracotta]
        
        return Canvas { context, size in
            let t = time * 0.2
            
            // Base layer (Deepest)
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(baseColors[0]))
            
            // 6 Layers of organic motion
            for i in 0..<6 {
                let offset = Double(i) * 1.5
                let speed = 0.5 + Double(i) * 0.1
                
                let x = size.width * (0.5 + 0.4 * sin(t * speed + offset))
                let y = size.height * (0.5 + 0.3 * cos(t * speed * 0.8 + offset * 1.2))
                
                let blobSize = size.width * (0.7 + 0.15 * sin(t * 0.4 + offset))
                let rect = CGRect(x: x - blobSize/2, y: y - blobSize/2, width: blobSize, height: blobSize)
                
                let colorIndex = i % baseColors.count
                let opacity = 0.25 - (Double(i) * 0.02)
                let color = baseColors[colorIndex].opacity(opacity)
                
                context.fill(
                    Circle().path(in: rect),
                    with: .radialGradient(
                        Gradient(colors: [color, .clear]),
                        center: CGPoint(x: x, y: y),
                        startRadius: 0,
                        endRadius: blobSize / 2
                    )
                )
            }
        }
        .blur(radius: 90)
    }

    /// A static image fallback with a gentle scale animation.
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
