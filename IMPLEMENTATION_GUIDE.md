# COIN Feedback App - Implementation Guide

## 1. Project Structure

```
coin/
├── Models/
│   ├── FeedbackEntry.swift       # SwiftData @Model for feedback entries
│   └── ShareEvent.swift          # SwiftData @Model for share tracking
│
├── Views/
│   ├── HomeView.swift            # List of feedback entries
│   ├── CreateEditView.swift      # Create/edit COIN entry form
│   ├── DetailView.swift          # Entry details with share button
│   ├── PaywallView.swift         # Premium features paywall
│   └── EmailComposerView.swift   # Email sharing interface
│
├── ViewModels/
│   ├── FeedbackEntryViewModel.swift  # State management for entries
│   └── PaywallViewModel.swift       # StoreKit 2 purchase logic
│
├── Services/
│   ├── CloudKitService.swift     # iCloud sync via CloudKit
│   └── EmailService.swift        # Email composition & sending
│
├── Utilities/                     # Placeholder for helpers
├── coinApp.swift                  # App entry point with SwiftData setup
└── coin.entitlements              # iCloud + CloudKit capabilities
```

## 2. Data Models

### FeedbackEntry
- **id** (UUID): Unique identifier
- **createdAt** (Date): Entry creation timestamp
- **updatedAt** (Date): Last modification timestamp
- **context** (String): Circumstances or issue to discuss
- **observation** (String): Specific, factual descriptions
- **impact** (String): How the issue affects the team/org
- **nextSteps** (String): Expected behavior changes going forward
- **recipientName** (String?): Who it was shared to
- **recipientEmail** (String?): Recipient's email
- **sharedAt** (Date?): Timestamp of last share
- **shareCount** (Int): Total shares of this entry
- **cloudKitIdentifier** (String?): CloudKit record name for sync
- **isCloudKitSynced** (Bool): Sync status flag

### ShareEvent
- **id** (UUID): Unique identifier
- **entryId** (UUID): Reference to FeedbackEntry
- **sharedAt** (Date): When it was shared
- **recipientEmail** (String): Who received it
- **recipientName** (String?): Optional recipient name

## 3. Navigation & Screens

### HomeView
- **Purpose**: Displays list of all feedback entries, sorted by creation date (newest first)
- **Features**:
  - List with context preview and last modified date
  - Share icon indicator for already-shared entries
  - Empty state with guidance
  - Floating "+" button to create new entry
  - Swipe-to-delete capability

### CreateEditView
- **Purpose**: Form for creating or editing COIN entries
- **Fields**: Context, Observation, Impact, Next Steps (all TextEditor)
- **Features**:
  - Auto-population for edits
  - Context field is required (Save button disabled if empty)
  - Saves to SwiftData on completion

### DetailView
- **Purpose**: View full entry with share/edit/delete options
- **Features**:
  - Display all COIN sections with formatted styling
  - Share history section (if shared):
    - Share count
    - Recipient email
    - Last share timestamp
  - Menu options:
    - Edit (opens CreateEditView)
    - Share via Email (shows MFMailComposeViewController)
    - Delete (with confirmation)

### PaywallView
- **Purpose**: Premium feature gating
- **Features**:
  - Feature highlights (Cloud Sync, Unlimited Sharing, Analytics)
  - Display available StoreKit 2 products with pricing
  - Purchase flow with transaction handling
  - "Maybe Later" option to dismiss
- **Connected Products**: `com.coin.premium.monthly`, `com.coin.premium.yearly`

## 4. CloudKit + iCloud Sync Configuration

### Entitlements Configuration

The `coin.entitlements` file includes:

```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.coin.feedback</string>
</array>
<key>com.apple.developer.ubiquity-container-identifiers</key>
<array>
    <string>iCloud.com.coin.feedback</string>
</array>
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.coin.feedback</string>
</array>
```

### Xcode Project Settings

1. **Signing & Capabilities**:
   - Select target `coin`
   - Go to "Signing & Capabilities"
   - Click "+ Capability"
   - Add: **iCloud** (select CloudKit)
   - Add: **Push Notifications**
   - Add: **Background Modes** (Remote notifications)

2. **CloudKit Container**:
   - Set to: `iCloud.com.coin.feedback`

3. **Bundle ID**:
   - Ensure bundle ID is set to a unique identifier (e.g., `com.coin.feedback`)

### SwiftData Configuration

In `coinApp.swift`, the ModelContainer is configured with automatic CloudKit sync:

```swift
let cloudKitConfiguration = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: false,
    cloudKitDatabase: .automatic
)
```

This enables:
- Automatic sync to private iCloud container
- Conflict resolution
- Offline-first operation with eventual consistency

### CloudKitService

