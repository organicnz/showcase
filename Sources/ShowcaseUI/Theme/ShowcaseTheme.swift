import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Adaptive Color Helper

#if canImport(UIKit)
extension Color {
    fileprivate init(
        lightRed lr: Double, lightGreen lg: Double, lightBlue lb: Double,
        darkRed dr: Double, darkGreen dg: Double, darkBlue db: Double
    ) {
        self.init(UIColor { traits in
            if traits.userInterfaceStyle == .dark {
                return UIColor(red: dr, green: dg, blue: db, alpha: 1.0)
            } else {
                return UIColor(red: lr, green: lg, blue: lb, alpha: 1.0)
            }
        })
    }

    fileprivate init(
        lightRed lr: Double, lightGreen lg: Double, lightBlue lb: Double, lightAlpha la: Double,
        darkRed dr: Double, darkGreen dg: Double, darkBlue db: Double, darkAlpha da: Double
    ) {
        self.init(UIColor { traits in
            if traits.userInterfaceStyle == .dark {
                return UIColor(red: dr, green: dg, blue: db, alpha: da)
            } else {
                return UIColor(red: lr, green: lg, blue: lb, alpha: la)
            }
        })
    }
}
#elseif canImport(AppKit)
extension Color {
    fileprivate init(
        lightRed lr: Double, lightGreen lg: Double, lightBlue lb: Double,
        darkRed dr: Double, darkGreen dg: Double, darkBlue db: Double
    ) {
        self.init(NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua {
                return NSColor(red: dr, green: dg, blue: db, alpha: 1.0)
            } else {
                return NSColor(red: lr, green: lg, blue: lb, alpha: 1.0)
            }
        })
    }

    fileprivate init(
        lightRed lr: Double, lightGreen lg: Double, lightBlue lb: Double, lightAlpha la: Double,
        darkRed dr: Double, darkGreen dg: Double, darkBlue db: Double, darkAlpha da: Double
    ) {
        self.init(NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua {
                return NSColor(red: dr, green: dg, blue: db, alpha: da)
            } else {
                return NSColor(red: lr, green: lg, blue: lb, alpha: la)
            }
        })
    }
}
#endif

// MARK: - Surface Tokens

extension Color {
    #if canImport(UIKit) || canImport(AppKit)
    public static let cardSurface = Color(
        lightRed: 1.0, lightGreen: 1.0, lightBlue: 1.0, lightAlpha: 0.80,
        darkRed: 1.0, darkGreen: 1.0, darkBlue: 1.0, darkAlpha: 0.08
    )
    public static let cardBorder = Color(
        lightRed: 1.0, lightGreen: 1.0, lightBlue: 1.0, lightAlpha: 0.30,
        darkRed: 1.0, darkGreen: 1.0, darkBlue: 1.0, darkAlpha: 0.15
    )
    public static let rowSurface = Color(
        lightRed: 1.0, lightGreen: 1.0, lightBlue: 1.0, lightAlpha: 0.60,
        darkRed: 1.0, darkGreen: 1.0, darkBlue: 1.0, darkAlpha: 0.06
    )
    #else
    public static let cardSurface = Color.white.opacity(0.80)
    public static let cardBorder = Color.white.opacity(0.30)
    public static let rowSurface = Color.white.opacity(0.60)
    #endif

    public static let glassTint = Color.ink.opacity(0.04)
    public static let glassStroke = Color.ink.opacity(0.12)
}

extension Font {
    public static let displayLarge = Typography.displayLarge
    public static let displayMedium = Typography.displayMedium
    public static let displaySmall = Typography.displaySmall
    public static let bodyLarge = Typography.bodyLarge
    public static let bodySmall = Typography.bodySmall
    public static let bodySmall2 = Typography.bodySmall2
    public static let bodyBold = Typography.bodyBold
    public static let labelCaps = Typography.labelCaps
}

// MARK: - ShapeStyle Convenience

extension ShapeStyle where Self == Color {
    public static var ink: Color { Color.ink }
    public static var soft: Color { Color.soft }
    public static var terracotta: Color { Color.terracotta }
    public static var ochre: Color { Color.ochre }
    public static var mid: Color { Color.mid }
    public static var cardSurface: Color { Color.cardSurface }
    public static var cardBorder: Color { Color.cardBorder }
    public static var rowSurface: Color { Color.rowSurface }
}

// MARK: - Typography & Spacing Shim

public enum Typography {
    // Note: In production, these should be replaced with Inter or Outfit fonts via Info.plist
    public static let displayLarge = Font.system(size: 52, weight: .bold, design: .rounded)
    public static let displayMedium = Font.system(size: 42, weight: .bold, design: .rounded)
    public static let displaySmall = Font.system(size: 34, weight: .bold, design: .rounded)
    public static let bodyLarge = Font.system(size: 20, weight: .regular)
    public static let body = Font.system(size: 18, weight: .regular)
    public static let bodyBold = Font.system(size: 18, weight: .semibold)
    public static let bodySmall = Font.system(size: 16, weight: .regular)
    public static let bodySmall2 = Font.system(size: 15, weight: .regular)
    public static let callout = Font.system(size: 17, weight: .regular)
    public static let caption1 = Font.system(size: 13, weight: .regular)
    public static let caption2 = Font.system(size: 12, weight: .regular)
    public static let labelCaps = Font.system(size: 11, weight: .medium)
    public static let buttonMedium = Font.system(size: 18, weight: .medium)
}

public enum LiquidGlassTheme {
    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
    }
    public enum Colors {
        public static let primary = Color.ink
        public static let secondary = Color.mid
        public static let accent = Color.terracotta
        public static let background = Color.soft
    }
    public enum CornerRadius {
        public static let small: CGFloat = 8
        public static let medium: CGFloat = 12
        public static let large: CGFloat = 20
        public static let extraLarge: CGFloat = 28
    }
    public enum Materials {
        /// Ultra-thin glass for light overlays
        public static let ultraThin = Color.white.opacity(0.08)
        /// Standard glass material with subtle glow
        public static let thin = Color.white.opacity(0.15)
        /// Thick frosted glass for cards
        public static let regular = Color.white.opacity(0.25)
        /// Deep dark glass for modals
        public static let thick = Color.black.opacity(0.4)
    }
    
    public enum Shadows {
        public static let subtle = Color.black.opacity(0.05)
        public static let medium = Color.black.opacity(0.12)
        public static let deep = Color.black.opacity(0.25)
    }
}
