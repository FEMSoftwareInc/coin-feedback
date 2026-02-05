import SwiftUI

struct GlassSampleView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            AppColors.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary(for: colorScheme))
                        Text("Calm Focus")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        Spacer()
                    }
                    Text("A quiet, glassy surface for thoughtful feedback.")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary(for: colorScheme))
                }
                .padding(AppSpacing.md)
                .glassCard(cornerRadius: 24, borderOpacity: 0.20, shadowOpacity: 0.10, shadowRadius: 16)

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        Image(systemName: "paperplane")
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.textSecondary(for: colorScheme))
                        Text("Share with care")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary(for: colorScheme))
                    }
                    Text("Send gentle, clear notes without visual noise.")
                        .font(.footnote)
                        .foregroundColor(AppColors.textSecondary(for: colorScheme))
                }
                .padding(AppSpacing.md)
                .glassCard(cornerRadius: 26, borderOpacity: 0.18, shadowOpacity: 0.12, shadowRadius: 18)

                HStack(spacing: AppSpacing.md) {
                    Button {
                        // Primary action
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle")
                            Text("Confirm")
                        }
                    }
                    .buttonStyle(GlassPrimaryButtonStyle())

                    Button {
                        // Secondary action
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "questionmark.circle")
                            Text("Learn more")
                        }
                    }
                    .buttonStyle(GlassSecondaryTextButtonStyle())
                }
            }
            .padding(AppSpacing.lg)
        }
    }
}

#Preview {
    GlassSampleView()
}
