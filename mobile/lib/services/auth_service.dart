import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Dio _dio = Dio();
  static const String baseUrl = 'https://heywish.com/api'; // Change for development
  
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Initialize and create anonymous user if needed
  Future<void> initialize() async {
    final user = _auth.currentUser;
    if (user == null) {
      await signInAnonymously();
    } else {
      await _syncWithBackend(user);
    }
  }
  
  // Sign in anonymously
  Future<User?> signInAnonymously() async {
    try {
      final result = await _auth.signInAnonymously();
      if (result.user != null) {
        await _syncWithBackend(result.user!);
      }
      return result.user;
    } catch (e) {
      print('Error signing in anonymously: $e');
      rethrow;
    }
  }
  
  // Sign in with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user != null) {
        await _syncWithBackend(result.user!);
      }
      return result.user;
    } catch (e) {
      print('Error signing in with email: $e');
      rethrow;
    }
  }
  
  // Sign up with email and password
  Future<User?> signUpWithEmail(String email, String password, {String? username}) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user != null) {
        await _syncWithBackend(result.user!, username: username);
      }
      return result.user;
    } catch (e) {
      print('Error signing up: $e');
      rethrow;
    }
  }
  
  // Upgrade anonymous account
  Future<User?> upgradeAnonymousAccount(String email, String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || !user.isAnonymous) {
        throw Exception('No anonymous user to upgrade');
      }
      
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      
      final result = await user.linkWithCredential(credential);
      if (result.user != null) {
        await _syncWithBackend(result.user!);
      }
      return result.user;
    } catch (e) {
      print('Error upgrading account: $e');
      rethrow;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    // Clear any local data
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
  
  // Sync user with backend
  Future<void> _syncWithBackend(User user, {String? username}) async {
    try {
      final token = await user.getIdToken();
      
      final response = await _dio.post(
        '$baseUrl/auth/sync',
        data: {
          'firebaseToken': token,
          if (username != null) 'username': username,
        },
      );
      
      // Store user data locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', response.data['user']['id']);
      await prefs.setString('userEmail', response.data['user']['email'] ?? '');
      await prefs.setBool('isAnonymous', response.data['user']['isAnonymous'] ?? false);
    } catch (e) {
      print('Error syncing with backend: $e');
      // Don't throw - allow offline usage
    }
  }
  
  // Get Firebase ID token for API calls
  Future<String?> getIdToken() async {
    try {
      return await _auth.currentUser?.getIdToken();
    } catch (e) {
      print('Error getting ID token: $e');
      return null;
    }
  }
}