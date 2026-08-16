import SwiftUI

extension Color {
    public static let ink = Color(red: 0.102, green: 0.102, blue: 0.180)
    public static let soft = Color(red: 0.969, green: 0.961, blue: 0.949)
    public static let terracotta = Color(red: 0.753, green: 0.224, blue: 0.169)
    public static let ochre = Color(red: 0.784, green: 0.663, blue: 0.431)
    public static let mid = Color(red: 0.541, green: 0.533, blue: 0.502)
}

public enum CornerRadius {
    public static let small: CGFloat = 8
    public static let card: CGFloat = 12
    public static let button: CGFloat = 20
    public static let modal: CGFloat = 28
}

public enum ScenarioGradient {
    public static func colors(for slug: String) -> [Color] {
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
        case "privacy":
            return [Color(red: 0.20, green: 0.40, blue: 0.35),
                    Color(red: 0.35, green: 0.55, blue: 0.45)]
        default:
            return [.gray, .gray.opacity(0.5)]
        }
    }
    
    public static func primaryColor(for slug: String) -> Color {
        switch slug {
        case "family": return Color(red: 0.75, green: 0.60, blue: 0.45)
        case "wellness": return Color(red: 0.25, green: 0.45, blue: 0.30)
        case "guests": return Color(red: 0.60, green: 0.45, blue: 0.55)
        case "investor": return Color(red: 0.70, green: 0.55, blue: 0.35)
        case "architecture": return Color(red: 0.35, green: 0.40, blue: 0.55)
        case "privacy": return Color(red: 0.15, green: 0.35, blue: 0.25)
        default: return .blue
        }
    }
}
