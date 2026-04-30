import SwiftUI
import ShowcaseCore

/// Playback controls component for tablet display
public struct PlaybackControls: View {
    let state: PlaybackState
    let onPlayPause: () -> Void
    let onNext: () -> Void
    let onStop: () -> Void
    
    public init(
        state: PlaybackState,
        onPlayPause: @escaping () -> Void,
        onNext: @escaping () -> Void,
        onStop: @escaping () -> Void
    ) {
        self.state = state
        self.onPlayPause = onPlayPause
        self.onNext = onNext
        self.onStop = onStop
    }
    
    public var body: some View {
        VStack(spacing: LiquidGlassTheme.Spacing.md) {
            // Current video info
            if let video = state.currentVideo {
                Text(video.title ?? "Playing...")
                    .font(Typography.bodyBold)
                    .foregroundColor(LiquidGlassTheme.Colors.primary)
                
                if case .playing(_, let queue, let index) = state {
                    Text("\(index + 1) of \(queue.count)")
                        .font(Typography.caption1)
                        .foregroundColor(LiquidGlassTheme.Colors.secondary)
                }
            }
            
            // Control buttons
            HStack(spacing: LiquidGlassTheme.Spacing.lg) {
                Button(action: onPlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 32))
                        .foregroundColor(LiquidGlassTheme.Colors.primary)
                }
                
                Button(action: onNext) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 32))
                        .foregroundColor(state.hasNext ? LiquidGlassTheme.Colors.primary : LiquidGlassTheme.Colors.secondary)
                }
                .disabled(!state.hasNext)
                
                Button(action: onStop) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 32))
                        .foregroundColor(LiquidGlassTheme.Colors.primary)
                }
            }
        }
        .padding(LiquidGlassTheme.Spacing.lg)
        .background(LiquidGlassTheme.Materials.ultraThin)
        .cornerRadius(LiquidGlassTheme.CornerRadius.large)
    }
    
    private var isPlaying: Bool {
        if case .playing = state {
            return true
        }
        return false
    }
}
