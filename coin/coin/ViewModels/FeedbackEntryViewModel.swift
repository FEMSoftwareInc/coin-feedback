import Foundation
import SwiftData
import Combine

@MainActor
class FeedbackEntryViewModel: ObservableObject {
    @Published var entries: [FeedbackEntry] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchEntries()
    }
    
    func fetchEntries() {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let descriptor = FetchDescriptor<FeedbackEntry>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            entries = try modelContext.fetch(descriptor)
        } catch {
            self.error = error
        }
    }
    
    func createEntry(context: String, observation: String, impact: String, nextSteps: String) {
        let entry = FeedbackEntry(
            context: context,
            observation: observation,
            impact: impact,
            nextSteps: nextSteps
        )
        modelContext.insert(entry)
        saveChanges()
        fetchEntries()
    }
    
    func updateEntry(_ entry: FeedbackEntry, context: String, observation: String, impact: String, nextSteps: String) {
        entry.context = context
        entry.observation = observation
        entry.impact = impact
        entry.nextSteps = nextSteps
        entry.updatedAt = Date()
        saveChanges()
        fetchEntries()
    }
    
    func deleteEntry(_ entry: FeedbackEntry) {
        modelContext.delete(entry)
        saveChanges()
        fetchEntries()
    }
    
    func shareEntry(_ entry: FeedbackEntry, to email: String, recipientName: String = "") {
        entry.markAsShared(to: email, recipientName: recipientName)
        saveChanges()
    }
    
    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            self.error = error
        }
    }
}
