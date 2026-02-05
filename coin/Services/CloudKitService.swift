import SwiftData
import CloudKit

struct FeedbackEntry: Model {
    @Attribute(.primaryKey) var id: UUID
    var feedbackText: String
    var createdAt: Date
}

struct ShareEvent: Model {
    @Attribute(.primaryKey) var id: UUID
    var eventDescription: String
    var createdAt: Date
}

let container = ModelContainer(schema: Schema([FeedbackEntry.self, ShareEvent.self]))

// Configure CloudKit
let cloudKitContainer = CKContainer.default()
let cloudKitOptions = CloudKitOptions(container: cloudKitContainer)

// Enable iCloud sync
let modelContainer = ModelContainer(schema: Schema([FeedbackEntry.self]), options: cloudKitOptions)