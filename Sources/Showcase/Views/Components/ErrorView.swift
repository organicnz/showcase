import SwiftUI

struct ErrorView: View {
    let error: Error
    let retryAction: () -> Void
    @State internal var isAnimating = false

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.terracotta.opacity(0.1))
                        .frame(width: 80, height: 80)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)

                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(.terracotta)
                }

                Text("Ошибка соединения")
                    .font(.displaySmall)
                    .foregroundStyle(.ink)
            }

            VStack(spacing: 16) {
                Text(error.localizedDescription)
                    .font(.bodyLarge)
                    .foregroundStyle(.mid)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text("Проверьте подключение к интернету и попробуйте снова.")
                    .font(.bodySmall2)
                    .foregroundStyle(.mid.opacity(0.6))
            }

            Button(action: retryAction) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Повторить")
                }
                .font(.bodyLarge)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(Color.terracotta)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.soft.ignoresSafeArea())
        .onAppear {
            isAnimating = true
        }
    }
}
