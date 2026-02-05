import SwiftUI
import CloudKit

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(
                    ".modelContainer",
                    modelContainer
                )
        }
    }
}