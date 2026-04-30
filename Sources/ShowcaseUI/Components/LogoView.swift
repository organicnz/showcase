import SwiftUI

public struct LogoView: View {
    let size: CGFloat

    public init(size: CGFloat = 100) {
        self.size = size
    }

    public var body: some View {
        // Using the new refined 'Master' logo asset with a circular frame
        Image("ShowcaseLogo", bundle: .module)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.15), radius: size * 0.1, y: size * 0.05)
    }
}

