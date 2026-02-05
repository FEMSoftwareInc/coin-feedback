import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \FeedbackEntry.createdAt, order: .reverse) var entries: [FeedbackEntry]
    @State private var showCreateSheet = false
    @State private var showPaywall = false
    @Environment(\.modelContext) var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var purchaseManager: PurchaseManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("History")
                            .font(.system(size: 34, weight: .bold))
                            .tracking(0.5)
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        Text("\(entries.count) entries")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(AppColors.textSecondary(for: colorScheme))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    
                    // Content
                    if entries.isEmpty {
                        emptyState
                            .frame(maxHeight: .infinity)
                    } else {
                        ScrollView(.vertical, showsIndicators: true) {
                            VStack(spacing: 12) {
                                ForEach(entries) { entry in
                                    NavigationLink(value: entry) {
                                        EntryCardView(entry: entry)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                    }
                }
            }
            .navigationDestination(for: FeedbackEntry.self) { selectedEntry in
                EntryDetailView(entry: selectedEntry)
            }
            .overlay(alignment: .bottomTrailing) {
                // Floating action button
                Button(action: { 
                    // Check if user is pro or under limit
                    if !purchaseManager.isProUser && entries.count >= 10 {
                        showPaywall = true
                    } else {
                        showCreateSheet = true
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
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
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
            .sheet(isPresented: $showCreateSheet) {
                CoinEditorView(entry: nil)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(purchaseManager: purchaseManager)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textSecondary(for: colorScheme).opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No entries yet")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                
                Text("Create your first COIN feedback entry to get started")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { 
                // Check if user is pro or under limit
                if !purchaseManager.isProUser && entries.count >= 10 {
                    showPaywall = true
                } else {
                    showCreateSheet = true
                }
            }) {
                Text("Create Entry")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
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
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            .padding(.top, 12)
        }
    }
}

#Preview {
    let purchaseManager = PurchaseManager()
    return HistoryView(purchaseManager: purchaseManager)
        .environmentObject(purchaseManager)
        .modelContainer(for: FeedbackEntry.self, inMemory: true)
}
