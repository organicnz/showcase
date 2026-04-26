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
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.mid.opacity(0.08))
                    .frame(width: 100, height: 100)

                Image(systemName: systemImage)
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(.mid.opacity(0.5))
            }

            VStack(spacing: 8) {
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
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
