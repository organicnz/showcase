import SwiftUI

public struct LogoView: View {
    let size: CGFloat

    public init(size: CGFloat = 100) {
        self.size = size
    }

    public var body: some View {
        // Using the new refined 'Master' logo asset
        Image("AppLogo", bundle: .module)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22)) // App icon style rounding
            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
    }
}

