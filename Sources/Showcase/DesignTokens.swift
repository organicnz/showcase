import SwiftUI

// MARK: - Brand Colors
// Design tokens — match Соль Девелопмент brand platform (UI_UX.md §2)

extension Color {
    // Primary
    /// Угольный — base text, dark surfaces
    static let ink = Color(red: 0.102, green: 0.102, blue: 0.180)         // #1A1A2E
    /// Мягкий — warm background
    static let soft = Color(red: 0.969, green: 0.961, blue: 0.949)        // #F7F5F2

    // Accent
    /// Терракота — primary accent, CTAs
    static let terracotta = Color(red: 0.753, green: 0.224, blue: 0.169)  // #C0392B
    /// Охра — secondary warm accent
    static let ochre = Color(red: 0.784, green: 0.663, blue: 0.431)       // #C8A96E

    // Neutrals
    /// Средний — captions, metadata
    static let mid = Color(red: 0.541, green: 0.533, blue: 0.502)         // #8A8880

    // Liquid Glass tints (iPadOS 26)
    static let glassTint = Color(red: 0.102, green: 0.102, blue: 0.180).opacity(0.04)
    static let glassStroke = Color(red: 0.102, green: 0.102, blue: 0.180).opacity(0.12)
}

extension ShapeStyle where Self == Color {
    static var ink: Color { Color.ink }
    static var soft: Color { Color.soft }
    static var terracotta: Color { Color.terracotta }
    static var ochre: Color { Color.ochre }
    static var mid: Color { Color.mid }
}

// MARK: - Brand Typography
// Cormorant Garamond (display) + Jost (body)
// Falls back to system fonts if custom fonts aren't bundled yet

extension Font {
    // Display — scenario titles, hero text
    static let displayLarge = Font.system(size: 48, weight: .light, design: .serif)
    static let displayMedium = Font.system(size: 32, weight: .regular, design: .serif)
    static let displaySmall = Font.system(size: 24, weight: .regular, design: .serif)

    // Body — descriptions, metadata
    static let bodyLarge = Font.system(size: 16, weight: .light)
    // bodyMedium intentionally omitted to avoid conflict with SwiftUI .body
    static let bodySmall2 = Font.system(size: 12, weight: .light)

    // Label — tags, pills, uppercase labels
    static let labelCaps = Font.system(size: 10, weight: .medium)
}

// MARK: - Corner Radii
// Spec: 8pt (small) · 12pt (card) · 20pt (large button) · 28pt (modal)

enum CornerRadius {
    static let small: CGFloat = 8
    static let card: CGFloat = 12
    static let button: CGFloat = 20
    static let modal: CGFloat = 28
}

// MARK: - Scenario Gradients
// Warm, muted gradients that complement the terracotta/ochre palette

enum ScenarioGradient {
    static func colors(for slug: String) -> [Color] {
        switch slug {
        case "family":
            return [Color(red: 0.82, green: 0.70, blue: 0.55),
                    Color(red: 0.90, green: 0.80, blue: 0.65)]
        case "wellness":
            return [Color(red: 0.55, green: 0.68, blue: 0.58),
                    Color(red: 0.68, green: 0.78, blue: 0.65)]
        case "guests":
            return [Color(red: 0.70, green: 0.60, blue: 0.68),
                    Color(red: 0.82, green: 0.72, blue: 0.78)]
        case "investor":
            return [Color(red: 0.80, green: 0.68, blue: 0.48),
                    Color(red: 0.90, green: 0.78, blue: 0.55)]
        case "architecture":
            return [Color(red: 0.52, green: 0.55, blue: 0.65),
                    Color(red: 0.65, green: 0.68, blue: 0.75)]
        default:
            return [.mid, .mid.opacity(0.5)]
        }
    }
}
