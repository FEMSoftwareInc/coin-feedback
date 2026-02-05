# Visual Architecture: StoreKit 2 Paywall

## User Journey

```
┌─────────────────────────────────────────────────────────────────┐
│                        App Launches                              │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
          ┌──────────────────────────────┐
          │   PurchaseManager Init       │
          │  - Load products             │
          │  - Check pro status          │
          │  - Start transaction listen  │
          └──────────┬───────────────────┘
                     │
        ┌────────────┴────────────┐
        ▼                         ▼
   ┌─────────┐           ┌─────────────┐
   │ Products│           │ isProUser   │
   │ Loaded  │           │ Determined  │
   └────┬────┘           └──────┬──────┘
        │                       │
        └───────────┬───────────┘
                    ▼
         ┌──────────────────────┐
         │   HistoryView        │
         │  Shows 10 entries    │
         │  (or list if less)   │
         └──────────┬───────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
        ▼                       ▼
   User taps       User taps COIN
   FAB(+)              entry
        │                       │
        │                       ├─── if < 10 entries or isProUser
        │                       │    ▼
        │                       │  EntryDetailView
        │                       │    │
        │                       │    ├─── if isProUser
        │                       │    │    │
        │                       │    │    └─► Share enabled ✓
        │                       │    │
        │                       │    └─── if !isProUser
        │                       │         │
        │                       │         └─► Share shows PaywallView
        │                       │
        │                       └─── if >= 10 entries and !isProUser
        │                            │
        │                            └─► PaywallView shown
        │
        └─ if >= 10 entries and !isProUser
             │
             └─► PaywallView shown
                   │
                   ├─ Purchase monthly
                   ├─ Purchase yearly (save badge)
                   ├─ Purchase lifetime
                   ├─ Restore purchases
                   └─ Maybe Later (dismiss)
                        │
                        ▼ (if purchased)
                   isProUser = true
                        │
                        ▼
                   All features unlocked ✓
```

## Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    App Store                                │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │ Products:        │  │ Transactions:    │                │
│  │ - Monthly        │  │ - Purchase logs  │                │
│  │ - Yearly         │  │ - Subscriptions  │                │
│  │ - Lifetime       │  │ - Revocations    │                │
│  └──────────────────┘  └──────────────────┘                │
└──────────────┬────────────────────────┬─────────────────────┘
               │                        │
               ▼                        ▼
    ┌──────────────────────┐  ┌────────────────────────┐
    │  StoreKit 2          │  │  Transaction.current   │
    │  .products()         │  │  Entitlements          │
    └──────────┬───────────┘  └────────────┬───────────┘
               │                            │
               ▼                            ▼
    ┌──────────────────────┐    ┌────────────────────────┐
    │ PurchaseManager      │    │ PurchaseManager        │
    │ .products            │    │ .checkProStatus()      │
    │ [Product]            │    │ → isProUser: Bool      │
    └──────────┬───────────┘    └────────────┬───────────┘
               │                             │
               └──────────────┬──────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ @Published       │
                    │ - products       │
                    │ - isProUser      │
                    │ - isLoading      │
                    │ - error          │
                    └────────┬─────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
          PaywallView   HistoryView   EntryDetailView
           observes      observes       observes
           isProUser      isProUser      isProUser
```

## State Management

```
PurchaseManager (Singleton)
├─ @StateObject in coinApp
│
├─ @Published var products: [Product]
│  └─ Updated when loadProducts() completes
│
├─ @Published var isProUser: Bool
│  ├─ Updated by checkProStatus()
│  ├─ Updated when transactions occur
│  ├─ Updated on app launch
│  └─ Updated after purchase/restore
│
├─ @Published var purchaseInProgress: Bool
│  └─ Used for loading indicators during purchase
│
├─ @Published var error: Error?
│  └─ Shows error messages to user
│
└─ Private Task: updateTask
   └─ Listens to Transaction.updates
      └─ Calls checkProStatus() when transactions occur
```

## Component Hierarchy

```
coinApp
│
├─ @StateObject purchaseManager
│  │
│  └─ setupTransactionListener()
│     └─ Task.background listening to Transaction.updates
│
└─ WindowGroup
   │
   └─ HistoryView(purchaseManager)
      │
      ├─ observes purchaseManager.isProUser
      ├─ checks entry count
      │
      ├─ [FAB Button]
      │  └─ onTap:
      │     ├─ if !isProUser && entries.count >= 10
      │     │  └─ show PaywallView
      │     └─ else
      │        └─ show CoinEditorView
      │
      ├─ [Entry List]
      │  └─ ForEach entries
      │     └─ NavigationLink → EntryDetailView
      │
      └─ PaywallView(purchaseManager)
         │
         ├─ observes purchaseManager.products
         ├─ observes purchaseManager.isProUser
         ├─ observes purchaseManager.purchaseInProgress
         │
         ├─ displays pricing options
         ├─ handles purchases
         └─ handles restore
```

## Transaction Flow

```
User taps Purchase
    │
    ▼
Button → purchaseProduct(product)
    │
    ▼
purchaseManager.purchase(product)
    │
    ▼
product.purchase() [StoreKit 2]
    │
    ├─ .success(verification)
    │  │
    │  ├─ Try verification.payloadValue
    │  ├─ transaction.finish() [Mark as finished]
    │  ├─ checkProStatus() [Update pro state]
    │  ├─ isProUser = true ✓
    │  └─ return true
    │
    ├─ .pending
    │  └─ return false [Wait for completion]
    │
    └─ .userCancelled
       └─ return false [User tapped Cancel]

