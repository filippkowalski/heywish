# Authentication System Documentation

This document provides a comprehensive overview of the authentication system in the Jinnie mobile app, including authentication flows, account merging, and data synchronization.

**Last Updated**: 2025-01-05

---

## Table of Contents

1. [Overview](#overview)
2. [Authentication Providers](#authentication-providers)
3. [Authentication Flows](#authentication-flows)
4. [Account Merging](#account-merging)
5. [Data Refresh After Merge](#data-refresh-after-merge)
6. [Technical Implementation](#technical-implementation)
7. [Error Handling](#error-handling)
8. [Testing](#testing)
9. [Troubleshooting](#troubleshooting)

---

## Overview

The Jinnie app uses Firebase Authentication as the primary authentication service, with a PostgreSQL backend for user data persistence. The system supports multiple authentication providers and includes sophisticated account merging capabilities to prevent data loss.

### Key Components

- **AuthService** (`lib/services/auth_service.dart`) - Core authentication logic
- **ApiService** (`lib/services/api_service.dart`) - Backend API communication
- **LocalDatabase** (`lib/services/local_database.dart`) - Offline SQLite storage
- **SyncManager** (`lib/services/sync_manager.dart`) - Offline/online data synchronization

### Authentication Architecture

```
┌─────────────────┐
│   Firebase Auth │ ← Primary authentication
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   AuthService   │ ← Business logic & state management
└────────┬────────┘
         │
         ├──────────────────────────┐
         ▼                          ▼
┌─────────────────┐        ┌─────────────────┐
│   API Service   │        │ Local Database  │
│  (PostgreSQL)   │        │    (SQLite)     │
└─────────────────┘        └─────────────────┘
```

---

## Authentication Providers

### 1. Anonymous Authentication

**Use Case**: Allow users to use the app without creating an account

**Implementation**:
```dart
final result = await authService.authenticateAnonymously();
```

**Characteristics**:
- Instant access without credentials
- No username required initially
- Can be upgraded to permanent account later
- Data can be merged when linking to a permanent account

### 2. Google Sign-In

**Use Case**: OAuth authentication via Google account

**Implementation**:
```dart
final result = await authService.authenticateWithGoogle();
```

**Configuration**:
- Requires SHA-1 fingerprint in Firebase Console for Android
- Requires OAuth client ID configuration
- See `CHANGELOG.md` for SHA-1 setup instructions

**Characteristics**:
- Fast, familiar authentication
- Auto-fills email and name
- Supports account linking

### 3. Apple Sign-In

**Use Case**: OAuth authentication via Apple ID (required for iOS)

**Implementation**:
```dart
final result = await authService.authenticateWithApple();
```

**Configuration**:
- Requires Apple Developer account setup
- Must configure Sign in with Apple capability
- Requires both `idToken` AND `accessToken` in OAuth credential

**Characteristics**:
- Privacy-focused (can hide email)
- Required for iOS App Store approval
- Supports account linking

### 4. Email/Password Authentication

**Use Case**: Traditional email-based authentication

**Implementation**:
```dart
// Sign Up
final result = await authService.signUpWithEmail(email, password);

// Sign In
final result = await authService.signInWithEmail(email, password);
```

**Characteristics**:
- Email verification recommended
- Password reset flow available
- Most control over user identity

---

## Authentication Flows

### Flow 1: New User Anonymous → Permanent Account

```
1. User opens app
2. App creates anonymous Firebase user automatically
3. User explores app, creates wishes/wishlists
4. User decides to create permanent account
5. User taps "Sign In" in onboarding/profile
6. User selects authentication method (Google/Apple/Email)
7. System checks if authenticated email already exists:

   Case A: Email NOT in system (new user)
   ├─→ Link anonymous account to new credentials
   ├─→ Preserve all anonymous data
   └─→ Complete onboarding (username, profile, etc.)

   Case B: Email EXISTS in system (returning user)
   ├─→ Show merge dialog: "Account already exists. Merge data?"
   ├─→ User accepts: Transfer anonymous data to existing account
   ├─→ User declines: Sign into existing account (anonymous data lost)
   └─→ Skip onboarding (user already has account)
```

### Flow 2: Returning User Direct Sign-In

```
1. User opens app
2. App creates anonymous Firebase user
3. User immediately taps "Sign In"
4. User authenticates with existing credentials
5. System checks for local anonymous data:

   Case A: No local data
   ├─→ Sign in directly
   ├─→ Load user's existing data
   └─→ Go to home screen

   Case B: Has local data (offline wishes/wishlists)
   ├─→ Show merge dialog
   ├─→ User accepts: Merge offline data to cloud
   ├─→ User declines: Discard offline data
   └─→ Go to home screen
```

### Flow 3: Account Linking (Anonymous → Permanent)

```
1. User has anonymous account with data
2. User selects authentication provider
3. Firebase attempts `linkWithCredential()`
4. Success: Anonymous account upgraded to permanent
5. All data automatically preserved
6. Continue to onboarding or home
```

---

## Account Merging

Account merging is a critical feature that prevents data loss when users have created content before signing in.

### When Merge is Triggered

Merge detection occurs in these scenarios:

1. **Anonymous user signs into existing account**
   - User created wishes/wishlists anonymously
   - Signs in with credentials that match existing account
   - System detects data in both anonymous and existing accounts

2. **Offline data when signing in**
   - User created data while offline
   - Signs in when back online
   - System detects unsynced local data

### Merge Detection Algorithm

The merge detection uses a **hybrid approach** to catch all data:

```dart
Future<(bool, String?, bool)> _checkMergeRequirement(String firebaseUid) async {
  try {
    // STEP 1: Check server while still authenticated as anonymous user
    try {
      final wishlistsResponse = await _apiService.get('/wishlists');
      final wishlists = (wishlistsResponse?['wishlists'] as List?) ?? [];

      final wishesResponse = await _apiService.get('/wishes');
      final wishes = (wishesResponse?['wishes'] as List?) ?? [];

      final hasServerData = wishlists.isNotEmpty || wishes.isNotEmpty;
      if (hasServerData) {
        return (true, firebaseUid, true); // Merge required
      }
    } catch (serverError) {
      // Server unreachable, fall through to local check
      debugPrint('⚠️ Server check failed: $serverError');
    }

    // STEP 2: Fallback to local SQLite (catches offline-created data)
    final localDb = LocalDatabase();

    // Check for user in local database
    final localUsers = await localDb.getEntities('users',
      where: 'firebase_uid = ?',
      whereArgs: [firebaseUid],
    );

    if (localUsers.isEmpty) {
      return (false, null, false); // No data to merge
    }

    // Check for wishlists
    final wishlists = await localDb.getEntities('wishlists',
      where: 'user_id = ?',
      whereArgs: [localUsers.first['id']],
    );

    // Check for wishes
    final wishes = await localDb.getEntities('wishes',
      where: 'created_by = ?',
      whereArgs: [localUsers.first['id']],
    );

    // Check for unsynced changes
    final unsyncedChanges = await localDb.getEntities('change_operations',
      where: 'sync_state != ?',
      whereArgs: [SyncState.synced.toString()],
    );

    final hasLocalData = wishlists.isNotEmpty ||
                        wishes.isNotEmpty ||
                        unsyncedChanges.isNotEmpty;

    return (hasLocalData, hasLocalData ? firebaseUid : null, hasLocalData);
  } catch (e) {
    debugPrint('❌ Error checking merge requirement: $e');
    return (false, null, false);
  }
}
```

**Why Hybrid Approach?**

- **Server-first**: Catches wishes created via API but not yet synced to local SQLite
  - Example: User adds wish → saves to server → before local sync completes, user signs in
  - Without server check, this data would be lost

- **Local fallback**: Catches offline-created data when network is unavailable
  - Example: User creates wish offline → signs in with poor connection
  - Without local check, offline data would be lost

### Merge Flow

```
1. User authenticates with provider (Google/Apple/Email)
2. Firebase throws "credential-already-in-use" exception
3. AuthService catches exception and checks for merge requirement
4. If merge required:
   ├─→ Show MergeAccountsBottomSheet
   ├─→ User sees: "You have X wishes and Y wishlists on this device"
   └─→ User chooses: "Merge" or "Sign in without merging"

5. If user chooses "Merge":
   ├─→ Call backend API: POST /api/auth/merge
   ├─→ Backend transfers wishlists: UPDATE wishlists SET user_id = $newUserId
   ├─→ Backend transfers wishes: UPDATE wishes SET created_by = $newUserId
   ├─→ Backend deletes anonymous user
   ├─→ Sign in to permanent account
   ├─→ Trigger data refresh (see next section)
   └─→ Navigate to home screen

6. If user chooses "Sign in without merging":
   ├─→ Sign in to permanent account
   ├─→ Anonymous data remains orphaned (will be cleaned up by backend)
   └─→ Navigate to home screen
```

### Backend Merge Endpoint

Location: `backend_openai_proxy/routes/jinnie.js`

```javascript
router.post('/auth/merge', requireAuth, async (req, res) => {
  const { anonymousUserId } = req.body;
  const authenticatedUser = req.user; // From JWT token

  // Transfer wishlists from anonymous to authenticated user
  const wishlistsResult = await client.query(
    'UPDATE wishlists SET user_id = $1 WHERE user_id = $2 RETURNING id',
    [authenticatedUser.id, anonymousUser.id]
  );

  // Transfer wishes created by anonymous user
  const wishesResult = await client.query(
    'UPDATE wishes SET created_by = $1 WHERE created_by = $2 RETURNING id',
    [authenticatedUser.id, anonymousUser.id]
  );

  // Delete anonymous user (CASCADE deletes related data)
  await client.query(
    'DELETE FROM users WHERE firebase_uid = $1',
    [anonymousUserId]
  );

  res.json({
    success: true,
    wishlistsMerged: wishlistsResult.rowCount,
    wishesMerged: wishesResult.rowCount,
  });
});
```

---

## Data Refresh After Merge

After a successful account merge, the app automatically refreshes all data to display merged content immediately without requiring manual refresh.

### Why This Matters

**Problem**: Before this feature, users would merge accounts but not see the merged wishes until they manually pulled to refresh or restarted the app.

**Solution**: Automatic data refresh triggered by merge completion.

### Implementation

#### 1. AuthService - Merge Timestamp

Location: `lib/services/auth_service.dart`

```dart
class AuthService extends ChangeNotifier {
  /// Timestamp of last successful account merge (used to trigger data refresh in UI)
  DateTime? _lastMergeTimestamp;
  DateTime? get lastMergeTimestamp => _lastMergeTimestamp;

  /// Refresh all app services after account merge to show merged data
  Future<void> _refreshAppDataAfterMerge() async {
    try {
      // Update merge timestamp - UI screens will watch this and refresh
      _lastMergeTimestamp = DateTime.now();
      notifyListeners(); // Triggers UI updates for screens watching AuthService

      debugPrint('🔄 Merge timestamp updated: $_lastMergeTimestamp');
    } catch (e) {
      debugPrint('⚠️ Error refreshing app data after merge: $e');
      // Don't throw - merge succeeded, this is just a UX improvement
    }
  }

  Future<void> performAccountMerge(String anonymousUserId) async {
    try {
      // ... merge logic ...

      debugPrint('✅ Account merge completed successfully');

      // Step 4: Refresh all app data to show merged content
      debugPrint('🔄 Refreshing app data after merge...');
      await _refreshAppDataAfterMerge();
      debugPrint('✅ App data refreshed successfully');
    } catch (e) {
      // ... error handling ...
    }
  }
}
```

#### 2. WishlistsScreen - Merge Detection

Location: `lib/screens/wishlists/wishlists_screen.dart`

```dart
class _WishlistsScreenState extends State<WishlistsScreen> {
  DateTime? _lastCheckedMergeTimestamp;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = context.watch<AuthService>();

    // Check if merge just completed - force reload regardless of _hasLoadedOnce
    if (authService.lastMergeTimestamp != null &&
        (_lastCheckedMergeTimestamp == null ||
            authService.lastMergeTimestamp!.isAfter(_lastCheckedMergeTimestamp!))) {
      debugPrint('🔄 WishlistsScreen: Merge detected, forcing data reload');
      _lastCheckedMergeTimestamp = authService.lastMergeTimestamp;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadWishlists(); // Force reload from server
      });
      return;
    }

    // ... rest of original logic ...
  }
}
```

### How It Works

```
┌─────────────────────────────────────────────────────────────┐
│ 1. User completes merge in authentication_step.dart        │
│    └─→ AuthService.performAccountMerge() called            │
└─────────────────────┬───────────────────────────────────────┘
                      ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Backend merge succeeds (wishes/wishlists transferred)   │
│    └─→ POST /api/auth/merge returns success                │
└─────────────────────┬───────────────────────────────────────┘
                      ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. AuthService._refreshAppDataAfterMerge() called          │
│    ├─→ _lastMergeTimestamp = DateTime.now()                │
│    └─→ notifyListeners() (triggers rebuild)                │
└─────────────────────┬───────────────────────────────────────┘
                      ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. WishlistsScreen.didChangeDependencies() triggered       │
│    ├─→ Detects authService.lastMergeTimestamp changed      │
│    └─→ Compares with _lastCheckedMergeTimestamp            │
└─────────────────────┬───────────────────────────────────────┘
                      ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. Force data reload                                        │
│    ├─→ _loadWishlists() called                             │
│    ├─→ Fetches merged data from server                     │
│    └─→ UI updates with merged wishes/wishlists             │
└─────────────────────────────────────────────────────────────┘
                      ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. User sees merged content immediately ✅                  │
└─────────────────────────────────────────────────────────────┘
```

### Key Design Decisions

1. **Timestamp-based detection**: Using `DateTime` instead of boolean flag allows for multiple merges in same session

2. **ChangeNotifier pattern**: Leverages Flutter's reactive pattern for clean separation of concerns

3. **Post-frame callback**: Ensures reload happens after widget is built, preventing setState during build

4. **Silent failure**: If refresh fails, merge still succeeded - this is a UX enhancement, not critical

5. **Per-screen opt-in**: Only screens that need refresh implement the pattern (WishlistsScreen needed, FeedScreen didn't)

### Extending to Other Screens

To add merge refresh to another screen:

```dart
class _YourScreenState extends State<YourScreen> {
  DateTime? _lastCheckedMergeTimestamp;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = context.watch<AuthService>();

    // Detect merge completion
    if (authService.lastMergeTimestamp != null &&
        (_lastCheckedMergeTimestamp == null ||
            authService.lastMergeTimestamp!.isAfter(_lastCheckedMergeTimestamp!))) {
      _lastCheckedMergeTimestamp = authService.lastMergeTimestamp;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadYourData(); // Your data loading method
      });
      return;
    }

    // ... rest of your logic ...
  }
}
```

---

## Technical Implementation

### NavigationAction Enum

Used to determine navigation after authentication:

```dart
enum NavigationAction {
  goHome,              // Existing user, skip onboarding
  continueOnboarding,  // New user, complete onboarding
  showMergeDialog,     // Merge required
}
```

### AuthResult Class

Returned by all authentication methods:

```dart
class AuthResult {
  final NavigationAction action;
  final OnboardingStep? resumeAt;        // For continueOnboarding
  final String? anonymousUserId;         // For showMergeDialog
  final firebase.User? user;
  final String? error;
}
```

### Key Methods

#### authenticateWithGoogle()

```dart
Future<AuthResult> authenticateWithGoogle() async {
  try {
    // Step 1: Google Sign In
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Step 2: Get OAuth credentials
    final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
    final credential = firebase.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Step 3: Try to link with anonymous account
    try {
      final userCredential = await _currentUser!.linkWithCredential(credential);
      // Success: Anonymous upgraded to permanent
      return AuthResult(action: NavigationAction.continueOnboarding);
    } on firebase.FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        // Account exists, check if merge needed
        final (requiresMerge, anonymousUid, hasData) =
            await _checkMergeRequirement(_currentUser!.uid);

        if (requiresMerge) {
          return AuthResult(
            action: NavigationAction.showMergeDialog,
            anonymousUserId: anonymousUid,
          );
        }

        // No merge needed, sign in directly
        await _firebaseAuth.signInWithCredential(credential);
        return AuthResult(action: NavigationAction.goHome);
      }
      throw e;
    }
  } catch (e) {
    return AuthResult(error: e.toString());
  }
}
```

#### authenticateWithApple()

**IMPORTANT**: Apple Sign-In requires BOTH `idToken` AND `accessToken`:

```dart
Future<AuthResult> authenticateWithApple() async {
  // ... get Apple credentials ...

  // Step 4: Create Firebase credential
  final oauthCredential = firebase.OAuthProvider('apple.com').credential(
    idToken: appleCredential.identityToken,
    rawNonce: rawNonce,
    accessToken: appleCredential.authorizationCode, // ← CRITICAL!
  );

  // ... rest of flow same as Google ...
}
```

**Bug History**: Missing `accessToken` caused "Invalid OAuth response from apple.com" error. This was fixed in commit `fix(mobile): Add missing accessToken for Apple Sign-In OAuth credential`.

---

## Error Handling

### Common Errors

#### 1. credential-already-in-use

**Cause**: User tries to link credential that's already associated with another account

**Handling**:
- Catch exception
- Check for merge requirement
- Show merge dialog if needed
- Otherwise sign in to existing account

#### 2. network-request-failed

**Cause**: No internet connection during authentication

**Handling**:
- Show user-friendly error message
- Allow retry
- Fall back to local data if available

#### 3. invalid-credential

**Cause**: Expired or malformed authentication token

**Handling**:
- Clear local auth state
- Force re-authentication
- Log error to Crashlytics

#### 4. user-cancelled

**Cause**: User cancelled Google/Apple sign-in flow

**Handling**:
- Silent handling (no error shown)
- Return to previous screen
- Log cancellation for analytics

### Error Messages

Location: `assets/translations/en.json`

```json
{
  "auth.error_google_signin": "Failed to sign in with Google. Please try again.",
  "auth.error_apple_signin": "Failed to sign in with Apple. Please try again.",
  "errors.network_error": "Network connection error. Please check your internet and try again.",
  "errors.something_went_wrong": "Something went wrong. Please try again."
}
```

---

## Testing

### Manual Test Cases

#### Test Case 1: Anonymous → Google Sign-In (New User)

```
1. Open app (anonymous user created automatically)
2. Add a wish titled "Test Wish 1"
3. Go to Profile tab
4. Tap "Sign In"
5. Select "Sign in with Google"
6. Choose Google account not in system
7. ✅ EXPECTED: Link succeeds, proceed to onboarding
8. Complete onboarding
9. ✅ EXPECTED: "Test Wish 1" visible on home screen
```

#### Test Case 2: Anonymous → Google Sign-In (Existing User with Merge)

```
1. Create anonymous user
2. Add wish titled "Anonymous Wish"
3. Go to Profile → Sign In
4. Sign in with Google account that already exists in system
5. ✅ EXPECTED: Merge dialog appears with count
6. Tap "Merge accounts"
7. ✅ EXPECTED: Navigate to home, "Anonymous Wish" appears immediately
8. ✅ EXPECTED: Existing wishes also visible
```

#### Test Case 3: Anonymous → Google Sign-In (Existing User without Merge)

```
1. Create anonymous user
2. DO NOT create any wishes
3. Go to Profile → Sign In
4. Sign in with existing Google account
5. ✅ EXPECTED: No merge dialog, direct to home
6. ✅ EXPECTED: Existing user's wishes displayed
```

#### Test Case 4: Offline Wish Creation → Sign-In

```
1. Open app
2. Turn on airplane mode
3. Add wish titled "Offline Wish"
4. Turn off airplane mode
5. Go to Profile → Sign In
6. Sign in with Google
7. ✅ EXPECTED: Merge dialog appears
8. Tap "Merge accounts"
9. ✅ EXPECTED: "Offline Wish" syncs and appears
```

#### Test Case 5: Apple Sign-In (iOS only)

```
1. Create anonymous user with wishes
2. Tap "Sign in with Apple"
3. Complete Apple authentication
4. ✅ EXPECTED: Merge dialog or onboarding (depending on account status)
5. ✅ EXPECTED: No "Invalid OAuth response" error
6. ✅ EXPECTED: Authentication succeeds
```

### Automated Test Cases

Location: `test/services/auth_service_test.dart`

```dart
group('Account Merging', () {
  test('should detect merge requirement with server data', () async {
    // Setup: Create anonymous user with wishes on server
    // Execute: Sign in with existing account
    // Assert: requiresMerge == true
  });

  test('should detect merge requirement with offline data', () async {
    // Setup: Create anonymous user with local-only wishes
    // Execute: Sign in with existing account (simulate offline)
    // Assert: requiresMerge == true (from local check)
  });

  test('should skip merge when no data exists', () async {
    // Setup: Create anonymous user with no wishes
    // Execute: Sign in with existing account
    // Assert: requiresMerge == false
  });

  test('should refresh data after merge', () async {
    // Setup: Create anonymous user with wishes
    // Execute: Perform merge
    // Assert: _lastMergeTimestamp updated
    // Assert: notifyListeners called
  });
});
```

---

## Troubleshooting

### Issue: Google Sign-In fails on Android release build

**Symptoms**: Works in debug, fails in release with "API error"

**Cause**: SHA-1 fingerprint not added to Firebase Console

**Solution**:
1. Get SHA-1 of release keystore:
   ```bash
   keytool -list -v -keystore jinnie-release-key.jks -alias jinnie-release
   ```
2. Add SHA-1 to Firebase Console: Project Settings > Your apps > Android app
3. Download new `google-services.json`
4. Replace `android/app/google-services.json`
5. Clean and rebuild:
   ```bash
   flutter clean
   flutter build appbundle
   ```

### Issue: Apple Sign-In fails with "Invalid OAuth response"

**Symptoms**: Apple authentication throws error immediately after credentials obtained

**Cause**: Missing `accessToken` in OAuth credential

**Solution**: Ensure credential includes both tokens:
```dart
final oauthCredential = firebase.OAuthProvider('apple.com').credential(
  idToken: appleCredential.identityToken,
  rawNonce: rawNonce,
  accessToken: appleCredential.authorizationCode, // ← This is required!
);
```

### Issue: Merge dialog doesn't appear

**Symptoms**: User has anonymous wishes, signs in, but no merge dialog shown

**Cause**: Merge detection failed (server unreachable and local data missing)

**Debug**:
1. Check logs for "Merge check: Querying server"
2. Verify API responds to `/wishlists` and `/wishes`
3. Check SQLite for anonymous user data
4. Verify `_checkMergeRequirement()` returns correct values

**Solution**:
- Ensure backend is reachable
- Verify local database is properly synced
- Check Firebase authentication state

### Issue: Merged data doesn't appear immediately

**Symptoms**: Merge succeeds but user has to manually refresh to see wishes

**Cause**: Data refresh after merge not working

**Debug**:
1. Check logs for "Refreshing app data after merge"
2. Verify `_lastMergeTimestamp` is updated
3. Check if `WishlistsScreen.didChangeDependencies()` is called
4. Verify `_loadWishlists()` is triggered

**Solution**:
- Ensure `notifyListeners()` is called in `_refreshAppDataAfterMerge()`
- Verify screen uses `context.watch<AuthService>()`
- Check timestamp comparison logic

### Issue: User stuck in onboarding after merge

**Symptoms**: After merge, user sent to onboarding instead of home

**Cause**: Backend didn't mark user as onboarding complete

**Solution**:
- Call `authService.markOnboardingCompleted()` after merge
- Update backend to set `onboarding_completed` flag
- Verify user record in database

---

## Best Practices

### For Developers

1. **Always check merge requirement** before signing in existing accounts
2. **Use hybrid merge detection** (server + local) for comprehensive coverage
3. **Handle offline scenarios** gracefully with local fallback
4. **Update UI reactively** using ChangeNotifier pattern for instant feedback
5. **Log authentication flows** extensively for debugging
6. **Test all providers** (Google, Apple, Email) on both platforms
7. **Never skip accessToken** for Apple Sign-In OAuth credentials

### For QA Testing

1. Test with **airplane mode** to verify offline handling
2. Test **merge flows** with various data combinations
3. Verify **automatic data refresh** after merge
4. Test **error recovery** when network fails mid-authentication
5. Test on **both iOS and Android** (platform-specific differences exist)
6. Test with **existing accounts** and **new accounts**
7. Verify **no data loss** in any scenario

### For Backend Development

1. **Keep merge atomic** (use database transactions)
2. **Log merge operations** for audit trail
3. **Clean up orphaned data** from declined merges
4. **Validate user IDs** before transferring data
5. **Return useful merge results** (counts of items merged)
6. **Handle edge cases** (user deleted between check and merge)

---

## Related Documentation

- **CHANGELOG.md**: Version history and Firebase configuration
- **CLAUDE.md**: Project guidelines and coding standards
- **lib/services/auth_service.dart**: Full authentication implementation
- **lib/screens/onboarding/**: Onboarding flow implementation
- **backend_openai_proxy/routes/jinnie.js**: Backend merge endpoint

---

## Questions or Issues?

If you encounter authentication issues not covered here:

1. Check the logs for detailed error messages
2. Search closed GitHub issues for similar problems
3. Review Firebase Console for authentication events
4. Verify backend API is accessible and responding
5. Contact the development team with reproduction steps

---

**Document Version**: 1.0
**Last Updated**: 2025-01-05
**Maintainer**: Development Team
