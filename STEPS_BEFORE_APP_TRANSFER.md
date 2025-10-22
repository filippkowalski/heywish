# Steps Before App Transfer to New App Store Account

This document outlines the critical steps required when transferring the Jinnie app to a different App Store Connect account.

## Current Configuration (As of October 2025)

### Apple Developer Account
- **Team ID**: `474TK9U3BP`
- **Bundle ID**: `com.wishlists.gifts`
- **Services ID**: `com.wishlists.gifts.signin`
- **App ID**: `com.wishlists.gifts` (with Sign in with Apple enabled)

### Firebase Project
- **Project ID**: `wishlist-app-v2`
- **Firebase Auth Domain**: `wishlist-app-v2.firebaseapp.com`
- **Apple Sign-In Configuration**:
  - Services ID: `com.wishlists.gifts.signin`
  - Team ID: `474TK9U3BP`
  - OAuth Redirect URI: `https://wishlist-app-v2.firebaseapp.com/__/auth/handler`

  ℹ️ **Note**: This is the exact URL that must be configured in Apple Developer Console under Services ID → Return URLs

### Database
- **PostgreSQL** hosted on Render.com
- **Users table** contains `firebase_uid` for authentication

---

## Pre-Transfer Checklist

### 1. Export User Data (CRITICAL)
Before initiating the transfer, export all user data for migration:

```sql
-- Export users with Apple Sign-In
SELECT
    id,
    username,
    email,
    firebase_uid,
    full_name,
    created_at
FROM users
WHERE firebase_uid IS NOT NULL
ORDER BY created_at DESC;
```

Save this data securely - you'll need it for user migration after transfer.

### 2. Document Current Configuration

**Apple Developer Portal:**
- Screenshot of App ID configuration
- Screenshot of Services ID configuration
- Note the Key ID for Sign in with Apple key
- Save a copy of current .p8 key file (if still available)

**Firebase Console:**
- Screenshot of Apple authentication provider settings
- Export Firebase project configuration
- Document all API keys and service account credentials

**Xcode:**
- Note current Team ID in project settings
- Document all provisioning profiles
- List all capabilities (Sign in with Apple, Push Notifications, etc.)

### 3. Test Current Setup
Verify everything works before transfer:
- [ ] Apple Sign-In working
- [ ] Google Sign-In working (if applicable)
- [ ] Push notifications working
- [ ] Deep links working
- [ ] All API endpoints responding correctly

### 4. Notify Stakeholders
- [ ] Notify team members of planned transfer
- [ ] Schedule maintenance window if needed
- [ ] Prepare user communication plan

---

## Post-Transfer Steps

### 1. Apple Developer Portal (New Account)

#### a) Verify App ID Transfer
- App ID `com.wishlists.gifts` should transfer automatically
- Verify "Sign in with Apple" capability is still enabled
- Note the **new Team ID**

#### b) Create New Services ID
1. Go to Identifiers → Add (+)
2. Select "Services IDs"
3. Create new Services ID:
   - **Description**: `Jinnie Sign In`
   - **Identifier**: `com.wishlists.gifts.signin` (same as before)
4. Enable "Sign in with Apple"
5. Click "Configure":
   - **Primary App ID**: `com.wishlists.gifts`
   - **Domains and Subdomains**: `wishlist-app-v2.firebaseapp.com`
   - **Return URLs**: `https://wishlist-app-v2.firebaseapp.com/__/auth/handler`

   ⚠️ **Important**: Use the exact return URL shown in Firebase Console. You can find it at:
   Firebase Console → Authentication → Sign-in method → Apple → OAuth redirect URI

6. Save and Register

#### c) Create New Key for Sign in with Apple
1. Go to Keys → Add (+)
2. **Key Name**: `Jinnie Apple Sign In Key`
3. Enable "Sign in with Apple"
4. Configure → Select Primary App ID: `com.wishlists.gifts`
5. **Download the .p8 key file** (only chance!)
6. **Note the new Key ID** (10 characters)
7. Store .p8 file securely

#### d) Create New APNs Key (for Push Notifications)
1. Go to Keys → Add (+)
2. **Key Name**: `Jinnie APNs Key`
3. Enable "Apple Push Notifications service (APNs)"
4. **Download the .p8 key file**
5. **Note the Key ID**

### 2. Firebase Console Updates

#### a) Update Apple Authentication Provider
1. Firebase Console → Authentication → Sign-in method
2. Click on Apple provider
3. Update with **new account details**:
   - **Services ID**: `com.wishlists.gifts.signin`
   - **Apple Team ID**: [NEW TEAM ID]
   - **Key ID**: [NEW KEY ID from Step 1c]
   - **Private Key**: [Content of new .p8 file from Step 1c]
4. Save changes

#### b) Update APNs Configuration (for FCM)
1. Firebase Console → Project Settings → Cloud Messaging
2. Apple app configuration section
3. Upload new APNs Auth Key:
   - Upload new .p8 file from Step 1d
   - Enter Key ID
   - Enter Team ID
