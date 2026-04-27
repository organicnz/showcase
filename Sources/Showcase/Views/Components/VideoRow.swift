import SwiftUI

struct VideoRow: View {
    let video: Video
    let action: () -> Void
    @Environment(ViewModel.self) var viewModel: ViewModel
    @State internal var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Thumbnail placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .fill(
                            LinearGradient(
                                colors: [Color.ochre.opacity(0.15), Color.terracotta.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 60)

                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.terracotta.opacity(0.7))
                }

                // Video info
                VStack(alignment: .leading, spacing: 6) {
                    Text(video.title ?? "Без названия")
                        .font(.bodyLarge)
                        .fontWeight(.medium)
                        .foregroundStyle(.ink)
                        .lineLimit(1)

                    HStack(spacing: 12) {
                        if let duration = video.durationSec {
                            Label(formatDuration(duration), systemImage: "clock")
                                .font(.bodySmall2)
                                .foregroundStyle(.mid)
                        }

                        Label("#\(video.orderIndex)", systemImage: "number")
                            .font(.bodySmall2)
                            .foregroundStyle(.mid)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.mid.opacity(0.5))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(Color.soft.opacity(0.001)) // Make entire row tappable
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }

    /// Formats seconds into a human-readable string (e.g., "0:28").
    private func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return "\(mins):\(String(format: "%02d", secs))"
    }
}
