import SwiftUI

// MARK: - Glass Card Modifier (Liquid Glass Effect)
struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .modifier(
                GlassStyle(
                    cornerRadius: 20,
                    borderOpacity: 0.20,
                    shadowOpacity: 0.10,
                    shadowRadius: 14
                )
            )
    }
}

// MARK: - View Extension for Glass Card
extension View {
    func glassCard() -> some View {
        self.modifier(GlassCardModifier())
    }
}

#Preview {
    ZStack {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.85, green: 0.90, blue: 0.95),
                Color(red: 0.90, green: 0.85, blue: 0.95)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack(spacing: 24) {
            // Glass card with text
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Context")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("Team feedback session")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                }
                
                Divider()
                    .opacity(0.3)
                
                Text("This is a preview of the glass card effect with the glassmorphism aesthetic applied.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.primary)
                    .lineLimit(3)
            }
            .padding(16)
            .glassCard()
            
            // Another variant with different content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Observation")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Spacer()
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
                Text("Created 2 hours ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .glassCard()
            
            Spacer()
        }
        .padding(16)
    }
}