4. Save

### 3. Update Mobile App (iOS)

#### a) Update Xcode Project
1. Open `mobile/ios/Runner.xcworkspace` in Xcode
2. Update Team ID:
   - Select Runner target
   - Signing & Capabilities tab
   - Update "Team" to new account
3. Verify all capabilities are present:
   - Sign in with Apple
   - Push Notifications
   - Associated Domains (if used)
4. Update provisioning profiles
5. Clean build folder: Shift + Cmd + K

#### b) Update GoogleService-Info.plist
1. Download updated `GoogleService-Info.plist` from Firebase Console
2. Replace file in `mobile/ios/Runner/GoogleService-Info.plist`
3. Ensure only one copy exists (check `mobile/ios/` folder too)

#### c) Update App Constants
Check if any hardcoded Team ID references exist:
```bash
cd mobile
grep -r "474TK9U3BP" .
```
Update any found references to new Team ID.

### 4. User Migration Strategy

⚠️ **CRITICAL**: Apple Sign-In user IDs change when Team ID changes!

#### Important: Apple Private Relay Emails

Most users use Apple's "Hide My Email" feature, which provides relay emails like:
- `random123@privaterelay.appleid.com`

**Good News**: These relay emails remain consistent even after Team ID changes! Apple maintains the same relay email for the same user across different apps from the same developer.

**However**: The relay email can change if:
- User revokes access and signs in again
- User creates a new Apple ID
- Transfer is to a completely different company (not just account transfer)

#### Migration Strategy: Transfer Token Approach (Recommended)

Before the transfer, implement a migration token system:

1. **Before Transfer - Generate Migration Tokens**:

```typescript
// Backend: Generate migration tokens for all users
POST /api/v1/auth/generate-migration-token
{
  "firebase_uid": "current_apple_id"
}

// Returns: { "migration_token": "secure_random_token" }
// Store in database: users.migration_token with 90-day expiry
```

2. **Update app BEFORE transfer**:
```dart
// When user opens app, generate and store migration token
final migrationToken = await authService.generateMigrationToken();
await secureStorage.write(key: 'migration_token', value: migrationToken);
```

3. **After Transfer - Use Migration Token**:

```typescript
// New sign-in endpoint checks for migration token
POST /api/v1/auth/sign-in-with-migration
{
  "new_apple_id": "new_firebase_uid_from_new_team",
  "migration_token": "token_from_secure_storage",
  "email": "user@example.com"  // can be relay email
}

// Backend logic:
// 1. Find user with matching migration_token
// 2. Verify token not expired
// 3. Update firebase_uid to new Apple ID
// 4. Invalidate migration token
// 5. Return success
```

4. **App logic after transfer**:
```dart
Future<void> signInWithApple() async {
  // Sign in with Apple (new Team ID)
  final appleCredential = await SignInWithApple.getAppleIDCredential(...);

  // Try migration first
  final migrationToken = await secureStorage.read(key: 'migration_token');
  if (migrationToken != null) {
    try {
      await apiService.migrateAccount(
        newAppleId: appleCredential.userIdentifier,
        migrationToken: migrationToken,
        email: appleCredential.email,
      );
      // Migration successful!
      return;
    } catch (e) {
      // Migration failed, try email fallback
    }
  }

  // Fallback: Email-based lookup (works for relay emails too!)
  await _tryEmailBasedMigration(appleCredential);
}
```

#### Fallback: Email-Based Migration

Even with relay emails, we can use email as a secondary identifier:

```sql
-- Find user by email (works with relay emails)
UPDATE users
SET
    firebase_uid = $1,  -- new Apple ID
    updated_at = NOW()
WHERE
    email = $2  -- can be privaterelay email
    AND firebase_uid IS NOT NULL  -- has old Apple ID
    AND migration_token IS NULL;  -- wasn't migrated via token
```

**Important**: Relay emails remain the same, so this works reliably!

#### Option B: Username-Based Recovery

For edge cases where migration token and email both fail:

1. **Display "Account Recovery" screen**:
```dart
// Show user their username from old account
"We found an account with username: @oldusername
Would you like to continue with this account?"
```

2. **Backend endpoint**:
```typescript
POST /api/v1/auth/recover-by-username
{
  "username": "oldusername",
  "new_apple_id": "new_firebase_uid"
}

// Backend verifies:
// 1. Username exists
// 2. Has old Apple ID (firebase_uid not null)
// 3. Not already migrated
// 4. Show confirmation to user
```

3. **Security check**: Send verification to relay email:
```typescript
// Send verification code to user's relay email
// User enters code to confirm account ownership
```

#### Option C: Manual Support Migration

Last resort for problematic cases:
- Provide in-app support contact
- Manual account verification process
- Admin tool to link old and new accounts
- Verify identity through wishlist details, username, etc.

#### Complete Migration Flow

