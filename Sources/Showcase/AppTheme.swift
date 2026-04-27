import SwiftUI

/// User-selectable appearance theme, persisted via `@AppStorage`.
///
/// Supports three modes:
/// - `.system` — follows the device appearance
/// - `.light` — forces light mode
/// - `.dark` — forces dark mode
public enum AppTheme: String, CaseIterable, Sendable {
    case system = "Системная"
    case light = "Светлая"
    case dark = "Тёмная"

    /// The `ColorScheme` to apply, or `nil` for system default.
    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    /// SF Symbol icon for each theme option.
    public var iconName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}
