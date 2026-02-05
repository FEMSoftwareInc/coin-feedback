# StoreKit 2 Paywall Implementation Guide

This document describes the complete paywall implementation for the COIN Feedback app using StoreKit 2 for iOS 17+.

## Overview

The implementation includes:
- **PurchaseManager**: Manages all StoreKit 2 transactions
- **PaywallView**: Beautiful glassmorphism UI for monetization
- **Gating Logic**: Prevents non-Pro users from sharing and creating 11+ entries

## Components

### 1. PurchaseManager (Services/PurchaseManager.swift)

An `@MainActor` `ObservableObject` that handles all purchase operations.

#### Key Features:

- **Product Loading**: Fetches the three product IDs from App Store
  - `com.femsoftware.coinfeedback.pro.monthly` (auto-renew)
  - `com.femsoftware.coinfeedback.pro.yearly` (auto-renew)
  - `com.femsoftware.coinfeedback.pro.lifetime` (non-consumable)

- **Purchase Flow**:
  ```swift
  let success = await purchaseManager.purchase(selectedProduct)
  ```

- **Restore Purchases**:
  ```swift
  let success = await purchaseManager.restorePurchases()
  ```

- **Pro Status Checking**: Continuously monitors current entitlements
  ```swift
  @Published var isProUser: Bool = false
  ```

- **Transaction Listening**: Listens for background transaction updates
  - Automatically updates `isProUser` when transactions occur
  - Handles subscription revocation detection
  - Validates transaction signatures

#### Published Properties:

```swift
@Published var products: [Product] = []           // Fetched products
@Published var isProUser = false                  // Current entitlement state
@Published var isLoading = false                  // Loading indicator
@Published var error: Error?                      // Error messages
@Published var purchaseInProgress = false         // Purchase button state
```

#### Reliable Entitlement Checking:

The `checkProStatus()` function checks **current entitlements** instead of UserDefaults:

```swift
// Checks active transactions with:
// 1. Product ID validation
// 2. Subscription revocation detection
// 3. Transaction signature verification (via StoreKit)
// 4. Non-consumable purchase detection

for await result in Transaction.currentEntitlements {
    let transaction = try result.payloadValue
    if productIDs.contains(transaction.productID) {
        if let subscription = transaction.subscription {
            // Check subscription is not revoked
            if transaction.revocationDate == nil {
                isProUser = true
                break
            }
        } else {
            // Lifetime purchase - always valid
            isProUser = true
            break
        }
    }
}
```

---

### 2. PaywallView (Views/PaywallView.swift)

Modern glassmorphism-styled paywall with three pricing tiers.

#### Visual Design:

- **Header**: Star icon with gradient + title + subtitle
- **Benefits List**: 4 key benefits with icons
  - Unlimited Entries
  - Email Sharing
  - Share Tracking
  - iCloud Sync

- **Pricing Options**: Interactive selection with:
  - Monthly plan
  - Yearly plan (with "Save X%" badge)
  - Lifetime plan
  - Visual feedback on selection

- **Purchase Button**: Gradient background with loading state
- **Restore Button**: Secondary action for existing customers
- **Maybe Later**: Dismiss button
- **Legal Text**: Auto-renew disclaimer

#### Glassmorphism Components:

```swift
// Benefits and pricing cards use:
.fill(Color.white.opacity(0.15))      // Semi-transparent white
.backdrop(blur: 20)                    // Blur effect
.stroke(Color.white.opacity(0.25))     // Light border
```

#### Usage:

```swift
@ObservedObject var purchaseManager: PurchaseManager

PaywallView(purchaseManager: purchaseManager)
```

---

### 3. Gating Logic

#### Share Gating (EntryDetailView)

When user taps "Share via Email":

```swift
Button(action: {
    // Check if user is pro before allowing share
    if !purchaseManager.isProUser {
        showPaywall = true
    } else if hasExistingRecipient {
        // Continue with share flow
        recipientName = entry.recipientName ?? ""
        recipientEmail = entry.recipientEmail ?? ""
        recordShareEventIfPossible()
        checkAndShowEmailComposer()
    } else {
        // Ask for recipient info
        showRecipientPrompt = true
    }
}) {
    Label("Share via Email", systemImage: "envelope")
}
```

**Result**: Non-Pro users see the PaywallView modally

#### 10-Entry Limit Gating (HistoryView)

When user taps the "+" button or "Create Entry":

```swift
Button(action: { 
    // Check if user is pro or under limit
    if !purchaseManager.isProUser && entries.count >= 10 {
        showPaywall = true
    } else {
        showCreateSheet = true
    }
})
```