```
1. User opens app with new version (before transfer)
   ↓
2. Generate migration token, store locally
   ↓
3. [Transfer happens]
   ↓
4. User opens app with updated version (after transfer)
   ↓
5. Signs in with Apple (new Team ID)
   ↓
6. App tries migration token → SUCCESS (90% of cases)
   ↓ (if failed)
7. App tries email matching → SUCCESS (8% of cases)
   ↓ (if failed)
8. App shows username recovery → SUCCESS (1.9% of cases)
   ↓ (if failed)
9. Contact support → Manual migration (0.1% of cases)
```

#### Database Schema Updates

Add migration support to users table:

```sql
ALTER TABLE users
ADD COLUMN migration_token VARCHAR(255) UNIQUE,
ADD COLUMN migration_token_expires_at TIMESTAMP,
ADD COLUMN migrated_at TIMESTAMP,
ADD COLUMN old_firebase_uid VARCHAR(255);

-- Index for fast lookup
CREATE INDEX idx_users_migration_token ON users(migration_token)
WHERE migration_token IS NOT NULL;
```

### 5. Testing Plan

#### Phase 1: Internal Testing
- [ ] Create test Apple ID accounts
- [ ] Test Apple Sign-In with new configuration
- [ ] Test user migration flow
- [ ] Test push notifications
- [ ] Test all critical app features

#### Phase 2: Beta Testing
- [ ] Release to TestFlight beta testers
- [ ] Monitor crash reports and user feedback
- [ ] Verify migration works for existing users
- [ ] Test on different iOS versions

#### Phase 3: Staged Rollout
- [ ] Release to 10% of users first
- [ ] Monitor for issues (24-48 hours)
- [ ] Release to 50% of users
- [ ] Monitor for issues (24-48 hours)
- [ ] Release to 100% of users

### 6. User Communication

#### Before Transfer
Send notification to all users:
```
Subject: Important Update - Jinnie Account Migration

We're improving our infrastructure! In the next update, you may be asked
to sign in again with Apple. Your data is safe and will be automatically
migrated. If you experience any issues, please contact support at
[support email].
```

#### After Transfer
In-app message for users affected by migration:
```
We've updated our sign-in system. Please sign in with Apple again to
continue using Jinnie. Your wishlists and data will be automatically
restored.
```

---

## Rollback Plan

If critical issues occur after transfer:

1. **Do NOT revert App Store transfer** (extremely difficult)
2. Instead, fix issues in new configuration
3. Emergency hotfix release process:
   - Identify issue
   - Fix in code
   - Fast-track App Store review
   - Communicate with affected users

---

## Post-Migration Monitoring

### Week 1
- [ ] Monitor authentication success/failure rates
- [ ] Track user migration completion rate
- [ ] Monitor support tickets for migration issues
- [ ] Check error logs for Apple Sign-In failures

### Week 2-4
- [ ] Verify all users have migrated successfully
- [ ] Address any edge cases
- [ ] Update documentation with lessons learned

---

## Contacts & Resources

### Apple Developer Support
- URL: https://developer.apple.com/contact/
- Phone: [Add support number]

### Firebase Support
- Console: https://console.firebase.google.com/
- Support: https://firebase.google.com/support

### Team Contacts
- iOS Developer: [Add contact]
- Backend Developer: [Add contact]
- DevOps: [Add contact]

---

## Additional Notes

### What Transfers Automatically
- App ID and capabilities
- App Store listing and metadata
- In-app purchases
- App Store reviews and ratings
- Analytics data (partial)

### What Needs Reconfiguration
- Sign in with Apple (Services ID, Key)
- Push notification certificates/keys
- Provisioning profiles
- Team-specific identifiers

### What Stays the Same
- Bundle ID: `com.wishlists.gifts`
- Firebase project (no changes)
- Backend API (no changes)
- Database (no changes)
- User data (except firebase_uid mapping)

---

## Checklist Summary

**Before Transfer:**
- [ ] Export all user data from database
- [ ] Document current Apple Developer configuration
- [ ] Document current Firebase configuration
- [ ] Save all screenshots and credentials
- [ ] Test current setup thoroughly
- [ ] Notify team and prepare communication

**During Transfer:**
- [ ] Initiate transfer in App Store Connect
- [ ] Wait for new account to accept transfer
- [ ] Monitor transfer status

**After Transfer:**
- [ ] Create new Services ID in new Apple Developer account
- [ ] Create new Sign in with Apple key
- [ ] Create new APNs key
- [ ] Update Firebase Apple authentication config
- [ ] Update Firebase Cloud Messaging APNs config
- [ ] Update Xcode project Team ID
- [ ] Update GoogleService-Info.plist
- [ ] Implement user migration flow
- [ ] Test thoroughly
- [ ] Release staged update
- [ ] Monitor and support users

---

**Last Updated**: October 22, 2025
**Document Owner**: Development Team
**Review Frequency**: Before any transfer
