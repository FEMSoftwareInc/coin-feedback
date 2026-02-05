import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \FeedbackEntry.createdAt, order: .reverse) var entries: [FeedbackEntry]
    @State private var showCreateSheet = false
    @State private var selectedEntry: FeedbackEntry?
    @State private var showPaywall = false
    
    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No feedback entries yet")
                            .font(.headline)
                        Text("Create your first COIN feedback entry to get started")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(entries) { entry in
                            NavigationLink(value: entry) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.context)
                                        .font(.headline)
                                        .lineLimit(1)
                                    HStack {
                                        Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Spacer()
                                        if entry.sharedAt != nil {
                                            Image(systemName: "paperplane.fill")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: deleteEntries)
                    }
                }
            }
            .navigationTitle("COIN Feedback")
            .navigationDestination(for: FeedbackEntry.self) { entry in
                EntryDetailView(entry: entry)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showCreateSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateEditView(entry: nil)
            }
        }
    }
    
    private func deleteEntries(offsets: IndexSet) {
        for index in offsets {
            entries[index].context = ""
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: FeedbackEntry.self, inMemory: true)
}
