import SwiftUI

// MARK: - Glass Style (Liquid Glass)
struct GlassStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    var cornerRadius: CGFloat = 24
    var borderOpacity: Double = 0.20
    var shadowOpacity: Double = 0.10
    var shadowRadius: CGFloat = 16

    func body(content: Content) -> some View {
        let gradientColors: [Color] = colorScheme == .dark
            ? [Color.white.opacity(0.10), Color.black.opacity(0.25)]
            : [Color.white.opacity(0.12), Color.white.opacity(0.04)]
        let borderAlpha = min(colorScheme == .dark ? borderOpacity + 0.05 : borderOpacity, 0.25)

        content
            .background {
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: gradientColors),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .blur(radius: 8)

                    Color.clear
                        .background(.ultraThinMaterial)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(borderAlpha), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: Color.black.opacity(shadowOpacity),
                radius: shadowRadius,
                x: 0,
                y: 6
            )
    }
}

// MARK: - View Extension
extension View {
    func glassCard(
        cornerRadius: CGFloat = 24,
        borderOpacity: Double = 0.20,
        shadowOpacity: Double = 0.10,
        shadowRadius: CGFloat = 16
    ) -> some View {
        modifier(
            GlassStyle(
                cornerRadius: cornerRadius,
                borderOpacity: borderOpacity,
                shadowOpacity: shadowOpacity,
                shadowRadius: shadowRadius
            )
        )
    }
}

// MARK: - Button Styles
struct GlassPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .background(
                AppColors.primaryAccent
                    .opacity(configuration.isPressed ? 0.80 : 0.95)
            )
            .glassCard(cornerRadius: 22, borderOpacity: 0.18, shadowOpacity: 0.12, shadowRadius: 14)
    }
}

struct GlassSecondaryTextButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(AppColors.textSecondary(for: colorScheme))
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
