import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  final firebase.FirebaseAuth _firebaseAuth = firebase.FirebaseAuth.instance;
  final ApiService _apiService = ApiService();
  
  User? _currentUser;
  firebase.User? _firebaseUser;
  
  User? get currentUser => _currentUser;
  firebase.User? get firebaseUser => _firebaseUser;
  bool get isAuthenticated => _firebaseUser != null;
  bool get isAnonymous => _firebaseUser?.isAnonymous ?? true;
  
  AuthService() {
    _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
  }
  
  Future<void> _onAuthStateChanged(firebase.User? firebaseUser) async {
    _firebaseUser = firebaseUser;
    
    if (firebaseUser != null) {
      // Sync with backend
      await syncUserWithBackend();
    } else {
      _currentUser = null;
    }
    
    notifyListeners();
  }
  
  Future<void> syncUserWithBackend() async {
    if (_firebaseUser == null) return;
    
    try {
      final idToken = await _firebaseUser!.getIdToken();
      _apiService.setAuthToken(idToken);
      
      final response = await _apiService.post('/auth/sync', {
        'firebase_uid': _firebaseUser!.uid,
        'email': _firebaseUser!.email,
        'full_name': _firebaseUser!.displayName,
        'is_anonymous': _firebaseUser!.isAnonymous,
      });
      
      _currentUser = User.fromJson(response['user']);
      notifyListeners();
    } catch (e) {
      debugPrint('Error syncing user: $e');
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
}