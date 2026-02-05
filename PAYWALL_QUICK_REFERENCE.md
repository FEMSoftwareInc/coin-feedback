# Quick Start: StoreKit 2 Paywall

## What Was Implemented

✅ **PurchaseManager** - StoreKit 2 transaction handler  
✅ **PaywallView** - Glassmorphism UI with 3 pricing tiers  
✅ **Share Gating** - Pro-only email sharing  
✅ **10-Entry Limit** - Free tier creates 10 entries max  

---

## Product IDs (Configure in App Store Connect)

```
com.femsoftware.coinfeedback.pro.monthly    → $9.99/month (auto-renew)
com.femsoftware.coinfeedback.pro.yearly     → $79.99/year (auto-renew)
com.femsoftware.coinfeedback.pro.lifetime   → $199.99 one-time
```

---

## How It Works

### 1. User Flow

```
App Start
  ↓
PurchaseManager loads products
  ↓
PurchaseManager checks isProUser
  ↓
User attempts to:
  • Share entry? → Check isProUser → Show Paywall if false
  • Create 11th entry? → Check count + isProUser → Show Paywall if needed
  • Tap purchase → Process with StoreKit 2 → Update isProUser
```

### 2. Code Access

```swift
// In any view:
@ObservedObject var purchaseManager: PurchaseManager

// Check if user is Pro:
if purchaseManager.isProUser {
    // Show premium feature
}

// Handle purchase:
let success = await purchaseManager.purchase(product)

// Restore purchases:
let success = await purchaseManager.restorePurchases()
```

---

## Testing in Simulator

1. Create Sandbox tester in App Store Connect
2. Sign in on simulator with Sandbox credentials
3. App will load products from Sandbox environment
4. Purchases are FREE in Sandbox
5. Subscriptions auto-renew every 5 minutes (test only)

---

## Current Gating Rules

### Free (Non-Pro)
- ✓ Create up to 10 entries
- ✗ Share entries (blocked)
- ✗ Create 11th entry (blocked)

### Pro (Subscribed or Lifetime)
- ✓ Unlimited entries
- ✓ Unlimited sharing
- ✓ All features

---

## Key Files

| File | Purpose |
|------|---------|
| `Services/PurchaseManager.swift` | Handles all purchases & entitlements |
| `Views/PaywallView.swift` | Glassmorphic paywall UI |
| `Views/EntryDetailView.swift` | Share gating logic |
| `Views/HistoryView.swift` | 10-entry limit gating |
| `coinApp.swift` | App initialization |

---

## Important: Entitlement Checking

**Never** use UserDefaults to track pro status. Always check:

```swift
// ✅ CORRECT - Fresh from StoreKit 2
for await result in Transaction.currentEntitlements {
    let transaction = try result.payloadValue
    if productIDs.contains(transaction.productID) {
        isProUser = true
    }
}

// ❌ WRONG - Stale data
let isPro = UserDefaults.standard.bool(forKey: "isPro")
```

The implementation always queries **current entitlements**, ensuring accuracy.

---

## Features Included

### PurchaseManager
- ✅ Load products from App Store
- ✅ Handle purchases with error handling
- ✅ Restore purchases (handles subscription recovery)
- ✅ Listen for background transaction updates
- ✅ Track pro status reliably
- ✅ Validate entitlements (not revoked)
- ✅ Handle subscription revocation

### PaywallView
- ✅ Glassmorphism design (matches app theme)
- ✅ Benefit list with 4 features
- ✅ Monthly/Yearly/Lifetime options
- ✅ Dynamic "Save X%" badge for yearly
- ✅ Purchase progress indicator
- ✅ Restore purchases button
- ✅ Maybe Later dismiss option
- ✅ Legal text about subscriptions

### Gating
- ✅ Share button shows Paywall if non-Pro
- ✅ 10-entry limit prevents 11th creation
- ✅ Smooth modal presentation
- ✅ Graceful handling of edge cases

---

## Next Steps

1. **Configure Products**: Set up 3 products in App Store Connect
2. **Test**: Use Sandbox credentials on simulator
3. **Deploy**: Archive and submit to App Store
4. **Monitor**: Track conversions in App Analytics

---

## Troubleshooting

### Products not loading?
- Check product IDs match App Store Connect exactly
- Ensure app has In-App Purchase capability
- Check Bundle ID in Xcode

### Purchases not working?
- Use Sandbox tester credentials
- Check device date/time is correct
- Clear app cache: Xcode → Product → Clean Build Folder

### Pro status not updating?
- App uses current entitlements (not cached)
- Close and reopen app
- Force kill app and relaunch

---

## Architecture

```
coinApp
  ├─ @StateObject purchaseManager: PurchaseManager
  │   ├─ @Published products: [Product]
  │   ├─ @Published isProUser: Bool
  │   ├─ loadProducts()
  │   ├─ purchase(product)
  │   ├─ restorePurchases()
  │   └─ checkProStatus()
  │
  ├─ HistoryView
  │   ├─ observes purchaseManager.isProUser
  │   ├─ 10-entry limit check
  │   └─ presents PaywallView if needed
  │
  └─ EntryDetailView
      ├─ observes purchaseManager.isProUser
      ├─ share gating
      └─ presents PaywallView if needed
```

---

## Pro Tips

1. **Check pro status before expensive operations**
   ```swift
   if purchaseManager.isProUser {
       // Allow sharing, unlimited entries, etc.
   }
   ```

2. **Always handle purchase errors**
   ```swift
   if await purchaseManager.purchase(product) {
       // Success - dismiss paywall
   } else {
       // Failed - show error message
   }
   ```

3. **Give users easy restore option**
   - Restore button always visible on paywall
   - Helps users recover after reinstalling app

4. **Test in sandbox first**
   - All in-app purchases are free in sandbox
   - Perfect for testing before App Store submission

---

## Questions?

Refer to PAYWALL_IMPLEMENTATION.md for detailed documentation.
