import SwiftUI

struct LoginView: View {
    @Environment(ViewModel.self) var viewModel: ViewModel
    @State internal var email = ""
    @State internal var password = ""
    @State internal var isLoading = false
    @State internal var errorMessage: String? = nil
    @State internal var isAnimating = false

    var body: some View {
        ZStack {
            // Immersive Ambient Background
            AmbientBackgroundView()

            VStack(spacing: 40) {
                // Header
                VStack(spacing: 16) {
                    LogoView(size: 80)
                        .scaleEffect(isAnimating ? 1.0 : 0.9)
                        .opacity(isAnimating ? 1.0 : 0.0)

                    VStack(spacing: 8) {
                        Text("МЕЩЕРСКИЙ ПАРК")
                            .font(.labelCaps)
                            .tracking(6)
                            .foregroundStyle(Color.terracotta)

                        Text("Вход в систему")
                            .font(.displayMedium)
                            .foregroundStyle(.ink)
                    }
                    .offset(y: isAnimating ? 0 : 20)
                    .opacity(isAnimating ? 1.0 : 0.0)
                }

                // Login Form
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        customTextField(title: "Email", text: $email, icon: "envelope")
                        customSecureField(title: "Пароль", text: $password, icon: "lock")
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .transition(.opacity)
                    }

                    Button(action: handleLogin) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 8)
                            }
                            Text("Войти")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.terracotta)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.button))
                        .shadow(color: Color.terracotta.opacity(0.3), radius: 10, y: 5)
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.modal)
                        .fill(Color.cardSurface)
                        .shadow(color: .ink.opacity(0.1), radius: 30, x: 0, y: 15)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.modal)
                        .stroke(Color.cardBorder, lineWidth: 1)
                )
                .frame(maxWidth: 400)
                .offset(y: isAnimating ? 0 : 40)
                .opacity(isAnimating ? 1.0 : 0.0)

                // Footer
                Text("Только для авторизованных сотрудников")
                    .font(.caption)
                    .foregroundStyle(.mid)
                    .opacity(isAnimating ? 0.6 : 0.0)
            }
            .padding(24)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
    }

    // MARK: - Components

    @ViewBuilder
    private func customTextField(title: String, text: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.labelCaps)
                .foregroundStyle(.mid)

            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.terracotta.opacity(0.7))
                    .frame(width: 20)

                TextField("example@mail.com", text: text)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            .padding()
            .background(Color.soft.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.small)
                    .stroke(Color.ink.opacity(0.1), lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private func customSecureField(title: String, text: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.labelCaps)
                .foregroundStyle(.mid)

            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.terracotta.opacity(0.7))
                    .frame(width: 20)

                SecureField("••••••••", text: text)
                    .textContentType(.password)
            }
            .padding()
            .background(Color.soft.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.small)
                    .stroke(Color.ink.opacity(0.1), lineWidth: 1)
            )
        }
    }

    // MARK: - Actions

    private func handleLogin() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await viewModel.login(email: email, password: password)
                isLoading = false
            } catch {
                errorMessage = "Ошибка входа: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

}
