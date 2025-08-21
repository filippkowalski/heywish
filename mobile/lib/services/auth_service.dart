import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  final firebase.FirebaseAuth _firebaseAuth = firebase.FirebaseAuth.instance;
  final ApiService _apiService = ApiService();
  
  User? _currentUser;
  firebase.User? _firebaseUser;
  StreamSubscription<firebase.User?>? _authStateSubscription;
  
  User? get currentUser => _currentUser;
  firebase.User? get firebaseUser => _firebaseUser;
  bool get isAuthenticated => _firebaseUser != null;
  bool get isAnonymous => _firebaseUser?.isAnonymous ?? true;
  
  AuthService() {
    _authStateSubscription = _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
  }
  
  Future<void> _onAuthStateChanged(firebase.User? firebaseUser) async {
    _firebaseUser = firebaseUser;
    
    if (firebaseUser != null) {
      // Sync with backend with retries
      await syncUserWithBackend(retries: 3);
    } else {
      _currentUser = null;
    }
    
    notifyListeners();
  }
  
  Future<void> syncUserWithBackend({int retries = 1}) async {
    if (_firebaseUser == null) return;
    
    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        final idToken = await _firebaseUser!.getIdToken(true); // Force refresh token
        _apiService.setAuthToken(idToken);
        
        debugPrint('🔄 AuthService: Syncing user with backend (attempt $attempt/$retries)');
        debugPrint('🔄 AuthService: Firebase UID: ${_firebaseUser!.uid}');
        debugPrint('🔄 AuthService: Is anonymous (before reload): ${_firebaseUser!.isAnonymous}');
        
        // Reload user to get fresh data after potential linking
        await _firebaseUser!.reload();
        final refreshedUser = _firebaseAuth.currentUser;
        debugPrint('🔄 AuthService: Is anonymous (after reload): ${refreshedUser!.isAnonymous}');
        debugPrint('🔄 AuthService: Email: ${refreshedUser.email}');
        debugPrint('🔄 AuthService: Display name: ${refreshedUser.displayName}');
        
        final response = await _apiService.post('/auth/sync', {
          'firebase_uid': refreshedUser!.uid,
          'email': refreshedUser.email,
          'full_name': refreshedUser.displayName,
          'is_anonymous': refreshedUser.isAnonymous,
        });
        
        _currentUser = User.fromJson(response['user']);
        debugPrint('✅ AuthService: User synced successfully - ID: ${_currentUser?.id}');
        notifyListeners();
        return; // Success, exit retry loop
      } catch (e) {
        debugPrint('❌ AuthService: Error syncing user (attempt $attempt/$retries): $e');
        if (attempt < retries) {
          await Future.delayed(Duration(seconds: attempt * 2)); // Exponential backoff
        } else {
          debugPrint('❌ AuthService: All sync attempts failed');
        }
      }
    }
  }
  
  Future<void> signInAnonymously() async {
    try {
      await _firebaseAuth.signInAnonymously();
    } catch (e) {
      debugPrint('Error signing in anonymously: $e');
      rethrow;
    }
  }
  
  Future<void> signInWithEmail(String email, String password) async {
    try {
      // If currently anonymous, link the account
      if (_firebaseUser?.isAnonymous ?? false) {
        final credential = firebase.EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        await _firebaseUser!.linkWithCredential(credential);
      } else {
        await _firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } catch (e) {
      debugPrint('Error signing in with email: $e');
      rethrow;
    }
  }
  
  Future<void> signUpWithEmail(String email, String password, String name) async {
    try {
      // If currently anonymous, link the account
      if (_firebaseUser?.isAnonymous ?? false) {
        final credential = firebase.EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        final userCredential = await _firebaseUser!.linkWithCredential(credential);
        
        // Update display name
        await userCredential.user!.updateDisplayName(name);
      } else {
        final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        // Update display name
        await userCredential.user!.updateDisplayName(name);
      }
      
      // Sync with backend
      await syncUserWithBackend();
    } catch (e) {
      debugPrint('Error signing up: $e');
      rethrow;
    }
  }
  
  Future<void> signInWithGoogle() async {
    try {
      // TODO: Implement Google Sign In
      // Requires google_sign_in package and configuration
      throw UnimplementedError('Google Sign In not yet implemented');
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }
  
  Future<void> signInWithApple() async {
    try {
      // TODO: Implement Apple Sign In
      // Requires sign_in_with_apple package and configuration
      throw UnimplementedError('Apple Sign In not yet implemented');
    } catch (e) {
      debugPrint('Error signing in with Apple: $e');
      rethrow;
    }
  }
  
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      _currentUser = null;
      _apiService.clearAuthToken();
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }
  
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error resetting password: $e');
      rethrow;
    }
  }
  
  Future<String?> getIdToken() async {
    return await _firebaseUser?.getIdToken();
  }
  
  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}