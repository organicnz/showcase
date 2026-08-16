import ShowcaseCore
import ShowcaseUI
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
                    .fill(Color.mid.opacity(0.08))
                    .frame(width: 100, height: 100)

                Image(systemName: systemImage)
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(.mid.opacity(0.6))
            }

            VStack(spacing: 12) {
                Text(title)
                    .font(.displaySmall)
                    .foregroundStyle(.ink)

                if let description = description {
                    Text(description)
                        .font(.bodyLarge)
                        .foregroundStyle(.mid)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.modal)
                .fill(Color.cardSurface)
                .shadow(color: .ink.opacity(0.05), radius: 20, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.modal)
                .stroke(Color.cardBorder, lineWidth: 1)
        )
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

