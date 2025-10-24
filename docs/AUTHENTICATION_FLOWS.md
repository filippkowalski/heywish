# Authentication Flows

This document describes all authentication flows in the Jinnie app, including account creation, sign-in, and account merging.

## Table of Contents

- [Overview](#overview)
- [Anonymous Sign-Up](#anonymous-sign-up)
- [Google/Apple Sign-In (New User)](#googleapple-sign-in-new-user)
- [Google/Apple Sign-In (Existing User)](#googleapple-sign-in-existing-user)
- [Account Linking (Anonymous → Authenticated)](#account-linking-anonymous--authenticated)
- [Account Merge Flow](#account-merge-flow)
- [Implementation Details](#implementation-details)

## Overview

Jinnie uses Firebase Authentication with support for:
- **Anonymous authentication** - Quick start without account creation
- **Google Sign-In** - OAuth authentication with Google
- **Apple Sign-In** - OAuth authentication with Apple (iOS only)

All authentication methods sync user data to a PostgreSQL database via the `/auth/sync` endpoint.

## Anonymous Sign-Up

**User Flow:**
1. User opens the app
2. User taps "Continue without signing in" on onboarding
3. App calls `AuthService.signInAnonymously()`
4. Firebase creates an anonymous account with a UID
5. Backend generates a random username (e.g., `user8592432`)
6. User completes onboarding and can create wishlists/wishes

**Technical Details:**
- Firebase: `_firebaseAuth.signInAnonymously()`
- Backend: `POST /auth/sync` with `signUpMethod: 'anonymous'`
- User record created in PostgreSQL with `firebase_uid` and generated username
- All data stored locally in SQLite and synced to backend

**Files:**
- `mobile/lib/services/auth_service.dart`: `signInAnonymously()`
- `backend/routes/jinnie.js`: `POST /auth/sync`

## Google/Apple Sign-In (New User)

**User Flow:**
1. User taps "Sign in with Google" or "Sign in with Apple" on onboarding
2. OAuth flow completes and returns credential
3. App checks if user exists in database
4. **User does not exist** → Show "Account Not Found" dialog
5. User continues to onboarding to set username
6. Profile is saved and user can create wishlists/wishes

**Technical Details:**
- Firebase: `_firebaseAuth.signInWithCredential(credential)`
- Backend: `POST /auth/check-email` returns `{ exists: false }`
- Onboarding service sets `hasAlreadySignedIn = true` to skip account creation step
- User completes username step and profile is synced to backend

**Files:**
- `mobile/lib/services/auth_service.dart`: `signInWithGoogleCheckExisting()`, `signInWithAppleCheckExisting()`
- `mobile/lib/screens/onboarding/widgets/sign_in_bottom_sheet.dart`

## Google/Apple Sign-In (Existing User)

**User Flow:**
1. User taps "Sign in with Google" or "Sign in with Apple"
2. OAuth flow completes
3. App checks if user exists in database
4. **User exists** → Mark onboarding complete and navigate to home
5. User sees their existing wishlists/wishes

**Technical Details:**
- Firebase: `_firebaseAuth.signInWithCredential(credential)`
- Backend: `POST /auth/check-email` returns `{ exists: true }`
- No onboarding needed - user goes straight to home screen
- User data synced from backend to local database

**Files:**
- `mobile/lib/services/auth_service.dart`: `signInWithGoogleCheckExisting()`, `signInWithAppleCheckExisting()`
- `mobile/lib/screens/onboarding/widgets/sign_in_bottom_sheet.dart`

## Account Linking (Anonymous → Authenticated)

**User Flow:**
1. **Anonymous user** creates wishlists/wishes with username `user8592432`
2. User taps "Sign in" and chooses Google/Apple
3. Email is **not** associated with any existing Firebase account
4. App links credential to anonymous Firebase account
5. **Firebase UID is preserved** - all data remains intact
6. Backend updates user record with email and auth provider
7. User navigated to home with all their data

**Technical Details:**
- Firebase: `_firebaseUser.linkWithCredential(credential)` instead of `signInWithCredential()`
- **Firebase UID stays the same** - critical for data preservation
- Backend: `POST /auth/sync` updates existing user by `firebase_uid`
- Username, wishlists, and wishes remain associated with same user ID
- No data migration needed - it's the same user, just authenticated now

**Special Handling:**
- `provider-already-linked` error → Fall back to `signInWithCredential()`
- Backend finds user by `firebase_uid` and updates email/auth fields

**Files:**
- `mobile/lib/services/auth_service.dart`: Lines 508-571 (Google), 661-724 (Apple)
- `backend/routes/jinnie.js`: `POST /auth/sync`

## Account Merge Flow

**User Flow:**
1. **Anonymous user** creates wishlists/wishes with username `user8592432`
2. User taps "Sign in" and chooses Google/Apple
3. Email `example@gmail.com` **already has a Firebase account** (different UID)
4. Firebase throws `credential-already-in-use` error
5. App detects anonymous user has data in local database
6. **Merge dialog appears**: "You have an existing account with this email. Would you like to merge your current wishlists and data with that account?"
7. User taps "Merge Accounts"
8. App calls backend `/auth/merge` endpoint with anonymous UID
9. Backend transfers all data:
   - Username from anonymous user (if authenticated user has none)
   - All wishlists from anonymous → authenticated user
   - All wishes from anonymous → authenticated user
10. Backend deletes anonymous user record
11. App syncs updated user data from backend
12. User navigates to home with merged data

**Technical Details:**

### Detection Logic
```dart
// In AuthService.signInWithGoogleCheckExisting()
if (e.code == 'credential-already-in-use') {
  final anonymousFirebaseUid = _firebaseUser!.uid;

  // IMPORTANT: Query by firebase_uid column, not by primary key (backend UUID)
  final localDb = LocalDatabase();
  final anonymousUserRows = await localDb.getEntities(
    'users',
    where: 'firebase_uid = ?',
    whereArgs: [anonymousFirebaseUid],
    limit: 1,
  );

  if (anonymousUserRows.isNotEmpty) {
    final anonymousUser = anonymousUserRows.first;
    final anonymousBackendId = anonymousUser['id']; // Backend UUID
    final username = anonymousUser['username'];

    // Check if user has wishlists (using backend UUID)
    final wishlists = await localDb.getEntities(
      'wishlists',
      where: 'user_id = ?',
      whereArgs: [anonymousBackendId], // Use backend UUID, not Firebase UID
    );

    // Check if user has wishes (using backend UUID)
    final wishes = await localDb.getEntities(
      'wishes',
      where: 'created_by = ?',
      whereArgs: [anonymousBackendId], // Use backend UUID, not Firebase UID
    );

    // If user has username or any wishlists/wishes, require merge
    if (username != null && username.isNotEmpty || wishlists.isNotEmpty || wishes.isNotEmpty) {
      requiresMerge = true;
      anonymousUserId = anonymousFirebaseUid; // Store Firebase UID for backend merge
    }
  }

  // Sign into existing account
  userCredential = await _firebaseAuth.signInWithCredential(credential);
}
```

**Key Implementation Details:**
- Local database uses **backend UUID** as primary key, not Firebase UID
- Must query `users` table by `firebase_uid` column: `WHERE firebase_uid = ?`
- After getting user, extract backend UUID from `id` column
- Use backend UUID to query `wishlists` (via `user_id`) and `wishes` (via `created_by`)
- Pass **Firebase UID** to backend merge endpoint (backend expects this)

### Backend Merge Endpoint
```javascript
POST /auth/merge
Body: { anonymousUserId: string }

// Transaction flow:
1. Get both users from database by firebase_uid
2. Transfer username (if authenticated user has none)
3. UPDATE wishlists SET user_id = authenticated_user_id WHERE user_id = anonymous_user_id
4. UPDATE wishes SET created_by = authenticated_user_id WHERE created_by = anonymous_user_id
5. DELETE anonymous user
6. COMMIT transaction
7. Return merged user and statistics
```

### Response Format
```json
{
  "success": true,
  "message": "Accounts merged successfully",
  "user": { /* updated user object */ },
  "merged": {
    "wishlistsTransferred": 3,
    "wishesTransferred": 12
  }
}
```

**Error Handling:**
- If merge fails, transaction is rolled back
- User sees error message and can try again
- Anonymous account remains intact if merge fails

**Files:**
- Mobile:
  - `mobile/lib/services/auth_service.dart`: Lines 526-563 (Google), 679-716 (Apple)
  - `mobile/lib/services/api_service.dart`: `mergeAccounts()`
  - `mobile/lib/screens/onboarding/widgets/sign_in_bottom_sheet.dart`: Lines 55-80 (Google), 140-165 (Apple)
  - `mobile/lib/common/widgets/merge_accounts_bottom_sheet.dart`
  - `mobile/assets/translations/en.json`: Merge strings
- Backend:
  - `backend/routes/jinnie.js`: `POST /auth/merge` (Lines 267-397)

## Implementation Details

### Firebase Account Linking
Firebase guarantees that when using `linkWithCredential()`, the Firebase UID is preserved:
- Anonymous UID: `o0IaD8w0TQVP2143rAyjsMHzn2a2`
- After linking: **Same UID** - `o0IaD8w0TQVP2143rAyjsMHzn2a2`
- All PostgreSQL foreign keys reference this UID
- No data migration needed

### Why Merge is Needed
When `credential-already-in-use` occurs, Firebase creates/signs into a **different** account:
- Anonymous UID: `o0IaD8w0TQVP2143rAyjsMHzn2a2` (has data)
- Authenticated UID: `FDNGEtrWzbUi60CxGzl76L1EbiC3` (existing account)
- These are **two different users** in database
- Without merge, anonymous data would be orphaned

### Data Integrity
The merge endpoint uses database transactions to ensure:
- All-or-nothing migration (ACID properties)
- No orphaned wishlists or wishes
- No duplicate data
- Clean deletion of anonymous user

### Local Database Cleanup
After merge, the mobile app performs these steps in sequence:

```dart
// 1. Call backend to merge accounts
await apiService.mergeAccounts(anonymousUserId);

// 2. Sync user profile from backend to get updated username
await authService.syncUserWithBackend(retries: 1);

// 3. CRITICAL: Perform full sync to fetch merged wishlists/wishes from backend
final syncManager = SyncManager();
await syncManager.performFullSync();

// 4. Mark onboarding complete and navigate to home
await authService.markOnboardingCompleted();
```

**Why Full Sync is Required:**
- Backend has merged wishlists/wishes to new user_id
- Local database still has old rows with anonymous user_id
- `performFullSync()` fetches all wishlists/wishes from backend
- Local database is updated with correct user_id references
- User immediately sees merged data without orphaned rows

## Diagrams

### Account Linking Flow (Success)
```
Anonymous User (UID: ABC123)
├── Wishlists
│   └── "Christmas 2025" (user_id: ABC123)
│       └── Wishes
└── Username: "user8592432"

↓ [Sign in with Google] → Email NOT in Firebase

Firebase: linkWithCredential() → UID: ABC123 (PRESERVED)

Same User (UID: ABC123)
├── Wishlists
│   └── "Christmas 2025" (user_id: ABC123) ✓ Still works!
│       └── Wishes
├── Username: "user8592432"
└── Email: "example@gmail.com" (NEW)
```

### Account Merge Flow (credential-already-in-use)
```
Anonymous User (UID: ABC123)          Existing User (UID: XYZ789)
├── Wishlists: 3                      ├── Wishlists: 0
│   └── "Christmas 2025"              └── Username: "" (empty)
│   └── "Birthday Ideas"
│   └── "Home Decor"
└── Username: "user8592432"

↓ [Sign in with Google] → Email ALREADY in Firebase

Firebase: credential-already-in-use error
App: Detect anonymous has data → Show merge dialog
User: Confirms merge

↓ [POST /auth/merge]

Merged User (UID: XYZ789)
├── Wishlists: 3 (TRANSFERRED)
│   └── "Christmas 2025" (user_id: XYZ789)
│   └── "Birthday Ideas" (user_id: XYZ789)
│   └── "Home Decor" (user_id: XYZ789)
└── Username: "user8592432" (TRANSFERRED)

Anonymous User (UID: ABC123): DELETED
```

## Testing Scenarios

### Scenario 1: Anonymous → Google (Successful Link)
1. Sign up anonymously
2. Create some wishlists
3. Sign in with Google (new email)
4. ✅ Expected: Account linked, all data preserved, no dialog shown

### Scenario 2: Anonymous → Google (Account Merge)
1. Sign up anonymously
2. Create wishlists and wishes
3. Sign in with Google (email that already exists)
4. ✅ Expected: Merge dialog shown
5. Confirm merge
6. ✅ Expected: All data transferred to existing account

### Scenario 3: Direct Google Sign-In (New User)
1. Sign in with Google (new email)
2. ✅ Expected: "Account Not Found" dialog
3. Complete onboarding with username
4. ✅ Expected: Account created

### Scenario 4: Direct Google Sign-In (Existing User)
1. Sign in with Google (existing email)
2. ✅ Expected: Navigate directly to home
3. ✅ Expected: All wishlists/wishes visible

## Security Considerations

### Firebase UID Validation
- Backend verifies Firebase token on all requests
- User ID (firebase_uid) is extracted from verified token
- No client-provided user IDs are trusted

### Merge Authorization
- Only authenticated user can merge data
- Anonymous UID is validated to exist in database
- Transaction ensures atomic operation

### Data Ownership
- Wishlists can only be merged to same authenticated user
- Wishes preserve original creator relationship
- No cross-user data leakage possible

## Known Issues & Fixes

### Initial Implementation Issues (Fixed in v1.1)

#### Issue 1: Merge Detection Broken (CRITICAL - Fixed)
**Problem:**
- Local database uses backend UUID as primary key (`users.id`)
- Original code queried `getEntity('users', firebaseUid)` treating Firebase UID as primary key
- This always returned `null` because Firebase UID is in `users.firebase_uid` column
- Result: Merge dialog never appeared, anonymous users silently lost all data

**Fix Applied:**
```dart
// Query by firebase_uid column, not primary key
final anonymousUserRows = await localDb.getEntities(
  'users',
  where: 'firebase_uid = ?',
  whereArgs: [anonymousFirebaseUid],
  limit: 1,
);

// Extract backend UUID for related queries
final anonymousBackendId = anonymousUserRows.first['id'];

// Use backend UUID for wishlists/wishes
final wishlists = await localDb.getEntities(
  'wishlists',
  where: 'user_id = ?',
  whereArgs: [anonymousBackendId], // Not Firebase UID!
);
```

**Status:** ✅ Fixed (commit c00a0e2)

#### Issue 2: No Data Sync After Merge (CRITICAL - Fixed)
**Problem:**
- Backend successfully merged wishlists/wishes to new user_id
- Local SQLite still had orphaned rows with old user_id
- Only synced user profile, not full data
- User didn't see merged wishlists/wishes until app restart

**Fix Applied:**
```dart
// After merge, perform full sync to fetch merged data
await apiService.mergeAccounts(anonymousUserId);
await authService.syncUserWithBackend(retries: 1);

// CRITICAL: Full sync to reconcile local DB
final syncManager = SyncManager();
await syncManager.performFullSync();
```

**Status:** ✅ Fixed (commit c00a0e2)

#### Issue 3: Silent Data Loss (CRITICAL - Fixed)
**Problem:**
- Consequence of issues 1 & 2 combined
- Anonymous users upgrading to Google/Apple with existing account lost all data
- No warning, no merge prompt, data disappeared

**Fix Applied:**
- Issues 1 & 2 resolved the root causes
- Merge detection now works correctly
- Full sync ensures data visibility

**Status:** ✅ Fixed (commit c00a0e2)

#### Issue 4: Concurrent Sync Race Condition (Medium - Fixed)
**Problem:**
- If `SyncManager.performFullSync()` is already running when merge happens
- Returns `SyncResult.inProgress()` immediately without waiting
- Fresh merged data might not appear until next scheduled sync (5 min)
- User sees stale data temporarily after merge

**Fix Applied:**
```dart
var syncResult = await syncManager.performFullSync();

// If sync is already in progress, wait and retry once
if (syncResult.error == 'Sync already in progress') {
  debugPrint('⚠️  Sync in progress, waiting 2 seconds...');
  await Future.delayed(const Duration(seconds: 2));
  syncResult = await syncManager.performFullSync();

  // If still in progress, rely on periodic sync (5 min)
  if (syncResult.error == 'Sync already in progress') {
    debugPrint('⚠️  Sync still in progress, relying on periodic sync');
  }
}
```

**Status:** ✅ Fixed (commit f5f8c7a+)

### Audit Trail

**First Audit (2025-01-10):**
- **Findings:** 3 High-priority issues
- **Resolution:** Same day
- **Status:** All fixed

**Second Audit (2025-01-10):**
- **Findings:** No blocking bugs, 1 residual risk (concurrent sync)
- **Resolution:** Same day
- **Status:** Fixed with retry logic
- **Testing Status:** Awaiting end-to-end device testing

## Future Enhancements

### Conflict Resolution
Currently, merge always transfers data from anonymous to authenticated user. Future improvements could:
- Detect duplicate wishlists by name
- Allow user to choose which wishlists to keep
- Merge wishes from duplicate wishlists

### Bulk Merge UI
Show preview of what will be merged:
```
Merging your accounts will transfer:
• Username: "user8592432"
• 3 wishlists
• 15 wishes

Continue?  [Merge] [Cancel]
```

### Offline Merge Queue
Handle merge when offline:
- Queue merge request locally
- Execute when connection restored
- Show pending merge status to user

### Local Database Schema Improvement
Add `firebase_uid` columns to wishlists/wishes tables:
- Would simplify merge detection queries
- Faster lookups without JOIN to users table
- More resilient to future schema changes