The `CloudKitService` handles:
- **Availability checking**: Verifies iCloud account status
- **Manual sync**: `syncEntry()` uploads individual entries
- **Fetching**: `fetchEntriesFromCloud()` retrieves from cloud
- **Deletion**: Removes entries from CloudKit

Note: With SwiftData's automatic CloudKit integration, manual syncing is optional but available for advanced scenarios.

## 5. Email Sharing

### EmailService

Provides email composition with pre-formatted COIN entry content:

```swift
EmailService.shared.sendFeedbackEmail(
    entry: feedbackEntry,
    recipient: "recipient@example.com",
    from: UIViewController,
    completion: { success, error in
        if success {
            entry.markAsShared(to: recipientEmail)
        }
    }
)
```

### MFMailComposeViewController Integration

- Launched from DetailView's menu
- Pre-populated with formatted entry content
- Recipient and subject auto-filled
- Tracking: After send, entry is marked with:
  - `sharedAt` timestamp
  - `shareCount` incremented
  - `recipientEmail` stored

### Email Body Format

```
COIN Feedback Entry
═══════════════════════════════════════════════════

CONTEXT
───────
[Entry context]

OBSERVATION
───────
[Entry observation]

IMPACT
───────
[Entry impact]

NEXT STEPS
───────
[Entry next steps]

═══════════════════════════════════════════════════
Generated: [Date]
App: COIN Feedback
```

## 6. StoreKit 2 Monetization

### Product IDs

- `com.coin.premium.monthly`: Recurring monthly subscription
- `com.coin.premium.yearly`: Recurring yearly subscription

### PaywallViewModel

Handles:
- Product fetching from App Store Connect
- Purchase transactions
- Entitlement verification
- Premium status tracking

### Gating Logic

Current implementation shows paywall but does not enforce feature access. To gate features:

```swift
@EnvironmentObject var paywallVM: PaywallViewModel

if paywallVM.isPremium {
    // Show unlimited features
} else {
    showPaywall()
}
```

## 7. Setup Steps

### Step 1: Configure Apple Developer Account

1. Go to [developer.apple.com](https://developer.apple.com)
2. Create App ID: `com.coin.feedback` (or adjust bundle ID in Xcode)
3. Enable capabilities:
   - iCloud (CloudKit)
   - Push Notifications
4. Create provisioning profiles

### Step 2: Configure Xcode Project

1. Open `coin.xcodeproj`
2. Select target `coin`
3. Go to "Signing & Capabilities"
4. Set Team ID (your Apple Developer account)
5. Add capabilities:
   - **iCloud**: Select "CloudKit", container: `iCloud.com.coin.feedback`
   - **Push Notifications** (for future remote notification sync)
6. Verify bundle ID matches: `com.coin.feedback`

### Step 3: App Store Connect Setup

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Create new app: `COIN Feedback`
3. Bundle ID: `com.coin.feedback`
4. Add In-App Purchases:
   - Product ID: `com.coin.premium.monthly`
   - Product ID: `com.coin.premium.yearly`
5. Configure pricing tiers and subscription details

### Step 4: CloudKit Dashboard

1. Go to CloudKit Dashboard: [icloud.developer.apple.com](https://icloud.developer.apple.com)
2. Select your container: `iCloud.com.coin.feedback`
3. Verify schema is created (will auto-create from SwiftData models)
4. Configure indexes if needed for filtering/sorting

### Step 5: Build & Run

```bash
# Build the app
xcodebuild build -scheme coin -configuration Debug

# Or use Xcode (Cmd+R)
```

Xcode will sync the schema to CloudKit automatically on first launch.

## 8. Testing Checklist

- [ ] Create a feedback entry (test all COIN fields)
- [ ] Edit an entry
- [ ] View entry details
- [ ] Delete an entry
- [ ] Share via email (verify MFMailComposeViewController launches)
- [ ] Verify share tracking (sharedAt, shareCount, recipientEmail)
- [ ] Check iCloud sync (observe in CloudKit Dashboard)
- [ ] Test premium paywall flow (purchase disabled in sandbox without test card)
- [ ] Verify data persists after app restart
- [ ] Test on multiple devices with same iCloud account (sync verification)

## 9. Key Dependencies

- **SwiftUI**: UI framework (iOS 17+)
- **SwiftData**: Data persistence with automatic CloudKit sync
- **CloudKit**: iCloud sync backend
- **StoreKit 2**: In-app purchase framework
- **MessageUI**: Email composition (`MFMailComposeViewController`)

## 10. Future Enhancements

- Analytics view showing feedback patterns
- Premium: Export to PDF/Word
- Premium: Team collaboration
- Notifications for sync status
- Offline indicator
- Search/filter entries
- Templates for common feedback scenarios
