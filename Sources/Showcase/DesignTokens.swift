import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Adaptive Color Helper

#if canImport(UIKit)
extension Color {
    /// Creates a color that automatically adapts between light and dark appearances.
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

    /// Creates a color with alpha that automatically adapts between light and dark appearances.
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
#endif

// MARK: - Brand Colors
// Design tokens — match Соль Девелопмент brand platform (UI_UX.md §2)
// All primary colors adapt automatically between light and dark appearances.

extension Color {

    // ── Primary ──────────────────────────────────────────────────────

    #if canImport(UIKit)
    /// Угольный — base text, adapts to warm off-white in dark mode
    static let ink = Color(
        lightRed: 0.102, lightGreen: 0.102, lightBlue: 0.180,   // #1A1A2E
        darkRed: 0.941, darkGreen: 0.933, darkBlue: 0.910       // #F0EECA → warm off-white
    )

    /// Мягкий — warm background, adapts to rich charcoal in dark mode
    static let soft = Color(
        lightRed: 0.969, lightGreen: 0.961, lightBlue: 0.949,   // #F7F5F2
        darkRed: 0.098, darkGreen: 0.098, darkBlue: 0.133       // #191922
    )
    #else
    // Fallback for macOS / SKIP (Android) — light-mode static values
    static let ink = Color(red: 0.102, green: 0.102, blue: 0.180)
    static let soft = Color(red: 0.969, green: 0.961, blue: 0.949)
    #endif

    // ── Accent (same in both modes) ──────────────────────────────────

    /// Терракота — primary accent, CTAs
    static let terracotta = Color(red: 0.753, green: 0.224, blue: 0.169)  // #C0392B
    /// Охра — secondary warm accent
    static let ochre = Color(red: 0.784, green: 0.663, blue: 0.431)       // #C8A96E

    // ── Neutrals ─────────────────────────────────────────────────────

    #if canImport(UIKit)
    /// Средний — captions, metadata; slightly brighter in dark mode for contrast
    static let mid = Color(
        lightRed: 0.541, lightGreen: 0.533, lightBlue: 0.502,   // #8A8880
        darkRed: 0.620, darkGreen: 0.612, darkBlue: 0.588       // #9E9C96
    )
    #else
    static let mid = Color(red: 0.541, green: 0.533, blue: 0.502)
    #endif

    // ── Surface Tokens ───────────────────────────────────────────────
    // Used for card backgrounds, list rows, and borders that were
    // previously hardcoded as Color.white.opacity(...).

    #if canImport(UIKit)
    /// Card surface — translucent white in light, subtle white in dark
    static let cardSurface = Color(
        lightRed: 1.0, lightGreen: 1.0, lightBlue: 1.0, lightAlpha: 0.80,
        darkRed: 1.0, darkGreen: 1.0, darkBlue: 1.0, darkAlpha: 0.08
    )

    /// Card border stroke
    static let cardBorder = Color(
        lightRed: 1.0, lightGreen: 1.0, lightBlue: 1.0, lightAlpha: 1.0,
        darkRed: 1.0, darkGreen: 1.0, darkBlue: 1.0, darkAlpha: 0.12
    )

    /// List row surface
    static let rowSurface = Color(
        lightRed: 1.0, lightGreen: 1.0, lightBlue: 1.0, lightAlpha: 0.60,
        darkRed: 1.0, darkGreen: 1.0, darkBlue: 1.0, darkAlpha: 0.06
    )
    #else
    static let cardSurface = Color.white.opacity(0.80)
    static let cardBorder = Color.white
    static let rowSurface = Color.white.opacity(0.60)
    #endif

    // ── Liquid Glass tints (iPadOS 26) ───────────────────────────────

    static let glassTint = Color(red: 0.102, green: 0.102, blue: 0.180).opacity(0.04)
    static let glassStroke = Color(red: 0.102, green: 0.102, blue: 0.180).opacity(0.12)
}

// MARK: - ShapeStyle Convenience

extension ShapeStyle where Self == Color {
    static var ink: Color { Color.ink }
    static var soft: Color { Color.soft }
    static var terracotta: Color { Color.terracotta }
    static var ochre: Color { Color.ochre }
    static var mid: Color { Color.mid }
    static var cardSurface: Color { Color.cardSurface }
    static var cardBorder: Color { Color.cardBorder }
    static var rowSurface: Color { Color.rowSurface }
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
