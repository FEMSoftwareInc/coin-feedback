import SwiftUI
import SwiftData

struct DetailView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    let entry: FeedbackEntry
    
    @State private var showShareSheet = false
    @State private var showEmailComposer = false
    @State private var showPaywall = false
    @State private var isEditing = false
    @State private var shareMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GlassCardSection(title: "Context", content: entry.context)
                GlassCardSection(title: "Observation", content: entry.observation)
                GlassCardSection(title: "Impact", content: entry.impact)
                GlassCardSection(title: "Next Steps", content: entry.nextSteps)
                
                // Share history with glassmorphism
                if let sharedAt = entry.sharedAt {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Share History")
                                .font(.headline)
                        }
                        .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Shared \(entry.shareCount) time(s)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            if let email = entry.recipientEmail, !email.isEmpty {
                                Text("To: \(email)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            if let name = entry.recipientName, !name.isEmpty {
                                Text("Recipient: \(name)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Text("Last shared: \(sharedAt.formatted())")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(12)
                    }
                    .modifier(GlassCardModifier())
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Feedback Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: { isEditing = true }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(action: { showEmailComposer = true }) {
                        Label("Share via Email", systemImage: "envelope")
                    }
                    Button(role: .destructive, action: { deleteEntry() }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            CoinEditorView(entry: entry)
        }
        .sheet(isPresented: $showEmailComposer) {
            EmailComposerView(entry: entry, isPresented: $showEmailComposer) { recipientEmail, recipientName in
                entry.markAsShared(to: recipientEmail, recipientName: recipientName)
                try? modelContext.save()
            }
        }
    }
    
    private func deleteEntry() {
        modelContext.delete(entry)
        try? modelContext.save()
        dismiss()
    }
}

struct GlassCardSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.blue)
            Text(content)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding(12)
        .modifier(GlassCardModifier())
    }
}

#Preview {
    DetailView(entry: FeedbackEntry(context: "Sample context", observation: "Sample observation", impact: "Sample impact", nextSteps: "Sample next steps"))
}
