import SwiftUI

/// Typography styles for the Showcase app
public enum Typography {
    // MARK: - Headings
    
    public static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)
    public static let title1 = Font.system(size: 28, weight: .bold, design: .default)
    public static let title2 = Font.system(size: 22, weight: .bold, design: .default)
    public static let title3 = Font.system(size: 20, weight: .semibold, design: .default)
    
    // MARK: - Body
    
    public static let body = Font.system(size: 17, weight: .regular, design: .default)
    public static let bodyBold = Font.system(size: 17, weight: .semibold, design: .default)
    public static let callout = Font.system(size: 16, weight: .regular, design: .default)
    
    // MARK: - Captions
    
    public static let caption1 = Font.system(size: 12, weight: .regular, design: .default)
    public static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
    
    // MARK: - Touch-Optimized (Tablet)
    
    public static let buttonLarge = Font.system(size: 20, weight: .semibold, design: .default)
    public static let buttonMedium = Font.system(size: 17, weight: .semibold, design: .default)
}
