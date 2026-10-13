---
name: liquid-glass-swiftui
description: Design system and SwiftUI implementation rules for the Liquid Glass aesthetic (iOS/iPadOS 26+). Use when building or styling UI components, cards, overlays, typography, micro-interactions, and responsive layouts tailored for iPad Pro sales presentations.
---

# Liquid Glass UI Mastery (SwiftUI & Skip Compose)

This skill dictates the visual design language, material systems, and ergonomic interaction patterns for the **Showcase (Meshchersky Park)** tablet application. 

The aesthetic identity is **"Liquid Glass" & "Quiet Luxury"**: deep materials, ultra-thin translucency, warm champagne/gold specular reflections, gentle micro-springs, and uncompromising readability under high-ambient lighting in sales galleries.

---

## 1. Visual Token Architecture

All UI components MUST consume centralized tokens defined in `ShowcaseTheme.swift` and `ThemeTokens.swift`. Never hardcode raw hex values or arbitrary blur radiuses.

### Color & Material Palette
* **Deep Ink Background (`Color.ink`):** `#0F1115` / `#161920` — rich, deep black-slate backdrop that enhances contrast.
* **Champagne Gold Specular (`Color.gold` / `Color.accent`):** `#D4AF37` / `#C5A059` — used exclusively for active states, subtle borders, and delicate glows.
* **Card Surface (`Color.cardSurface`):** Adaptive ultra-thin fill (light: 80% opacity white, dark: 8% opacity white).
* **Card Border (`Color.cardBorder`):** Subtle outline (light: 30% opacity, dark: 15% opacity).
* **Glass Tint & Stroke (`Color.glassTint`, `Color.glassStroke`):** 4% tint, 12% stroke for floating chrome.

```swift
// MARK: - Recommended Card Background Pattern
.background(
    RoundedRectangle(cornerRadius: 24, style: .continuous)
        .fill(Color.cardSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.cardBorder,
                            Color.cardBorder.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
)
```

---

## 2. iPad Pro Responsive Layouts

The application runs primarily in **landscape orientation on iPad Pro (11-inch & 13-inch)**.

### Ergonomic Guidelines:
1. **Target Dimensions:** Optimize for 2388×1668 (11") and 2732×2048 (13") screen bounds.
2. **Touch Targets:** Minimum 48×48 pt for all interactive elements to prevent mis-taps during active customer dialogs.
3. **Margins & Spacing:**
   * Outer safe margins: `32pt` minimum.
   * Inter-card spacing: `20pt` to `24pt`.
   * Card padding: `24pt`.
4. **Information Density:** Avoid cluttered dashboards. Prioritize high-impact visual imagery and breathing room.

---

## 3. Micro-Animations & Fluid Physics

Quiet luxury demands subtle, physical, and non-distracting animations.

### Physics Constants:
* **Interactive Springs:** `Animation.spring(response: 0.35, dampingFraction: 0.75)`
* **Active Press Feedback:** Subtle scale down `scaleEffect(isPressed ? 0.98 : 1.0)` with soft haptic tap (`UIImpactFeedbackGenerator(style: .light)`).
* **Card Hover / Focus:** `scaleEffect(isSelected ? 1.02 : 1.0)` accompanied by gold border illumination.
* **Scene Cross-Fade:** Smooth 0.5s to 0.8s ease-in-out transitions when switching scenarios.

---

## 4. Skip Cross-Platform (Compose) Compatibility

Because `ShowcaseUI` transpiles to Android Jetpack Compose via Skip:
* **Prefer declarative Shapes:** `RoundedRectangle(cornerRadius:style:)` maps seamlessly to `androidx.compose.foundation.shape.RoundedCornerShape`.
* **Guard UIKit/AppKit Extensions:** Never call `UIColor` directly without `#if canImport(UIKit)` guards.
* **Avoid Nested Heavy Blurs:** Use `Color.cardSurface` opacity fills rather than complex stacked blur layers, ensuring 60fps performance on Android tablets.

---

## 5. Standard Component Template: `GlassScenarioCard`

```swift
import SwiftUI

public struct GlassScenarioCard: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    public init(title: String, subtitle: String, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.displayMedium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.bodySmall)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.cardSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(
                                isSelected ? Color.gold : Color.cardBorder,
                                lineWidth: isSelected ? 1.5 : 1.0
                            )
                    )
            )
            .shadow(
                color: isSelected ? Color.gold.opacity(0.15) : Color.black.opacity(0.08),
                radius: isSelected ? 16 : 8,
                x: 0,
                y: isSelected ? 8 : 4
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
```
