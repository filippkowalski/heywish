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
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  final firebase.FirebaseAuth _firebaseAuth = firebase.FirebaseAuth.instance;
  final ApiService _apiService = ApiService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _currentUser;
  firebase.User? _firebaseUser;
  StreamSubscription<firebase.User?>? _authStateSubscription;
  bool _isOnboardingCompleted = false;
  Timer? _tokenRefreshTimer;

  User? get currentUser => _currentUser;
  firebase.User? get firebaseUser => _firebaseUser;
  bool get isAuthenticated => _firebaseUser != null;
  bool get isOnboardingCompleted => _isOnboardingCompleted;

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
      // Sync with backend with retries (no signup method for existing sessions)
      await syncUserWithBackend(retries: 3);
      _scheduleTokenRefresh();
    } else {
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
      } catch (e) {
        debugPrint(
          '❌ AuthService: Error syncing user (attempt $attempt/$retries): $e',
        );
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


  Future<void> signInWithGoogle() async {
    try {
      debugPrint('🔍 AuthService: Starting Google Sign-In...');

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('❌ AuthService: Google Sign-In was cancelled by user');
        throw Exception('Google Sign-In was cancelled');
      }

      debugPrint('✅ AuthService: Google user selected: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        debugPrint('❌ AuthService: Failed to get Google auth tokens');
        throw Exception('Failed to get Google authentication tokens');
      }

      debugPrint('✅ AuthService: Google auth tokens obtained');

      // Create a new credential
      final credential = firebase.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Check if this is a new user
      final methods = await _firebaseAuth.fetchSignInMethodsForEmail(
        googleUser.email,
      );
      final isNewUser = methods.isEmpty;

      // Sign in to Firebase with the Google credential
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      debugPrint(
        '✅ AuthService: Firebase auth successful for: ${userCredential.user?.email}',
      );
      debugPrint(
        '✅ AuthService: Display name: ${userCredential.user?.displayName}',
      );

      // If this is a new user, sync with signup method
      if (isNewUser) {
        await syncUserWithBackend(signUpMethod: 'google', sendFullName: true);
      }
      _scheduleTokenRefresh();
    } catch (e) {
      debugPrint('❌ AuthService: Error signing in with Google: $e');
      rethrow;
    }
  }

  Future<void> signInWithApple() async {
    try {
      debugPrint('🍎 AuthService: Starting Apple Sign-In...');

      // Check if Apple Sign-In is available
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        debugPrint('❌ AuthService: Apple Sign-In not available on this device');
        throw Exception('Apple Sign-In is not available on this device');
      }

      // Generate a random nonce
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      debugPrint('🍎 AuthService: Requesting Apple ID credential...');

      // Request Apple ID credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      debugPrint('✅ AuthService: Apple ID credential received');
      debugPrint('🍎 User ID: ${appleCredential.userIdentifier}');
      debugPrint('🍎 Email: ${appleCredential.email}');
      debugPrint('🍎 Given Name: ${appleCredential.givenName}');
      debugPrint('🍎 Family Name: ${appleCredential.familyName}');

      // Create OAuth credential for Firebase
      final oauthCredential = firebase.OAuthProvider(
        "apple.com",
      ).credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase with Apple credential
      final userCredential = await _firebaseAuth.signInWithCredential(
        oauthCredential,
      );

      // Check if this is a new user
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      debugPrint('✅ AuthService: Firebase auth successful for Apple user');
      debugPrint('✅ AuthService: Firebase user: ${userCredential.user?.email}');
      debugPrint(
        '✅ AuthService: Display name: ${userCredential.user?.displayName}',
      );

      // If this is the first time signing in and we have name info, update the display name
      if (userCredential.user?.displayName == null &&
          (appleCredential.givenName != null ||
              appleCredential.familyName != null)) {
        final displayName =
            '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                .trim();
        if (displayName.isNotEmpty) {
          await userCredential.user?.updateDisplayName(displayName);
          debugPrint('✅ AuthService: Updated display name to: $displayName');
        }
      }

      // If this is a new user, sync with signup method
      if (isNewUser) {
        await syncUserWithBackend(signUpMethod: 'apple', sendFullName: true);
      }
      _scheduleTokenRefresh();
    } catch (e) {
      debugPrint('❌ AuthService: Error signing in with Apple: $e');

      // Provide more specific error messages
      if (e.toString().contains('AuthorizationErrorCode.unknown')) {
        throw Exception(
          'Apple Sign-In capability not enabled.\n\nTo fix this:\n1. Open Apple Developer Portal\n2. Go to Identifiers → com.wishlists.gifts\n3. Enable "Sign In with Apple" capability\n4. Or open Xcode → Signing & Capabilities → Add "Sign In with Apple"',
        );
      } else if (e.toString().contains('AuthorizationErrorCode.canceled')) {
        throw Exception('Apple Sign-In was cancelled by the user');
      } else if (e.toString().contains(
        'AuthorizationErrorCode.invalidResponse',
      )) {
        throw Exception('Invalid response from Apple Sign-In');
      } else if (e.toString().contains('AuthorizationErrorCode.notHandled')) {
        throw Exception('Apple Sign-In request was not handled');
      } else if (e.toString().contains('AuthorizationErrorCode.failed')) {
        throw Exception('Apple Sign-In failed. Please try again.');
      }

      rethrow;
    }
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

  /// Sign in with Google for "Already have account" flow
  /// Returns true if user exists in DB, false if new user
  Future<bool> signInWithGoogleCheckExisting() async {
    try {
      debugPrint('🔍 AuthService: Starting Google Sign-In (check existing)...');

      // Check if current user is anonymous
      final isAnonymous = _firebaseUser?.isAnonymous ?? false;
      debugPrint('🔍 AuthService: Current user is anonymous: $isAnonymous');

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('❌ AuthService: Google Sign-In was cancelled by user');
        throw Exception('Google Sign-In was cancelled');
      }

      debugPrint('✅ AuthService: Google user selected: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        debugPrint('❌ AuthService: Failed to get Google auth tokens');
        throw Exception('Failed to get Google authentication tokens');
      }

      debugPrint('✅ AuthService: Google auth tokens obtained');

      // Create a new credential
      final credential = firebase.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      firebase.UserCredential userCredential;

      if (isAnonymous && _firebaseUser != null) {
        try {
          // Link the Google credential to the existing anonymous account
          final oldUid = _firebaseUser!.uid;
          debugPrint('🔗 AuthService: Linking Google account to anonymous user...');
          debugPrint('🔗 AuthService: Anonymous UID before linking: $oldUid');

          userCredential = await _firebaseUser!.linkWithCredential(credential);

          final newUid = userCredential.user?.uid;
          debugPrint('✅ AuthService: Successfully linked Google account');
          debugPrint('✅ AuthService: UID after linking: $newUid');
          debugPrint('✅ AuthService: UID preserved: ${oldUid == newUid}');
        } on firebase.FirebaseAuthException catch (e) {
          if (e.code == 'provider-already-linked') {
            // Already linked, just sign in instead
            debugPrint('ℹ️  AuthService: Provider already linked, signing in...');
            userCredential = await _firebaseAuth.signInWithCredential(credential);
          } else if (e.code == 'credential-already-in-use') {
            // This email is already associated with a different account
            // We'll need to handle account merging
            debugPrint('⚠️  AuthService: Credential already in use by another account');
            rethrow;
          } else {
            rethrow;
          }
        }
      } else {
        // Sign in to Firebase with the Google credential
        debugPrint('🔑 AuthService: Signing in with Google credential...');
        userCredential = await _firebaseAuth.signInWithCredential(credential);
      }

      debugPrint(
        '✅ AuthService: Firebase auth successful for: ${userCredential.user?.email}',
      );

      // Get auth token to check database
      await _refreshAuthToken(force: true);

      // Check if user exists in database (they should if they upgraded from anonymous)
      final emailCheckResponse = await _apiService.checkEmailExists();
      final userExists = emailCheckResponse?['exists'] ?? false;

      debugPrint('📧 AuthService: User exists in DB: $userExists');

      if (userExists || isAnonymous) {
        // User exists OR was anonymous (now linked) - sync to update their data
        await syncUserWithBackend(
          retries: 3,
          signUpMethod: 'google',
          sendFullName: !isAnonymous, // Only send full name for new Google users
        );
      }
      // If user doesn't exist and wasn't anonymous, don't sync yet - let onboarding handle it

      _scheduleTokenRefresh();

      return userExists;
    } catch (e) {
      debugPrint('❌ AuthService: Error signing in with Google: $e');
      rethrow;
    }
  }

  /// Sign in with Apple for "Already have account" flow
  /// Returns true if user exists in DB, false if new user
  Future<bool> signInWithAppleCheckExisting() async {
    try {
      debugPrint('🍎 AuthService: Starting Apple Sign-In (check existing)...');

      // Check if current user is anonymous
      final isAnonymous = _firebaseUser?.isAnonymous ?? false;
      debugPrint('🔍 AuthService: Current user is anonymous: $isAnonymous');

      // Check if Apple Sign-In is available
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        debugPrint('❌ AuthService: Apple Sign-In not available on this device');
        throw Exception('Apple Sign-In is not available on this device');
      }

      // Generate a random nonce
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      debugPrint('🍎 AuthService: Requesting Apple ID credential...');

      // Request Apple ID credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      debugPrint('✅ AuthService: Apple ID credential received');

      // Create OAuth credential for Firebase
      final oauthCredential = firebase.OAuthProvider(
        "apple.com",
      ).credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      firebase.UserCredential userCredential;

      if (isAnonymous && _firebaseUser != null) {
        try {
          // Link the Apple credential to the existing anonymous account
          final oldUid = _firebaseUser!.uid;
          debugPrint('🔗 AuthService: Linking Apple account to anonymous user...');
          debugPrint('🔗 AuthService: Anonymous UID before linking: $oldUid');

          userCredential = await _firebaseUser!.linkWithCredential(oauthCredential);

          final newUid = userCredential.user?.uid;
          debugPrint('✅ AuthService: Successfully linked Apple account');
          debugPrint('✅ AuthService: UID after linking: $newUid');
          debugPrint('✅ AuthService: UID preserved: ${oldUid == newUid}');
        } on firebase.FirebaseAuthException catch (e) {
          if (e.code == 'provider-already-linked') {
            // Already linked, just sign in instead
            debugPrint('ℹ️  AuthService: Provider already linked, signing in...');
            userCredential = await _firebaseAuth.signInWithCredential(oauthCredential);
          } else if (e.code == 'credential-already-in-use') {
            // This email is already associated with a different account
            // We'll need to handle account merging
            debugPrint('⚠️  AuthService: Credential already in use by another account');
            rethrow;
          } else {
            rethrow;
          }
        }
      } else {
        // Sign in to Firebase with the Apple credential
        debugPrint('🔑 AuthService: Signing in with Apple credential...');
        userCredential = await _firebaseAuth.signInWithCredential(oauthCredential);
      }

      debugPrint('✅ AuthService: Firebase auth successful for Apple user');

      // Update display name if available
      if (userCredential.user?.displayName == null &&
          (appleCredential.givenName != null ||
              appleCredential.familyName != null)) {
        final displayName =
            '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                .trim();
        if (displayName.isNotEmpty) {
          await userCredential.user?.updateDisplayName(displayName);
          debugPrint('✅ AuthService: Updated display name to: $displayName');
        }
      }

      // Get auth token to check database
      await _refreshAuthToken(force: true);

      // Check if user exists in database (they should if they upgraded from anonymous)
      final emailCheckResponse = await _apiService.checkEmailExists();
      final userExists = emailCheckResponse?['exists'] ?? false;

      debugPrint('📧 AuthService: User exists in DB: $userExists');

      if (userExists || isAnonymous) {
        // User exists OR was anonymous (now linked) - sync to update their data
        await syncUserWithBackend(
          retries: 3,
          signUpMethod: 'apple',
          sendFullName: !isAnonymous, // Only send full name for new Apple users
        );
      }
      // If user doesn't exist and wasn't anonymous, don't sync yet - let onboarding handle it

      _scheduleTokenRefresh();

      return userExists;
    } catch (e) {
      debugPrint('❌ AuthService: Error signing in with Apple: $e');
      rethrow;
    }
  }

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
