import SwiftUI
import SwiftData

struct CreateEditView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    let entry: FeedbackEntry?
    
    @State private var context = ""
    @State private var observation = ""
    @State private var impact = ""
    @State private var nextSteps = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Context")) {
                    TextEditor(text: $context)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .frame(minHeight: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.secondarySystemBackground))
                        )
                }
                
                Section(header: Text("Observation")) {
                    TextEditor(text: $observation)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .frame(minHeight: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.secondarySystemBackground))
                        )
                }
                
                Section(header: Text("Impact")) {
                    TextEditor(text: $impact)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .frame(minHeight: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.secondarySystemBackground))
                        )
                }
                
                Section(header: Text("Next Steps")) {
                    TextEditor(text: $nextSteps)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .frame(minHeight: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.secondarySystemBackground))
                        )
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(entry == nil ? "New Feedback" : "Edit Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") { saveFeedback() }
                        .disabled(context.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let entry = entry {
                    context = entry.context
                    observation = entry.observation
                    impact = entry.impact
                    nextSteps = entry.nextSteps
                }
            }
        }
    }
    
    private func saveFeedback() {
        if let entry = entry {
            entry.context = context
            entry.observation = observation
            entry.impact = impact
            entry.nextSteps = nextSteps
            entry.updatedAt = Date()
        } else {
            let newEntry = FeedbackEntry(
                context: context,
                observation: observation,
                impact: impact,
                nextSteps: nextSteps
            )
            modelContext.insert(newEntry)
        }
        
        dismiss()
    }
}

#Preview {
    CreateEditView(entry: nil)
}
