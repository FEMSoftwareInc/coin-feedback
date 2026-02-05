import SwiftUI

struct CoinSectionView: View {
    let label: String
    let title: String
    let placeholder: String
    @Binding var text: String
    var focusedField: FocusState<CoinEditorView.CoinField?>.Binding
    let fieldType: CoinEditorView.CoinField
    @Environment(\.colorScheme) private var colorScheme
    
    var characterCount: Int {
        text.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack(spacing: 12) {
                // COIN Label Circle
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.2, green: 0.5, blue: 0.9).opacity(0.8),
                                    Color(red: 0.3, green: 0.6, blue: 0.95).opacity(0.6)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    Text(label)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Section Title
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                
                Spacer()
                
                // Character Counter
                Text("\(characterCount)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
                    .monospacedDigit()
            }
            
            // Text Editor with Glass Card Style
            ZStack(alignment: .topLeading) {
                // Custom TextEditor with glass effect
                TextEditor(text: $text)
                    .focused(focusedField, equals: fieldType)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
                    .padding(12)
                    .background(Color.clear)
                    .onChange(of: text) { oldValue, newValue in
                        // Autosave trigger - update timestamp
                        // This is handled in the parent view on save
                    }
                
                // Placeholder overlay
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.textSecondary(for: colorScheme).opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }
            .modifier(GlassCardModifier())
        }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var sampleText = ""
    @Previewable @FocusState var focusedField: CoinEditorView.CoinField?
    
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
        
        VStack {
            CoinSectionView(
                label: "C",
                title: "Context",
                placeholder: "Describe the situation, setting, or background...",
                text: $sampleText,
                focusedField: $focusedField,
                fieldType: .context
            )
            .padding()
        }
    }
}

#Preview("With Text") {
    @Previewable @State var sampleText = "During our team standup meeting this morning, we discussed the upcoming Q4 product roadmap and feature prioritization."
    @Previewable @FocusState var focusedField: CoinEditorView.CoinField?
    
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
        
        VStack {
            CoinSectionView(
                label: "O",
                title: "Observation",
                placeholder: "What did you observe? Be specific and objective...",
                text: $sampleText,
                focusedField: $focusedField,
                fieldType: .observation
            )
            .padding()
        }
    }
}

#Preview("Near Limit") {
    @Previewable @State var sampleText = String(repeating: "This is a long text to test the character counter. ", count: 9)
    @Previewable @FocusState var focusedField: CoinEditorView.CoinField?
    
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
        
        VStack {
            CoinSectionView(
                label: "I",
                title: "Impact",
                placeholder: "What was the effect or consequence?",
                text: $sampleText,
                focusedField: $focusedField,
                fieldType: .impact
            )
            .padding()
        }
    }
}
