import SwiftUI

/// View for displaying service states (loading, error, empty)
public struct ServiceStateView: View {
    let icon: String
    let message: String
    let action: (() -> Void)?
    
    public init(icon: String, message: String, action: (() -> Void)? = nil) {
        self.icon = icon
        self.message = message
        self.action = action
    }
    
    public var body: some View {
        VStack(spacing: LiquidGlassTheme.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(LiquidGlassTheme.Colors.secondary)
            
            Text(message)
                .font(Typography.body)
                .foregroundColor(LiquidGlassTheme.Colors.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, LiquidGlassTheme.Spacing.xl)
            
            if let action = action {
                Button(action: action) {
                    Text("Retry")
                        .font(Typography.buttonMedium)
                        .foregroundColor(LiquidGlassTheme.Colors.primary)
                        .padding(.horizontal, LiquidGlassTheme.Spacing.lg)
                        .padding(.vertical, LiquidGlassTheme.Spacing.md)
                        .background(LiquidGlassTheme.Materials.ultraThin)
                        .cornerRadius(LiquidGlassTheme.CornerRadius.medium)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