(Meanwhile, Transaction.updates listener also fires)
    │
    ▼
setupTransactionListener()
    │
    ├─ Detects transaction
    ├─ transaction.finish()
    ├─ checkProStatus()
    └─ isProUser = true ✓
```

## Gating Decision Trees

### Share Email Gating

```
User taps "Share via Email"
    │
    ▼
┌─ Is isProUser true?
│  │
│  ├─ YES → Continue normal share flow
│  │         ├─ Check existing recipient
│  │         ├─ Or prompt for recipient
│  │         └─ Send email
│  │
│  └─ NO → Show PaywallView
│          ├─ User sees pricing
│          ├─ If purchase → isProUser = true
│          │   └─ Share sheet dismisses
│          ├─ If restore → isProUser = true
│          │   └─ Share sheet dismisses
│          └─ If cancel → Share remains blocked
```

### Create Entry Gating

```
User taps FAB (+) or Create Entry
    │
    ▼
┌─ Is isProUser true?
│  │
│  └─ YES → Show CoinEditorView
│          └─ Create unlimited entries
│
└─ NO → Check entry count
   │
   ├─ Count < 10 → Show CoinEditorView
   │              └─ Can create entry
   │
   └─ Count >= 10 → Show PaywallView
                    ├─ User sees pricing
                    ├─ If purchase → isProUser = true
                    │   └─ Can now create
                    ├─ If restore → isProUser = true
                    │   └─ Can now create
                    └─ If cancel → Can't create
```

## Error Handling

```
StoreKit Operation
    │
    ├─ Success
    │  ├─ Update UI
    │  └─ Dismiss modal
    │
    ├─ Network Error
    │  ├─ Show alert
    │  └─ Allow retry
    │
    ├─ User Cancelled
    │  └─ Silent dismiss
    │
    └─ Transaction Error
       ├─ Save error
       ├─ Show user message
       └─ Keep paywall open
```

## Concurrency Model

```
@MainActor
PurchaseManager
├─ All @Published updates on main thread
├─ All UI operations on main thread
│
└─ Async operations:
   ├─ loadProducts() async
   ├─ purchase() async
   ├─ restorePurchases() async
   └─ checkProStatus() async
      └─ Naturally awaits on current entitlements
```

## File Organization

```
COIN App Project
│
├─ coin/coin/
│  │
│  ├─ coinApp.swift [MODIFIED]
│  │  └─ Initializes PurchaseManager
│  │
│  ├─ Services/
│  │  ├─ CloudKitService.swift
│  │  ├─ EmailService.swift
│  │  ├─ PurchaseManager.swift [NEW] ✓
│  │  └─ TextSummarizer.swift
│  │
│  ├─ Views/
│  │  ├─ CoinEditorView.swift
│  │  ├─ EntryDetailView.swift [MODIFIED] ✓
│  │  ├─ HistoryView.swift [MODIFIED] ✓
│  │  ├─ HomeView.swift
│  │  ├─ PaywallView.swift [REDESIGNED] ✓
│  │  └─ ...
│  │
│  ├─ ViewModels/
│  │  └─ (PaywallViewModel removed - replaced by PurchaseManager)
│  │
│  └─ Models/
│     ├─ FeedbackEntry.swift
│     └─ ShareEvent.swift
│
└─ Documentation/
   ├─ PAYWALL_SUMMARY.md [NEW] ✓
   ├─ PAYWALL_IMPLEMENTATION.md [NEW] ✓
   ├─ PAYWALL_QUICK_REFERENCE.md [NEW] ✓
   ├─ PAYWALL_CODE_EXAMPLES.md [NEW] ✓
   └─ README.md
```

## Product ID Mapping

```
Product ID                                    Type              Price
┌─────────────────────────────────────────┬──────────────────┬───────┐
│ com.femsoftware.coinfeedback.pro.monthly│ Auto-Renewable   │$9.99  │
│                                          │ (Monthly)        │/month │
├─────────────────────────────────────────┼──────────────────┼───────┤
│ com.femsoftware.coinfeedback.pro.yearly │ Auto-Renewable   │$79.99 │
│                                          │ (Yearly)         │/year  │
│                                          │                  │(save  │
│                                          │                  │ 33%)  │
├─────────────────────────────────────────┼──────────────────┼───────┤
│ com.femsoftware.coinfeedback.pro.lifetime│ Non-Consumable   │$199.99│
│                                          │ (One-time)       │       │
└─────────────────────────────────────────┴──────────────────┴───────┘
```

## Deployment Checklist

```
Before Submission to App Store
├─ [ ] Products configured in App Store Connect
├─ [ ] Bundle ID matches
├─ [ ] In-App Purchases capability enabled
├─ [ ] Sandbox testing complete
├─ [ ] Purchase flow works
├─ [ ] Restore purchases works
├─ [ ] Pro status persists
├─ [ ] No compilation errors
├─ [ ] All gating rules tested
└─ [ ] Documentation complete

After App Store Approval
├─ [ ] Monitor paywall impressions
├─ [ ] Track conversion rates
├─ [ ] Monitor revenue
├─ [ ] Track user feedback
├─ [ ] Monitor churn/retention
└─ [ ] Plan enhancements
```
