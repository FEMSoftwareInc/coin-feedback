//
//  coinApp.swift
//  coin
//
//  Created by Mauricio Neri on 2026-01-23.
//

import SwiftUI
import SwiftData

@main
struct coinApp: App {
    @StateObject private var purchaseManager = PurchaseManager()
    @StateObject private var cloudKitService = CloudKitService()
    
    let sharedModelContainer: ModelContainer
    
    init() {
        let schema = Schema([
            FeedbackEntry.self,
            ShareEvent.self,
        ])
        
        // Start with local-only configuration
        // CloudKit sync can be enabled later via CloudKitService
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            self.sharedModelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            // Fallback to in-memory store to avoid startup crash
            let fallbackConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
            do {
                self.sharedModelContainer = try ModelContainer(
                    for: schema,
                    configurations: [fallbackConfiguration]
                )
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            HistoryView(purchaseManager: purchaseManager)
                .environmentObject(purchaseManager)
                .environmentObject(cloudKitService)
        }
        .modelContainer(sharedModelContainer)
    }
}
