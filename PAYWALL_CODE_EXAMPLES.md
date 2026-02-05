# StoreKit 2 Paywall - Code Examples

## Complete Implementation Examples

### 1. Checking Pro Status

```swift
import SwiftUI

struct MyFeatureView: View {
    @ObservedObject var purchaseManager: PurchaseManager
    
    var body: some View {
        if purchaseManager.isProUser {
            // Show premium feature
            PremiumFeatureView()
        } else {
            // Show limited feature
            Button("Upgrade to Pro") {
                showPaywall = true
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(purchaseManager: purchaseManager)
            }
        }
    }
    
    @State private var showPaywall = false
}
```

### 2. Gating Content on Purchase

```swift
struct FeatureView: View {
    @ObservedObject var purchaseManager: PurchaseManager
    @State private var showPaywall = false
    
    var body: some View {
        Button(action: { handleAction() }) {
            Text("Use Premium Feature")
        }
    }
    
    private func handleAction() {
        if purchaseManager.isProUser {
            // Feature available - proceed
            performFeature()
        } else {
            // Show paywall
            showPaywall = true
        }
    }
    
    private func performFeature() {
        // Your feature logic here
    }
}
```

### 3. Handling Purchases

```swift
struct PaywallExample: View {
    @ObservedObject var purchaseManager: PurchaseManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedProduct: Product?
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        VStack {
            if let product = selectedProduct {
                Button(action: { purchaseProduct(product) }) {
                    if purchaseManager.purchaseInProgress {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Purchase - \(product.displayPrice)")
                    }
                }
                .disabled(purchaseManager.purchaseInProgress)
            }
        }
        .alert("Purchase Failed", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
    }
    
    private func purchaseProduct(_ product: Product) {
        Task {
            if await purchaseManager.purchase(product) {
                // Purchase successful
                dismiss()
            } else {
                // Purchase failed
                errorMessage = purchaseManager.error?.localizedDescription
                showError = true
            }
        }
    }
}
```

### 4. Restoring Purchases

```swift
struct RestorePurchasesView: View {
    @ObservedObject var purchaseManager: PurchaseManager
    
    @State private var isRestoring = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Button(action: { restorePurchases() }) {
            if isRestoring {
                ProgressView()
            } else {
                Text("Restore Purchases")
            }
        }
        .disabled(isRestoring)
        .alert("Restore Complete", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func restorePurchases() {
        isRestoring = true
        Task {
            let success = await purchaseManager.restorePurchases()
            isRestoring = false
            
            if success {
                alertMessage = "Purchases restored successfully!"
                if purchaseManager.isProUser {
                    alertMessage += "\n\nYou're now a Pro user!"
                }
            } else {
                alertMessage = "No purchases to restore"
            }
            
            showAlert = true
        }
    }
}
```

### 5. Share Gating (as implemented)

```swift
struct EntryDetailView: View {
    @ObservedObject var purchaseManager: PurchaseManager
    @State private var showPaywall = false
    
    let entry: FeedbackEntry
    
    var body: some View {
        VStack {
            Button("Share via Email") {
                handleShare()
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(purchaseManager: purchaseManager)
        }
    }
    
    private func handleShare() {
        // Check if user is pro
        if !purchaseManager.isProUser {
            showPaywall = true
            return
        }
        
        // Continue with share flow
        // ... send email, etc.
    }
}
```

### 6. Entry Limit Gating (as implemented)

```swift
struct HistoryView: View {
    @Query var entries: [FeedbackEntry]
    @ObservedObject var purchaseManager: PurchaseManager
    
    @State private var showCreateSheet = false
    @State private var showPaywall = false
    
    var body: some View {
        Button(action: { handleCreateEntry() }) {
            Image(systemName: "plus")
        }
        .sheet(isPresented: $showCreateSheet) {
            CoinEditorView(entry: nil)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(purchaseManager: purchaseManager)
        }
    }
    
    private func handleCreateEntry() {
        // Check 10-entry limit
        if !purchaseManager.isProUser && entries.count >= 10 {
            showPaywall = true
            return
        }
        
        // Show creation sheet
        showCreateSheet = true
    }
}
```

### 7. Monitoring Purchase Manager State

```swift
struct SettingsView: View {
    @ObservedObject var purchaseManager: PurchaseManager
    
    var body: some View {
        List {
            Section("Account") {
                HStack {
                    Text("Pro Status")
                    Spacer()
                    Text(purchaseManager.isProUser ? "Pro" : "Free")
                        .foregroundColor(purchaseManager.isProUser ? .green : .gray)
                }
            }
            
            Section("Available Products") {
                ForEach(purchaseManager.products, id: \.id) { product in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(product.displayName)
                                .font(.headline)
                            Text(product.displayPrice)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Info") {
                            showProductInfo(product)
                        }
                    }
                }
            }
            
            if let error = purchaseManager.error {
                Section("Errors") {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    private func showProductInfo(_ product: Product) {
        print("Product: \(product.displayName)")
        print("Price: \(product.displayPrice)")
        print("ID: \(product.id)")
    }
}
```

