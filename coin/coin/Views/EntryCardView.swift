import SwiftUI
import SwiftData

struct EntryCardView: View {
    let entry: FeedbackEntry
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Left column: COIN badges
            VStack(spacing: 2) {
                ForEach(["C", "O", "I", "N"], id: \.self) { letter in
                    Text(letter)
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 24, height: 20)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    AppColors.primaryAccent,
                                    AppColors.primaryAccentDark
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(4)
                        .tracking(0.5)
                }
            }
            
            // Right column: Content
            VStack(alignment: .leading, spacing: 6) {
                // Row 1: Date and Shared status (aligned with C badge)
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        
                        Text(entry.createdAt.timeAgoDisplay)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(AppColors.textSecondary(for: colorScheme))
                    }
                    
                    Spacer()
                    
                    SharedStatusView(entry: entry)
                }
                
                // Row 2-4: Summary text (aligned with O, I, N badges)
                Text(entry.coinSummary)
                    .font(.system(size: 13, weight: .regular))
                    .lineLimit(4)
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .tracking(0.2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .glassCard()
    }
}

// MARK: - Shared Status Component
struct SharedStatusView: View {
    let entry: FeedbackEntry
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        if let sharedAt = entry.sharedAt {
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Shared")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            AppColors.sharedAccent,
                            AppColors.sharedAccentDark
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(5)
                
                Text(sharedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
            }
        } else {
            VStack(alignment: .trailing, spacing: 4) {
                Text("Not shared")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.textSecondary(for: colorScheme).opacity(colorScheme == .dark ? 0.22 : 0.12))
                    .cornerRadius(5)
                
                Text("—")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
            }
        }
    }
}

// MARK: - Date Extension for "time ago" display
extension Date {
    var timeAgoDisplay: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

#Preview {
    let entry = FeedbackEntry(
        context: "Team meeting about project roadmap",
        observation: "Discussed Q1 priorities",
        impact: "Aligned on feature timeline",
        nextSteps: "Schedule follow-up for Q2 planning",
        recipientEmail: "team@example.com",
        sharedAt: Date().addingTimeInterval(-86400)
    )
    
    VStack(spacing: 16) {
        EntryCardView(entry: entry)
        
        let unsharedEntry = FeedbackEntry(
            context: "Code review feedback",
            observation: "PR merged successfully",
            impact: "Improved code quality",
            nextSteps: "Apply learnings to future PRs"
        )
        EntryCardView(entry: unsharedEntry)
    }
    .padding(16)
    .background(
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.85, green: 0.90, blue: 0.95),
                Color(red: 0.90, green: 0.85, blue: 0.95)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    .modelContainer(for: FeedbackEntry.self, inMemory: true)
}
