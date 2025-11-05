import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'api_service.dart';
import 'local_database.dart';
import 'fcm_service.dart';
import 'onboarding_service.dart';
import 'sync_manager.dart';
import 'analytics_service.dart';
import '../models/user.dart';
import '../models/sync_entity.dart';
import '../utils/crashlytics_logger.dart';

/// Navigation action to take after authentication
enum NavigationAction {
  continueOnboarding,  // New user → go through full onboarding flow
  goHome,              // Existing user → skip onboarding, go to /home
  showMergeDialog,     // Credential conflict → show merge confirmation UI
}

/// Result of authentication operation
class AuthenticationResult {
  /// Primary user state flags
  final bool isExistingUser;      // User exists in backend DB with username
  final bool isNewUser;            // User just created, needs onboarding
  final bool isAnonymousUpgrade;   // Was anonymous, now authenticated

  /// Merge scenario flags
  final bool requiresMerge;        // Anonymous data needs merging
  final String? anonymousUserId;   // Firebase UID of anonymous account to merge

  /// Navigation hints
  final NavigationAction action;   // Action to take (continue onboarding, go home, or show merge dialog)
  final OnboardingStep? resumeAt;  // Where to resume onboarding if new user

  /// Backend sync state
  final bool userSynced;           // User data synced to backend
  final String? username;          // Current username (if exists)

  AuthenticationResult({
    required this.action,
    this.isExistingUser = false,
    this.isNewUser = false,
    this.isAnonymousUpgrade = false,
    this.requiresMerge = false,
    this.anonymousUserId,
    this.resumeAt,
    this.userSynced = false,
    this.username,
  });
}

class AuthService extends ChangeNotifier {
  final firebase.FirebaseAuth _firebaseAuth = firebase.FirebaseAuth.instance;
  final ApiService _apiService = ApiService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final AnalyticsService _analyticsService = AnalyticsService();

  User? _currentUser;
  firebase.User? _firebaseUser;
  StreamSubscription<firebase.User?>? _authStateSubscription;
  bool _isOnboardingCompleted = false;
  Timer? _tokenRefreshTimer;
  String? _lastAuthMethod; // Track the last auth method used

  User? get currentUser => _currentUser;
  firebase.User? get firebaseUser => _firebaseUser;
  bool get isAuthenticated => _firebaseUser != null;
  bool get isOnboardingCompleted => _isOnboardingCompleted;
  ApiService get apiService => _apiService;
  String? get lastAuthMethod => _lastAuthMethod;

  AuthService() {
    _authStateSubscription = _firebaseAuth.authStateChanges().listen(
      _onAuthStateChanged,
    );
    _loadOnboardingStatus();

    // Register token refresh callback with API service
    _apiService.setTokenRefreshCallback(() async {
      debugPrint('🔄 AuthService: Token refresh requested by API service');
      return await _refreshAuthToken(force: true);
    });
  }

  Future<void> _onAuthStateChanged(firebase.User? firebaseUser) async {
    _firebaseUser = firebaseUser;

    if (firebaseUser != null) {
      // Set user ID in Crashlytics for crash reports
      await CrashlyticsLogger.setUserId(firebaseUser.uid);
      await CrashlyticsLogger.log('User authenticated: ${firebaseUser.uid}');

      // Sync with backend with retries (no signup method for existing sessions)
      await syncUserWithBackend(retries: 3);
      _scheduleTokenRefresh();
    } else {
      // Clear user data on sign out
      await CrashlyticsLogger.clearUserData();
      await CrashlyticsLogger.log('User signed out');
      _currentUser = null;
      _apiService.clearAuthToken();
      _tokenRefreshTimer?.cancel();
    }

    notifyListeners();
  }

