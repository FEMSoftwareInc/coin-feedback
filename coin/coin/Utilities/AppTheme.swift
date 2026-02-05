import SwiftUI

// MARK: - App Theme
enum AppColors {
    // Calm, low-saturation background gradient
    static let backgroundTop = Color(red: 0.90, green: 0.93, blue: 0.96)
    static let backgroundBottom = Color(red: 0.88, green: 0.91, blue: 0.95)
    static let backgroundTopDark = Color(red: 0.12, green: 0.14, blue: 0.18)
    static let backgroundBottomDark = Color(red: 0.10, green: 0.12, blue: 0.16)

    static let primaryAccent = Color(red: 0.42, green: 0.56, blue: 0.72)
    static let primaryAccentDark = Color(red: 0.32, green: 0.45, blue: 0.60)

    static let sharedAccent = Color(red: 0.26, green: 0.62, blue: 0.42)
    static let sharedAccentDark = Color(red: 0.20, green: 0.52, blue: 0.36)

    static let textLightPrimary = Color(red: 0.12, green: 0.14, blue: 0.18)
    static let textLightSecondary = Color(red: 0.36, green: 0.40, blue: 0.46)

    static let textDarkPrimary = Color(red: 0.90, green: 0.92, blue: 0.96)
    static let textDarkSecondary = Color(red: 0.70, green: 0.74, blue: 0.80)

    static func textPrimary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? textDarkPrimary : textLightPrimary
    }

    static func textSecondary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? textDarkSecondary : textLightSecondary
    }

    static func backgroundGradient(for scheme: ColorScheme) -> LinearGradient {
        let colors = scheme == .dark
            ? [backgroundTopDark, backgroundBottomDark]
            : [backgroundTop, backgroundBottom]
        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}
