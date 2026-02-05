import Foundation
import CloudKit
import SwiftData
import Combine

@MainActor
class CloudKitService: ObservableObject {
    @Published var isSyncEnabled = false
    @Published var syncStatus = "Not synced"
    @Published var lastSyncDate: Date?
    
    private let container: CKContainer
    private let database: CKDatabase
    
    init() {
        // Use default CloudKit container
        self.container = CKContainer.default()
        self.database = container.privateCloudDatabase
        
        checkCloudKitAvailability()
    }
    
    /// Check if iCloud and CloudKit are available
    func checkCloudKitAvailability() {
        container.accountStatus { accountStatus, error in
            DispatchQueue.main.async {
                if accountStatus == .available {
                    self.isSyncEnabled = true
                    self.syncStatus = "Ready to sync"
                } else {
                    self.isSyncEnabled = false
                    self.syncStatus = "iCloud not available"
                }
            }
        }
    }
    
    /// Sync a feedback entry to CloudKit
    func syncEntry(_ entry: FeedbackEntry) {
        guard isSyncEnabled else {
            syncStatus = "CloudKit not available"
            return
        }
        
        let record = CKRecord(recordType: "FeedbackEntry")
        record["context"] = entry.context
        record["observation"] = entry.observation
        record["impact"] = entry.impact
        record["nextSteps"] = entry.nextSteps
        record["recipientName"] = entry.recipientName
        record["recipientEmail"] = entry.recipientEmail
        record["sharedAt"] = entry.sharedAt
        record["shareCount"] = entry.shareCount as CKRecordValue
        record["createdAt"] = entry.createdAt
        record["updatedAt"] = entry.updatedAt
        
        database.save(record) { [weak self] record, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncStatus = "Sync failed: \(error.localizedDescription)"
                } else {
                    self?.lastSyncDate = Date()
                    self?.syncStatus = "Synced"
                    
                    if let record = record {
                        self?.syncStatus = "Synced: \(record.recordID.recordName)"
                    }
                }
            }
        }
    }
    
    /// Fetch entries from CloudKit
    func fetchEntriesFromCloud(completion: @escaping ([CKRecord]?, Error?) -> Void) {
        guard isSyncEnabled else {
            completion(nil, NSError(domain: "CloudKitService", code: -1, userInfo: nil))
            return
        }
        
        let query = CKQuery(recordType: "FeedbackEntry", predicate: NSPredicate(value: true))
        
        database.fetch(withQuery: query, completionHandler: { result in
            switch result {
            case .success(let (matchResults, _)):
                let records = matchResults.compactMap { try? $0.1.get() }
                DispatchQueue.main.async {
                    self.lastSyncDate = Date()
                    self.syncStatus = "Fetched \(records.count) entries"
                    completion(records, nil)
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.syncStatus = "Fetch failed: \(error.localizedDescription)"
                    completion(nil, error)
                }
            }
        })
    }
    
    /// Delete entry from CloudKit
    func deleteEntry(_ entry: FeedbackEntry) {
        guard !entry.cloudKitIdentifier.isEmpty else { return }
        guard isSyncEnabled else { return }
        
        let recordID = CKRecord.ID(recordName: entry.cloudKitIdentifier)
        
        database.delete(withRecordID: recordID) { [weak self] _, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncStatus = "Delete failed: \(error.localizedDescription)"
                } else {
                    self?.lastSyncDate = Date()
                    self?.syncStatus = "Entry deleted from cloud"
                }
            }
        }
    }
}