  void _scheduleTokenRefresh() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = Timer.periodic(const Duration(minutes: 45), (_) {
      _refreshAuthToken(force: true);
    });
  }

  Future<void> _persistOnboardingCompleted(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value) {
        await prefs.setBool('onboarding_completed', true);
      } else {
        await prefs.remove('onboarding_completed');
      }
      _isOnboardingCompleted = value;
    } catch (e) {
      debugPrint('❌ AuthService: Error persisting onboarding flag: $e');
    }
  }

  Future<String?> _refreshAuthToken({bool force = false}) async {
    if (_firebaseUser == null) {
      return null;
    }

    try {
      final token = await _firebaseUser!.getIdToken(force);
      if (token != null) {
        _apiService.setAuthToken(token);
      }
      return token;
    } catch (e) {
      debugPrint('❌ AuthService: Failed to refresh auth token: $e');
      return null;
    }
  }

  Future<void> syncUserWithBackend({
    int retries = 1,
    String? signUpMethod,
    String? username,
    bool sendFullName = false,
  }) async {
    if (_firebaseUser == null) return;

    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        await _refreshAuthToken(force: true);

        debugPrint(
          '🔄 AuthService: Syncing user with backend (attempt $attempt/$retries)',
        );
        debugPrint('🔄 AuthService: Firebase UID: ${_firebaseUser!.uid}');
        // Reload user to get fresh data after potential linking
        await _firebaseUser!.reload();
        final refreshedUser = _firebaseAuth.currentUser;
        debugPrint('🔄 AuthService: Email: ${refreshedUser?.email}');
        debugPrint(
          '🔄 AuthService: Display name: ${refreshedUser?.displayName}',
        );

        // Prepare sync data to match backend expectations
        // Note: firebase_uid and email come from Firebase token verification, not request body
        final syncData = <String, dynamic>{
          // Only send fullName during initial sync (sign up), not during profile refresh
          // This prevents overwriting user's custom full_name with Firebase displayName
          if (sendFullName && refreshedUser?.displayName != null)
            'fullName': refreshedUser?.displayName,
          if (signUpMethod != null) 'signUpMethod': signUpMethod,
          if (username != null)
            'username':
                username, // Only for anonymous users during initial signup
        };

        debugPrint('🔄 AuthService: Sync data: ${syncData.toString()}');

        final response = await _apiService.post('/auth/sync', syncData);

        _currentUser = User.fromJson(response['user']);
        debugPrint(
          '✅ AuthService: User synced successfully - ID: ${_currentUser?.id}',
        );

        // Retry FCM token registration now that we have auth
        FCMService().retryTokenRegistration();

        if ((_currentUser?.username?.isNotEmpty ?? false) &&
            !_isOnboardingCompleted) {
          await _persistOnboardingCompleted(true);
        }
        notifyListeners();
        return; // Success, exit retry loop
      } catch (e, stackTrace) {
        debugPrint(
          '❌ AuthService: Error syncing user (attempt $attempt/$retries): $e',
        );

        // Log to Crashlytics on final attempt
        if (attempt >= retries) {
          await CrashlyticsLogger.logError(
            e,
            stackTrace,
            reason: 'Failed to sync user with backend after $retries attempts',
            context: {
              'firebase_uid': _firebaseUser?.uid ?? 'unknown',
              'signup_method': signUpMethod ?? 'unknown',
              'attempts': retries,
            },
          );
        }

        if (attempt < retries) {
          await Future.delayed(
            Duration(seconds: attempt * 2),
          ); // Exponential backoff
        } else {
          debugPrint(
            '❌ AuthService: All sync attempts failed - will continue without backend sync',
          );
          // Don't throw error - let user continue with local auth
          // Backend sync can be retried later during onboarding completion
        }
      }
    }
  }

  // ============================================================================
  // NEW CONSOLIDATED AUTHENTICATION METHODS
  // ============================================================================

  /// Authenticate with Google - handles new users, existing users, and merge scenarios
  ///
  /// Returns [AuthenticationResult] with navigation action and user state
  ///
  /// Set [checkMerge] to false to skip merge detection (for legacy callers)
  Future<AuthenticationResult> authenticateWithGoogle({bool checkMerge = true}) async {
    debugPrint('🔑 AuthService: Starting Google authentication (checkMerge: $checkMerge)');

    // Track sign in attempt
    _analyticsService.trackSignInAttempt('google');

    try {
      // Track if user was anonymous before auth
      final wasAnonymous = _firebaseUser?.isAnonymous ?? false;
      String? anonymousUidForMerge;
      bool requiresMerge = false;

      // Step 1: Get Google credential
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('❌ AuthService: Google Sign-In was cancelled by user');
        throw Exception('Google Sign-In was cancelled');
      }

      debugPrint('✅ AuthService: Google user selected: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        debugPrint('❌ AuthService: Failed to get Google auth tokens');
        throw Exception('Failed to get Google authentication tokens');
      }

      final credential = firebase.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Step 2: Perform Firebase authentication
      firebase.UserCredential userCredential;

      if (wasAnonymous && _firebaseUser != null) {
        try {
          // Try to link credential to anonymous account
          debugPrint('🔗 AuthService: Linking Google to anonymous account...');
          userCredential = await _firebaseUser!.linkWithCredential(credential);
          await userCredential.user!.reload();
          _firebaseUser = _firebaseAuth.currentUser;
          debugPrint('✅ Successfully linked Google to anonymous account');
        } on firebase.FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use' && checkMerge) {
            // Check if anonymous account has data worth merging
            debugPrint('⚠️  Credential already in use, checking for merge...');
            final mergeCheck = await _checkMergeRequirement(_firebaseUser!.uid);
            requiresMerge = mergeCheck.$1;
            anonymousUidForMerge = mergeCheck.$2;
            debugPrint('🔍 Merge required: $requiresMerge');
          } else if (e.code == 'provider-already-linked') {
            debugPrint('ℹ️  Provider already linked, signing in...');
          }
          // Sign into existing account
          userCredential = await _firebaseAuth.signInWithCredential(credential);
        }
      } else {
        userCredential = await _firebaseAuth.signInWithCredential(credential);
      }

      debugPrint('✅ AuthService: Firebase auth successful for: ${userCredential.user?.email}');

      // Step 3: Sync with backend and verify user state
      final userContext = await _syncAndVerifyUser(wasAnonymous, 'google');

      // Step 4: Build result based on all signals
      final result = _buildAuthResult(
        wasAnonymous: wasAnonymous,
        requiresMerge: requiresMerge,
        anonymousUidForMerge: anonymousUidForMerge,
        hasUsername: userContext.$1,
        username: userContext.$2,
      );

      // Track successful authentication
      if (result.isNewUser) {
        _analyticsService.trackSignUpSuccess('google');
      } else {
        _analyticsService.trackSignInSuccess('google');
      }

      // Store auth method for later use in onboarding completion
      _lastAuthMethod = 'google';

      debugPrint('✅ AuthService: Authentication complete - action: ${result.action}');
      return result;
    } catch (e) {
      debugPrint('❌ AuthService: Google authentication failed: $e');

      // Track authentication failure
      _analyticsService.trackSignInFailure('google', e.toString());

      await CrashlyticsLogger.logError(e, StackTrace.current, reason: 'Google authentication failed');
      rethrow;
    }
  }

  /// Authenticate with Apple - handles new users, existing users, and merge scenarios
  ///
  /// Returns [AuthenticationResult] with navigation action and user state
  ///
  /// Set [checkMerge] to false to skip merge detection (for legacy callers)
  Future<AuthenticationResult> authenticateWithApple({bool checkMerge = true}) async {
    debugPrint('🍎 AuthService: Starting Apple authentication (checkMerge: $checkMerge)');

    // Track sign in attempt
    _analyticsService.trackSignInAttempt('apple');

    try {
      // Track if user was anonymous before auth
      final wasAnonymous = _firebaseUser?.isAnonymous ?? false;
      String? anonymousUidForMerge;
      bool requiresMerge = false;

      // Step 1: Check if Apple Sign-In is available
      if (!await SignInWithApple.isAvailable()) {
        debugPrint('❌ AuthService: Apple Sign-In not available on this device');
        throw Exception('Apple Sign-In is not available on this device');
      }

      // Step 2: Generate nonce
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Step 3: Request Apple credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      debugPrint('✅ AuthService: Apple credential obtained');

      // Step 4: Create Firebase credential
      final oauthCredential = firebase.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      // Step 5: Perform Firebase authentication
      firebase.UserCredential userCredential;

      if (wasAnonymous && _firebaseUser != null) {
        try {
          // Try to link credential to anonymous account
          debugPrint('🔗 AuthService: Linking Apple to anonymous account...');
          userCredential = await _firebaseUser!.linkWithCredential(oauthCredential);
          await userCredential.user!.reload();
          _firebaseUser = _firebaseAuth.currentUser;
          debugPrint('✅ Successfully linked Apple to anonymous account');
        } on firebase.FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use' && checkMerge) {
            // Check if anonymous account has data worth merging
            debugPrint('⚠️  Credential already in use, checking for merge...');
            final mergeCheck = await _checkMergeRequirement(_firebaseUser!.uid);
            requiresMerge = mergeCheck.$1;
            anonymousUidForMerge = mergeCheck.$2;
            debugPrint('🔍 Merge required: $requiresMerge');
          } else if (e.code == 'provider-already-linked') {
            debugPrint('ℹ️  Provider already linked, signing in...');
          }
          // Sign into existing account
          userCredential = await _firebaseAuth.signInWithCredential(oauthCredential);
        }
      } else {
        userCredential = await _firebaseAuth.signInWithCredential(oauthCredential);
      }

      debugPrint('✅ AuthService: Firebase auth successful');

      // Step 6: Sync with backend and verify user state
      final userContext = await _syncAndVerifyUser(wasAnonymous, 'apple');

      // Step 7: Build result based on all signals
      final result = _buildAuthResult(
        wasAnonymous: wasAnonymous,
        requiresMerge: requiresMerge,
        anonymousUidForMerge: anonymousUidForMerge,
        hasUsername: userContext.$1,
        username: userContext.$2,
      );

      // Track successful authentication
      if (result.isNewUser) {
        _analyticsService.trackSignUpSuccess('apple');
      } else {
        _analyticsService.trackSignInSuccess('apple');
      }

      // Store auth method for later use in onboarding completion
      _lastAuthMethod = 'apple';

      debugPrint('✅ AuthService: Authentication complete - action: ${result.action}');
      return result;
    } catch (e) {
      debugPrint('❌ AuthService: Apple authentication failed: $e');

      // Track authentication failure
      _analyticsService.trackSignInFailure('apple', e.toString());

      await CrashlyticsLogger.logError(e, StackTrace.current, reason: 'Apple authentication failed');
      rethrow;
    }
  }

  /// Perform account merge for anonymous users
  ///
  /// This method handles the complete merge flow:
  /// 1. Calls backend API to merge anonymous account data
  /// 2. Syncs user profile to get updated username
  /// 3. Performs full sync to pull merged wishlists/wishes
  ///
  /// PRECONDITIONS:
  /// - Must be called AFTER user is authenticated with new credential
  /// - Auth token must be valid
  ///
  /// Throws Exception on failure
  Future<void> performAccountMerge(String anonymousFirebaseUid) async {
    debugPrint('🔗 AuthService: Starting account merge for: $anonymousFirebaseUid');

    try {
      // Ensure token is fresh
      await _refreshAuthToken(force: true);

      // Step 1: Backend merge
      await _apiService.mergeAccounts(anonymousFirebaseUid);
      await CrashlyticsLogger.log('Account merge: Backend merge completed');

      // Step 2: Sync user profile
      await syncUserWithBackend(retries: 1);
      await CrashlyticsLogger.log('Account merge: User profile synced');

      // Step 3: Full sync for merged data
      final syncManager = SyncManager();
      var syncResult = await syncManager.performFullSync();

      // Handle sync-in-progress case
      if (syncResult.error == 'Sync already in progress') {
        debugPrint('⚠️  Sync in progress, waiting 2 seconds...');
        await Future.delayed(const Duration(seconds: 2));
        syncResult = await syncManager.performFullSync();
      }

      // Check for errors
      if (syncResult.hasErrors && syncResult.error != 'Sync already in progress') {
        debugPrint('❌ Full sync failed: ${syncResult.error}');
        await CrashlyticsLogger.logError(
          syncResult.error ?? 'Unknown sync error',
          StackTrace.current,
          reason: 'Account merge: Full sync failed',
          context: {
            'push_errors': syncResult.pushErrors.toString(),
            'pull_errors': syncResult.pullErrors.toString(),
          },
        );
        throw Exception('Unable to sync merged data. Please check your connection and try again.');
      }

      debugPrint('✅ Account merge completed successfully');
      await CrashlyticsLogger.log('Account merge: Completed successfully');

      // Step 4: Refresh all app data to show merged content
      debugPrint('🔄 Refreshing app data after merge...');
      await _refreshAppDataAfterMerge();
      debugPrint('✅ App data refreshed successfully');
    } catch (e) {
      debugPrint('❌ Account merge failed: $e');
      await CrashlyticsLogger.logError(
        e,
        StackTrace.current,
        reason: 'Account merge failed',
        context: {'anonymous_uid': anonymousFirebaseUid},
      );
      rethrow;
    }
  }

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
      debugPrint('⚠️  Error refreshing app data after merge: $e');
      // Don't throw - merge succeeded, this is just a UX improvement
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Check if anonymous account has data worth merging
  ///
  /// IMPORTANT: This method first tries to query the SERVER for wishlist/wish data
  /// while still authenticated as the anonymous user (catches server-only data like
  /// wishes created via API but not yet synced locally). If the server check fails
  /// (offline, network error), it falls back to checking local SQLite for unsynced
  /// data (catches offline-created wishes/wishlists).
  ///
  /// This hybrid approach ensures:
  /// - Online: Detects ALL data including server-only wishes
  /// - Offline: Still detects locally-created unsynced data
  ///
  /// Returns: (requiresMerge, anonymousFirebaseUid, hasMergeableData)
  Future<(bool, String?, bool)> _checkMergeRequirement(String firebaseUid) async {
    try {
      debugPrint('🔍 Merge check: Querying server for firebase UID $firebaseUid');

      // FIRST: Try to check server while we still have the anonymous user's auth token
      // This catches wishes created via API but not saved to local SQLite
      try {
        final wishlistsResponse = await _apiService.get('/wishlists');
        final wishlists = (wishlistsResponse?['wishlists'] as List?) ?? [];

        final wishesResponse = await _apiService.get('/wishes');
        final wishes = (wishesResponse?['wishes'] as List?) ?? [];

        final hasData = wishlists.isNotEmpty || wishes.isNotEmpty;

        debugPrint(
          '🔍 Merge check (server): wishlists=${wishlists.length}, wishes=${wishes.length}, hasData=$hasData',
        );

        if (hasData) {
          return (true, firebaseUid, true);
        }

        // No server data, but don't return yet - check local DB too
        debugPrint('🔍 Merge check: No server data, checking local DB...');
      } catch (serverError) {
        // Server check failed (offline, network error, etc.)
        // Fall through to local SQLite check
        debugPrint('⚠️  Server merge check failed, falling back to local DB: $serverError');
      }

      // FALLBACK: Check local SQLite for offline-created or unsynced data
      // This ensures offline users don't lose data
      final localDb = LocalDatabase();

      // Query by firebase_uid (not backend UUID)
      final anonymousUserRows = await localDb.getEntities(
        'users',
        where: 'firebase_uid = ?',
        whereArgs: [firebaseUid],
        limit: 1,
      );

      bool hasData = false;
      String? backendUuid;
      String? username;

      if (anonymousUserRows.isNotEmpty) {
        final anonymousUser = anonymousUserRows.first;
        backendUuid = anonymousUser['id'];
        username = anonymousUser['username'];

        // Check for wishlists linked to this backend UUID
        final wishlists = await localDb.getEntities(
          'wishlists',
          where: 'user_id = ?',
          whereArgs: [backendUuid],
          limit: 1,
        );

        // Check for wishes linked to this backend UUID
        final wishes = await localDb.getEntities(
          'wishes',
          where: 'created_by = ?',
          whereArgs: [backendUuid],
          limit: 1,
        );

        hasData = (username != null && username.isNotEmpty) ||
                  wishlists.isNotEmpty ||
                  wishes.isNotEmpty;

        debugPrint(
          '🔍 Merge check (local DB - user row): username=$username, wishlists=${wishlists.length}, wishes=${wishes.length}',
        );
      }

      // Check for any unsynced data (offline-created)
      if (!hasData) {
        final pendingWishlists = await localDb.getEntities(
          'wishlists',
          where: 'sync_state != ?',
          whereArgs: [SyncState.synced.toString()],
          limit: 1,
        );

        final pendingWishes = await localDb.getEntities(
          'wishes',
          where: 'sync_state != ?',
          whereArgs: [SyncState.synced.toString()],
          limit: 1,
        );

        final pendingChanges = await localDb.getEntities(
          'change_operations',
          where: 'synced = ?',
          whereArgs: [0],
          limit: 1,
        );

        if (pendingWishlists.isNotEmpty ||
            pendingWishes.isNotEmpty ||
            pendingChanges.isNotEmpty) {
          hasData = true;
          debugPrint(
            '🔍 Merge check (local DB - unsynced): wishlists=${pendingWishlists.length}, wishes=${pendingWishes.length}, pendingChanges=${pendingChanges.length}',
          );
        }
      }

      if (!hasData) {
        debugPrint('🔍 Merge check: No data found (server or local)');
      }

      return (hasData, hasData ? firebaseUid : null, hasData);
    } catch (e) {
      debugPrint('❌ Error checking merge requirement: $e');
      await CrashlyticsLogger.logError(
        e,
        StackTrace.current,
        reason: 'Merge check failed',
        context: {'firebase_uid': firebaseUid},
      );
      // On total failure, assume no merge needed (safer than blocking sign-in)
      return (false, null, false);
    }
  }

  /// Sync with backend and verify user state
  ///
  /// Returns: (hasUsername, username)
  Future<(bool, String?)> _syncAndVerifyUser(bool wasAnonymous, String signUpMethod) async {
    // Refresh token before backend calls
    await _refreshAuthToken(force: true);

    // Check if user exists in backend
    final emailCheck = await _apiService.checkEmailExists();
    final existsInDb = emailCheck?['exists'] ?? false;

    debugPrint('📧 User exists in backend: $existsInDb');

    // ALWAYS sync user data - either create new account or update existing
    // This is critical: brand new users need their backend account created!
    //
    // IMPORTANT: Only send full name for BRAND NEW users to avoid overwriting
    // custom names that returning users may have set in-app.
    // - Brand new user (existsInDb=false): Send Firebase profile name
    // - Existing user (existsInDb=true): Don't overwrite their custom name
    // - Anonymous upgrade (wasAnonymous=true): Don't send name (they set it during signup)
    await syncUserWithBackend(
      retries: 3,
      signUpMethod: signUpMethod,
      sendFullName: !existsInDb && !wasAnonymous, // Only for brand new Google/Apple users
    );

    // Get current user state
    final username = _currentUser?.username;
    final hasUsername = username != null && username.isNotEmpty;

    return (hasUsername, username);
  }

  /// Build authentication result based on all signals
  AuthenticationResult _buildAuthResult({
    required bool wasAnonymous,
    required bool requiresMerge,
    required String? anonymousUidForMerge,
    required bool hasUsername,
    required String? username,
  }) {
    // CASE 1: Merge required (credential conflict with data)
    if (requiresMerge && anonymousUidForMerge != null) {
      return AuthenticationResult(
        action: NavigationAction.showMergeDialog,
        requiresMerge: true,
        anonymousUserId: anonymousUidForMerge,
      );
    }

    // CASE 2: Existing user (has username)
    if (hasUsername) {
      return AuthenticationResult(
        action: NavigationAction.goHome,
        isExistingUser: true,
        isAnonymousUpgrade: wasAnonymous,
        username: username,
        userSynced: true,
      );
    }

    // CASE 3: New user (needs onboarding)
    return AuthenticationResult(
      action: NavigationAction.continueOnboarding,
      isNewUser: true,
      resumeAt: OnboardingStep.shoppingInterests, // Full onboarding flow
      userSynced: true,
    );
  }

  // ============================================================================
  // DEPRECATED METHODS (for backward compatibility)
  // ============================================================================

  @Deprecated('Use authenticateWithGoogle() instead. Will be removed in Q2 2025.')
  Future<void> signInWithGoogle() async {
    debugPrint('⚠️  DEPRECATED: signInWithGoogle() called - please migrate to authenticateWithGoogle()');
    await CrashlyticsLogger.log('DEPRECATED_API: signInWithGoogle() called');

    // Still perform full auth + sync so currentUser stays accurate
    await authenticateWithGoogle(checkMerge: false);

    // Legacy behavior: don't navigate, let auth state listener handle it
  }

  @Deprecated('Use authenticateWithApple() instead. Will be removed in Q2 2025.')
  Future<void> signInWithApple() async {
    debugPrint('⚠️  DEPRECATED: signInWithApple() called - please migrate to authenticateWithApple()');
    await CrashlyticsLogger.log('DEPRECATED_API: signInWithApple() called');

    // Still perform full auth + sync so currentUser stays accurate
    await authenticateWithApple(checkMerge: false);

    // Legacy behavior: don't navigate, let auth state listener handle it
  }

  /// Sign in anonymously
  Future<void> signInAnonymously() async {
    try {
      debugPrint('👤 AuthService: Starting anonymous sign-in...');

      // Sign in anonymously with Firebase
      final userCredential = await _firebaseAuth.signInAnonymously();

      debugPrint('✅ AuthService: Anonymous auth successful');
      debugPrint('✅ Firebase UID: ${userCredential.user?.uid}');
      debugPrint('✅ Is Anonymous: ${userCredential.user?.isAnonymous}');

      // Sync with backend (backend will generate username)
      await syncUserWithBackend(signUpMethod: 'anonymous');

      _scheduleTokenRefresh();
    } catch (e) {
      debugPrint('❌ AuthService: Error signing in anonymously: $e');
      rethrow;
    }
  }

  /// Link anonymous account with Google
  Future<void> linkWithGoogle() async {
    try {
      debugPrint('🔗 AuthService: Linking anonymous account with Google...');

      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw Exception('No user is currently signed in');
      }

      if (!currentUser.isAnonymous) {
        throw Exception('Current user is not anonymous');
      }

      // Trigger Google sign-in
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('❌ AuthService: Google Sign-In was cancelled');
        throw Exception('Google Sign-In was cancelled');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = firebase.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link the credential (preserves firebase_uid!)
      await currentUser.linkWithCredential(credential);

      debugPrint('✅ AuthService: Account linked successfully with Google');
      debugPrint('✅ Firebase UID preserved: ${currentUser.uid}');

      // Reload user to get fresh data and update isAnonymous flag
      await currentUser.reload();
      _firebaseUser = _firebaseAuth.currentUser;
      debugPrint('🔄 AuthService: User reloaded, isAnonymous: ${_firebaseUser?.isAnonymous}');

      // Sync with backend to update sign_up_method and full_name
      await syncUserWithBackend(signUpMethod: 'google', sendFullName: true);
    } catch (e) {
      debugPrint('❌ AuthService: Error linking with Google: $e');
      rethrow;
    }
  }

  /// Link anonymous account with Apple
  Future<void> linkWithApple() async {
    try {
      debugPrint('🔗 AuthService: Linking anonymous account with Apple...');

      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw Exception('No user is currently signed in');
      }

      if (!currentUser.isAnonymous) {
        throw Exception('Current user is not anonymous');
      }

      // Check if Apple Sign-In is available
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception('Apple Sign-In is not available on this device');
      }

      // Generate nonce
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request Apple ID credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = firebase.OAuthProvider(
        "apple.com",
      ).credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      // Link the credential (preserves firebase_uid!)
      await currentUser.linkWithCredential(oauthCredential);

      debugPrint('✅ AuthService: Account linked successfully with Apple');
      debugPrint('✅ Firebase UID preserved: ${currentUser.uid}');

      // Reload user to get fresh data and update isAnonymous flag
      await currentUser.reload();
      _firebaseUser = _firebaseAuth.currentUser;
      debugPrint('🔄 AuthService: User reloaded, isAnonymous: ${_firebaseUser?.isAnonymous}');

      // Sync with backend to update sign_up_method and full_name
      await syncUserWithBackend(signUpMethod: 'apple', sendFullName: true);
    } catch (e) {
      debugPrint('❌ AuthService: Error linking with Apple: $e');
      rethrow;
    }
  }

  /// Generate a cryptographically secure random nonce for Apple Sign-In
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // signInWithGoogleCheckExisting() - DELETED - replaced by authenticateWithGoogle()

  // signInWithAppleCheckExisting() - DELETED - replaced by authenticateWithApple()

  Future<void> signOut() async {
    try {
      debugPrint('🔍 AuthService: Signing out...');

      // Sign out from Google if user was signed in with Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
        debugPrint('✅ AuthService: Google sign-out completed');
      }

      // Note: Apple Sign-In doesn't require explicit sign-out
      // The credential is automatically revoked when Firebase signs out

      // Sign out from Firebase
      await _firebaseAuth.signOut();
      debugPrint('✅ AuthService: Firebase sign-out completed');

      _currentUser = null;
      _apiService.clearAuthToken();
      _tokenRefreshTimer?.cancel();
      await _persistOnboardingCompleted(false);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ AuthService: Error signing out: $e');
      rethrow;
    }
  }


  Future<String?> getIdToken() async {
    return await _firebaseUser?.getIdToken();
  }

  /// Load onboarding status from SharedPreferences
  Future<void> _loadOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isOnboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      debugPrint(
        '📱 AuthService: Onboarding completed: $_isOnboardingCompleted',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('❌ AuthService: Error loading onboarding status: $e');
    }
  }

  /// Mark onboarding as completed
  Future<void> markOnboardingCompleted() async {
    await _persistOnboardingCompleted(true);
    debugPrint('✅ AuthService: Onboarding marked as completed');
    notifyListeners();
  }

  /// Reset onboarding status (for testing purposes)
  Future<void> resetOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('onboarding_completed');
      _isOnboardingCompleted = false;
      debugPrint('🔄 AuthService: Onboarding status reset');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ AuthService: Error resetting onboarding status: $e');
    }
  }

  /// Check if user needs to complete onboarding
  bool get needsOnboarding {
    return isAuthenticated && !_isOnboardingCompleted;
  }

  /// Delete user account and all associated data
  Future<bool> deleteAccount() async {
    try {
      debugPrint('🗑️ AuthService: Starting account deletion');

      // Call backend to delete account data
      final success = await _apiService.deleteAccount();

      if (success) {
        // Try to delete Firebase account (backend already deleted it, so this might fail)
        if (_firebaseUser != null) {
          try {
            await _firebaseUser!.delete();
            debugPrint('✅ AuthService: Firebase account deleted');
          } catch (e) {
            // Backend already deleted the Firebase user, so this error is expected
            debugPrint(
              'ℹ️ AuthService: Firebase user already deleted by backend: $e',
            );
          }
        }

        // Clear local data
        await _clearLocalData();

        // Reset state
        _currentUser = null;
        _firebaseUser = null;
        _isOnboardingCompleted = false;
        _apiService.clearAuthToken();
        _tokenRefreshTimer?.cancel();

        notifyListeners();

        debugPrint('✅ AuthService: Account deletion completed successfully');
        return true;
      } else {
        debugPrint('❌ AuthService: Backend account deletion failed');
        return false;
      }
    } catch (e) {
      debugPrint('❌ AuthService: Account deletion error: $e');
      return false;
    }
  }

  /// Clear all local data and reset app state
  Future<void> _clearLocalData() async {
    try {
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear local database
      await LocalDatabase().clearAllData();

      // Sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Sign out from Firebase
      await _firebaseAuth.signOut();

      debugPrint('🧹 AuthService: Local data cleared and user signed out');
    } catch (e) {
      debugPrint('❌ AuthService: Error clearing local data: $e');
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _tokenRefreshTimer?.cancel();
    super.dispose();
  }
}
