import Foundation
import SwiftData

@Model
final class ShareEvent {
    var entryId: String = ""
    var sharedAt: Date = Date()
    var recipientEmail: String = ""
    var recipientName: String = ""
    
    init(entryId: String, recipientEmail: String, recipientName: String = "") {
        self.entryId = entryId
        self.sharedAt = Date()
        self.recipientEmail = recipientEmail
        self.recipientName = recipientName
    }
}
