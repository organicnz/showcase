import SwiftUI
import ShowcaseCore

/// Card component for video display
public struct VideoCard: View {
    let video: Video
    let onTap: () -> Void
    
    public init(video: Video, onTap: @escaping () -> Void) {
        self.video = video
        self.onTap = onTap
    }
    
    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: LiquidGlassTheme.Spacing.md) {
                // Thumbnail placeholder
                RoundedRectangle(cornerRadius: LiquidGlassTheme.CornerRadius.small)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 68)
                    .overlay(
                        Image(systemName: "play.fill")
                            .foregroundColor(.white.opacity(0.8))
                    )
                
                VStack(alignment: .leading, spacing: LiquidGlassTheme.Spacing.xs) {
                    Text(video.title ?? "Untitled")
                        .font(Typography.body)
                        .foregroundColor(LiquidGlassTheme.Colors.primary)
                        .lineLimit(2)
                    
                    if let duration = video.durationSec {
                        Text("\(duration)s")
                            .font(Typography.caption1)
                            .foregroundColor(LiquidGlassTheme.Colors.secondary)
                    }
                }
                
                Spacer()
            }
            .frame(height: 100)
            .padding(LiquidGlassTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: LiquidGlassTheme.CornerRadius.medium)
                    .fill(LiquidGlassTheme.Materials.ultraThin)
            )
        }
        .buttonStyle(.plain)
    }
}
