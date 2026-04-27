import SwiftUI

struct EmptyStateView: View {
    let title: String
    let systemImage: String
    let description: String?

    init(_ title: String, systemImage: String, description: String? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.description = description
    }

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                // Outer glow
                Circle()
                    .fill(Color.terracotta.opacity(0.15))
                    .frame(width: 140, height: 140)
                    .blur(radius: 20)

                // Inner circle
                Circle()
                    .fill(colorScheme == .dark ? .white.opacity(0.05) : Color.mid.opacity(0.08))
                    .frame(width: 100, height: 100)

                Image(systemName: systemImage)
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(colorScheme == .dark ? .white.opacity(0.8) : .mid.opacity(0.6))
            }

            VStack(spacing: 12) {
                Text(title)
                    .font(.displaySmall)
                    .foregroundStyle(colorScheme == .dark ? .white : .ink)

                if let description = description {
                    Text(description)
                        .font(.bodyLarge)
                        .foregroundStyle(colorScheme == .dark ? .white.opacity(0.6) : .mid)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.modal)
                .fill(colorScheme == .dark ? .black.opacity(0.4) : .white.opacity(0.6))
                .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.05), radius: 20, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.modal)
                .stroke(colorScheme == .dark ? .white.opacity(0.1) : .white, lineWidth: 1)
        )
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
