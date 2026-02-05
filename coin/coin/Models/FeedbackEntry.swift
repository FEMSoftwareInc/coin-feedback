import Foundation
import SwiftData
import NaturalLanguage

@Model
final class FeedbackEntry {
    // MARK: - Properties
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // COIN fields
    var context: String = ""
    var observation: String = ""
    var impact: String = ""
    var nextSteps: String = ""
    
    // Recipient info
    var recipientName: String?
    var recipientEmail: String?
    
    // Share tracking
    var sharedAt: Date?
    var shareCount: Int = 0
    
    // CloudKit sync metadata
    var cloudKitIdentifier: String = ""
    var isCloudKitSynced: Bool = false
    
    // MARK: - Initializer
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        context: String = "",
        observation: String = "",
        impact: String = "",
        nextSteps: String = "",
        recipientName: String? = nil,
        recipientEmail: String? = nil,
        sharedAt: Date? = nil,
        shareCount: Int = 0,
        cloudKitIdentifier: String = "",
        isCloudKitSynced: Bool = false
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.context = context
        self.observation = observation
        self.impact = impact
        self.nextSteps = nextSteps
        self.recipientName = recipientName
        self.recipientEmail = recipientEmail
        self.sharedAt = sharedAt
        self.shareCount = shareCount
        self.cloudKitIdentifier = cloudKitIdentifier
        self.isCloudKitSynced = isCloudKitSynced
    }

    // MARK: - Computed Properties
    var isShared: Bool {
        sharedAt != nil
    }

    var coinSummary: String {
        // Use local ML-based summarization
        return TextSummarizer.shared.summarize(
            context: context,
            observation: observation,
            impact: impact,
            nextSteps: nextSteps
        )
    }

    // MARK: - Validation Constants
    static let maxCOINLength = 800
    static let maxEmailLength = 254

    // MARK: - Validation Helpers
    var isCOINValid: Bool {
        !context.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !observation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !impact.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !nextSteps.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        context.count <= Self.maxCOINLength &&
        observation.count <= Self.maxCOINLength &&
        impact.count <= Self.maxCOINLength &&
        nextSteps.count <= Self.maxCOINLength
    }

    var isRecipientEmailValid: Bool {
        guard let email = recipientEmail else { return true }
        return email.count <= Self.maxEmailLength && isValidEmail(email)
    }

    private func isValidEmail(_ email: String) -> Bool {
        let regex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: regex, options: .regularExpression) != nil
    }

    // MARK: - Methods
    /// Mark entry as shared
    func markAsShared(to recipientEmail: String, recipientName: String = "") {
        self.sharedAt = Date()
        self.shareCount += 1
        self.recipientEmail = recipientEmail
        self.recipientName = recipientName
        self.updatedAt = Date()
    }
}