**Result**: 
- Non-Pro users can create up to 10 entries
- On attempting 11th: PaywallView shown modally
- Pro users: unlimited entries

---

### 4. App Integration (coinApp.swift)

```swift
@main
struct coinApp: App {
    @StateObject private var purchaseManager = PurchaseManager()
    
    // ... ModelContainer setup ...
    
    var body: some Scene {
        WindowGroup {
            HistoryView(purchaseManager: purchaseManager)
                .environmentObject(purchaseManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
```

#### Data Flow:

1. **App Launch**: PurchaseManager initializes
   - Sets up transaction listener
   - Loads products
   - Checks pro status

2. **HistoryView**: Receives purchaseManager as parameter
   - Used for 10-entry limit check
   - Passed to EntryDetailView

3. **EntryDetailView**: Receives purchaseManager as parameter
   - Used for share gating

4. **PaywallView**: References purchaseManager
   - Can purchase, restore, and update pro status

---

## Product Configuration

### In App Store Connect:

Set up these product IDs:

1. **Monthly Subscription** (Optional)
   - ID: `com.femsoftware.coinfeedback.pro.monthly`
   - Type: Auto-Renewable Subscription
   - Price: $9.99/month
   - Billing Cycle: Monthly

2. **Yearly Subscription** (Optional)
   - ID: `com.femsoftware.coinfeedback.pro.yearly`
   - Type: Auto-Renewable Subscription
   - Price: $79.99/year
   - Billing Cycle: Yearly

3. **Lifetime** (Required)
   - ID: `com.femsoftware.coinfeedback.pro.lifetime`
   - Type: Non-Consumable
   - Price: $199.99 (one-time)

---

## Testing

### Sandbox Testing:

1. Use a Sandbox Apple ID (created in App Store Connect)
2. Sign in to App Store settings on simulator/device
3. Purchase will be free in sandbox
4. Subscription auto-renews every 5 minutes

### Testing Pro Status:

```swift
// In simulator/sandbox:
// 1. Tap purchase button
// 2. Confirm purchase
// 3. isProUser should update to true
// 4. Share button becomes enabled
// 5. Can create unlimited entries
```

### Testing Gating:

```swift
// 10-Entry Limit:
// 1. Create 10 entries
// 2. Try to create 11th → Paywall shown
// 3. Restore purchase or close
// 4. Can now create unlimited

// Share Gating:
// 1. Try to share as non-Pro → Paywall shown
// 2. Purchase/close
// 3. Can now share
```

---

## Key Implementation Details

### Transaction Signature Verification

StoreKit 2 automatically verifies transaction signatures when accessing `Transaction.currentEntitlements`. No additional verification needed.

### Subscription Revocation Handling

The implementation checks `transaction.revocationDate == nil` to ensure revoked subscriptions don't grant access.

### No UserDefaults

Entitlement state is **never** stored in UserDefaults. It's checked fresh from StoreKit 2's current entitlements, ensuring accuracy.

### Thread Safety

All StoreKit operations run on `@MainActor` to ensure UI thread safety.

### Error Handling

Each operation includes error handling:
```swift
do {
    // StoreKit operation
} catch {
    self.error = error
    print("Failed: \(error)")
}
```

---

## Files Modified/Created

### Created:
- `coin/coin/Services/PurchaseManager.swift` - Main purchase manager

### Updated:
- `coin/coin/Views/PaywallView.swift` - Complete redesign with glassmorphism
- `coin/coin/Views/EntryDetailView.swift` - Added share gating + purchaseManager
- `coin/coin/Views/HistoryView.swift` - Added 10-entry limit gating + purchaseManager
- `coin/coin/coinApp.swift` - Replaced PaywallViewModel with PurchaseManager

### Deleted:
- `coin/coin/ViewModels/PaywallViewModel.swift` (replaced by PurchaseManager)

---

## Future Enhancements

1. **Analytics**: Track paywall impressions, conversions, and purchase sources
2. **Promo Codes**: Support promotional codes in App Store
3. **Pricing Variants**: Different pricing by region
4. **Trial Period**: Offer free trial for subscriptions
5. **Family Sharing**: Support iOS Family Sharing
6. **A/B Testing**: Test different paywall designs/messaging

---

## References

- [StoreKit 2 Documentation](https://developer.apple.com/storekit/)
- [In-App Purchases Best Practices](https://developer.apple.com/documentation/storekit)
- [Transaction Verification](https://developer.apple.com/documentation/storekit/transaction/appaccounttoken)
