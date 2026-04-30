import SwiftUI

/// Liquid Glass design language theme for iOS/iPadOS 26
public enum LiquidGlassTheme {
    // MARK: - Colors
    
    public enum Colors {
        public static let primary = Color.white
        public static let secondary = Color.gray
        public static let accent = Color.blue
        public static let background = Color.black
        public static let surface = Color.white.opacity(0.1)
    }
    
    // MARK: - Materials
    
    public enum Materials {
        public static let ultraThin = Material.ultraThinMaterial
        public static let thin = Material.thinMaterial
        public static let regular = Material.regularMaterial
    }
    
    // MARK: - Corner Radius
    
    public enum CornerRadius {
        public static let small: CGFloat = 8
        public static let medium: CGFloat = 16
        public static let large: CGFloat = 20
        public static let extraLarge: CGFloat = 24
    }
    
    // MARK: - Spacing
    
    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
    }
}