### 8. Combining Multiple Gating Rules

```swift
struct FeatureAccessView: View {
    @ObservedObject var purchaseManager: PurchaseManager
    @Query var entries: [FeedbackEntry]
    
    @State private var showPaywall = false
    
    var canAccessFeature: Bool {
        // Pro users always have access
        if purchaseManager.isProUser {
            return true
        }
        
        // Free users have limited features
        // Example: Can share up to 5 times, create up to 10 entries
        return entries.count < 10 && entries.filter(\.sharedAt != nil).count < 5
    }
    
    var body: some View {
        if canAccessFeature {
            Button("Share Entry") {
                // Perform share
            }
        } else {
            Button("Unlock Sharing") {
                showPaywall = true
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(purchaseManager: purchaseManager)
            }
        }
    }
}
```

### 9. Product Details Display

```swift
struct ProductDetailsView: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(product.displayName)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(product.displayPrice)
                .font(.headline)
                .foregroundColor(.blue)
            
            if let description = product.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            // Subscription info if applicable
            if let subscription = product.subscription {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Billing Cycle:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("\(subscription.subscriptionPeriod.value) \(subscriptionPeriodUnit(subscription.subscriptionPeriod.unit))")
                        .font(.caption)
                }
            }
        }
    }
    
    private func subscriptionPeriodUnit(_ unit: Product.SubscriptionPeriod.Unit) -> String {
        switch unit {
        case .day: return "day(s)"
        case .week: return "week(s)"
        case .month: return "month(s)"
        case .year: return "year(s)"
        @unknown default: return "unknown"
        }
    }
}
```

### 10. Error Recovery

```swift
struct PurchaseWithErrorRecovery: View {
    @ObservedObject var purchaseManager: PurchaseManager
    
    @State private var showError = false
    @State private var showRetry = false
    @State private var lastError: Error?
    @State private var retryCount = 0
    
    var body: some View {
        VStack {
            if purchaseManager.purchaseInProgress {
                ProgressView()
                Text("Processing purchase...")
            } else {
                Button("Purchase") {
                    purchaseWithRetry()
                }
            }
        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("Retry", action: { purchaseWithRetry() })
                .disabled(retryCount >= 3)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(lastError?.localizedDescription ?? "Unknown error")
        }
    }
    
    private func purchaseWithRetry() {
        if retryCount >= 3 {
            showError = true
            return
        }
        
        retryCount += 1
        
        Task {
            if let product = purchaseManager.products.first {
                if await purchaseManager.purchase(product) {
                    retryCount = 0
                } else {
                    lastError = purchaseManager.error
                    showError = true
                }
            }
        }
    }
}
```

---

## Integration Checklist

- [ ] PurchaseManager created and in Services folder
- [ ] PaywallView updated with new design
- [ ] EntryDetailView has share gating
- [ ] HistoryView has 10-entry limit gating
- [ ] coinApp uses PurchaseManager instead of PaywallViewModel
- [ ] Products configured in App Store Connect
- [ ] Sandbox tester created for testing
- [ ] Build is clean (no compilation errors)
- [ ] Tested in simulator with Sandbox credentials
- [ ] Tested purchase flow
- [ ] Tested restore purchases
- [ ] Tested pro status updates

---

## Common Patterns

### Pattern 1: Lazy Evaluation
```swift
@State private var showPaywall = false

// Don't show paywall until user interacts
Button("Action") {
    guard purchaseManager.isProUser else {
        showPaywall = true
        return
    }
    performAction()
}
```

### Pattern 2: Feature Flags
```swift
struct FeatureFlags {
    @ObservedObject var pm: PurchaseManager
    
    var canShare: Bool { pm.isProUser }
    var canSync: Bool { pm.isProUser }
    var canExport: Bool { pm.isProUser }
    var unlimitedEntries: Bool { pm.isProUser }
}
```

### Pattern 3: Graceful Degradation
```swift
var entryLimit: Int {
    purchaseManager.isProUser ? Int.max : 10
}

var sharingLimit: Int {
    purchaseManager.isProUser ? Int.max : 5
}
```

---

## Debugging Tips

```swift
// Print pro status
print("Is Pro User: \(purchaseManager.isProUser)")

// Check products loaded
print("Products: \(purchaseManager.products.map { $0.displayName })")

// Print errors
if let error = purchaseManager.error {
    print("Error: \(error.localizedDescription)")
}

// Check transaction updates
print("Purchase in progress: \(purchaseManager.purchaseInProgress)")
```
