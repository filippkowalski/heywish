import 'package:flutter/foundation.dart';
import 'dart:io';
import 'api_service.dart';

enum OnboardingStep {
  welcome,
  intro,
  username,
  usernameConfirmation,
  birthday,
  gender,
  notifications,
  findFriends,
  accountChoice,
  complete
}

class OnboardingData {
  String? username;
  String? fullName;
  DateTime? birthday;
  String? gender;
  Map<String, bool> notificationPreferences;
  bool contactPermissionGranted;
  List<Map<String, dynamic>> friendSuggestions;

  OnboardingData({
    this.username,
    this.fullName,
    this.birthday,
    this.gender,
    Map<String, bool>? notificationPreferences,
    this.contactPermissionGranted = false,
    List<Map<String, dynamic>>? friendSuggestions,
  }) : notificationPreferences = notificationPreferences ?? {
          'birthday_notifications': true,
          'coupon_notifications': true,
          'discount_notifications': true,
          'friend_activity': true,
          'wishlist_updates': true,
        },
        friendSuggestions = friendSuggestions ?? [];

  bool get isUsernameValid => username != null && username!.length >= 3;
  bool get isProfileComplete => true; // Now optional
  
  Map<String, dynamic> toProfileUpdateData() {
    return {
      'username': username,
      'full_name': fullName,
      'birthdate': birthday?.toIso8601String().split('T')[0], // YYYY-MM-DD format
      'gender': gender,
      'notification_preferences': notificationPreferences,
      'privacy_settings': {
        'phone_discoverable': contactPermissionGranted,
        'show_birthday': true,
        'show_gender': false,
      },
    };
  }
}

class OnboardingService extends ChangeNotifier {
  final ApiService _apiService;
  
  OnboardingService({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService();
  
  OnboardingStep _currentStep = OnboardingStep.welcome;
  OnboardingData _data = OnboardingData();
  bool _isLoading = false;
  String? _error;
  String? _usernameCheckResult;
  List<String> _usernameSuggestions = [];
  
  OnboardingStep get currentStep => _currentStep;
  OnboardingData get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get usernameCheckResult => _usernameCheckResult;
  List<String> get usernameSuggestions => _usernameSuggestions;
  
  void nextStep() {
    switch (_currentStep) {
      case OnboardingStep.welcome:
        _currentStep = OnboardingStep.intro;
        break;
      case OnboardingStep.intro:
        _currentStep = OnboardingStep.username;
        break;
      case OnboardingStep.username:
        _currentStep = OnboardingStep.usernameConfirmation;
        break;
      case OnboardingStep.usernameConfirmation:
        _currentStep = OnboardingStep.birthday;
        break;
      case OnboardingStep.birthday:
        _currentStep = OnboardingStep.gender;
        break;
      case OnboardingStep.gender:
        _currentStep = OnboardingStep.notifications;
        break;
      case OnboardingStep.notifications:
        _currentStep = OnboardingStep.complete; // Skip account choice, go directly to complete
        break;
      case OnboardingStep.findFriends:
        _currentStep = OnboardingStep.accountChoice;
        break;
      case OnboardingStep.accountChoice:
        _currentStep = OnboardingStep.complete;
        break;
      case OnboardingStep.complete:
        // Already at the end
        break;
    }
    notifyListeners();
  }
  
  void previousStep() {
    switch (_currentStep) {
      case OnboardingStep.welcome:
        // Can't go back from first step
        break;
      case OnboardingStep.intro:
        _currentStep = OnboardingStep.welcome;
        break;
      case OnboardingStep.username:
        _currentStep = OnboardingStep.intro;
        break;
      case OnboardingStep.usernameConfirmation:
        _currentStep = OnboardingStep.username;
        break;
      case OnboardingStep.birthday:
        _currentStep = OnboardingStep.usernameConfirmation;
        break;
      case OnboardingStep.gender:
        _currentStep = OnboardingStep.birthday;
        break;
      case OnboardingStep.notifications:
        _currentStep = OnboardingStep.gender;
        break;
      case OnboardingStep.findFriends:
        _currentStep = OnboardingStep.notifications;
        break;
      case OnboardingStep.accountChoice:
        _currentStep = OnboardingStep.notifications; // Skip find friends for now
        break;
      case OnboardingStep.complete:
        _currentStep = OnboardingStep.notifications; // Go back to notifications
        break;
    }
    notifyListeners();
  }
  
  void goToStep(OnboardingStep step) {
    _currentStep = step;
    notifyListeners();
  }
  
  /// Skip directly to account choice (near end)
  void skipToAccountChoice() {
    _currentStep = OnboardingStep.accountChoice;
    notifyListeners();
  }
  
  /// Check username availability with retry logic and enhanced error handling
  Future<void> checkUsernameAvailability(String username, {int retryAttempt = 0}) async {
    if (username.length < 3) {
      _usernameCheckResult = 'Username must be at least 3 characters';
      _usernameSuggestions = [];
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    const maxRetries = 3;
    const baseDelay = Duration(milliseconds: 1000);
    
    try {
      debugPrint('🔍 OnboardingService: Checking username: $username (attempt ${retryAttempt + 1})');
      
      final response = await _apiService.checkUsernameAvailability(username);
      
      if (response != null) {
        final isAvailable = response['available'] as bool;
        
        if (isAvailable) {
          _usernameCheckResult = 'Available';
          _data.username = username;
          _usernameSuggestions = [];
        } else {
          _usernameCheckResult = 'Username taken';
          _usernameSuggestions = List<String>.from(response['suggestions'] ?? []);
        }
      } else {
        throw Exception('Server returned null response');
      }
      
    } catch (e) {
      debugPrint('❌ OnboardingService: Username check error (attempt ${retryAttempt + 1}): $e');
      
      // Determine error type and decide on retry strategy
      final shouldRetry = _shouldRetryUsernameCheck(e, retryAttempt, maxRetries);
      
      if (shouldRetry) {
        // Exponential backoff: 1s, 2s, 4s
        final delay = Duration(milliseconds: baseDelay.inMilliseconds * (1 << retryAttempt));
        debugPrint('🔄 OnboardingService: Retrying username check in ${delay.inMilliseconds}ms...');
        
        await Future.delayed(delay);
        return checkUsernameAvailability(username, retryAttempt: retryAttempt + 1);
      } else {
        // Set appropriate error message based on error type
        _usernameCheckResult = _getErrorMessage(e, retryAttempt >= maxRetries);
        _usernameSuggestions = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Determine if we should retry the username check based on error type
  bool _shouldRetryUsernameCheck(dynamic error, int retryAttempt, int maxRetries) {
    if (retryAttempt >= maxRetries) return false;
    
    final errorString = error.toString().toLowerCase();
    
    // Retry on network-related errors
    if (errorString.contains('socket') ||
        errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('network') ||
        errorString.contains('server returned null')) {
      return true;
    }
    
    // Don't retry on client errors (400-499) except timeouts
    if (errorString.contains('400') ||
        errorString.contains('401') ||
        errorString.contains('403') ||
        errorString.contains('404')) {
      return false;
    }
    
    // Retry on server errors (500+)
    if (errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504')) {
      return true;
    }
    
    // Default: retry for unknown errors
    return true;
  }
  
  /// Get user-friendly error message based on error type
  String _getErrorMessage(dynamic error, bool maxRetriesReached) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('socket') ||
        errorString.contains('connection') ||
        errorString.contains('network')) {
      return maxRetriesReached 
          ? 'Connection failed. Check your internet connection.'
          : 'Connection issue...';
    }
    
    if (errorString.contains('timeout')) {
      return maxRetriesReached
          ? 'Request timed out. Please try again.'
          : 'Checking...';
    }
    
    if (errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504')) {
      return maxRetriesReached
          ? 'Server error. Please try again later.'
          : 'Server issue...';
    }
    
    // Default error message
    return maxRetriesReached
        ? 'Unable to check username. Please try again.'
        : 'Checking...';
  }
  
  void updateUsername(String username) {
    _data.username = username;
    
    // Optimistic UI updates
    if (username.length < 3) {
      _usernameCheckResult = 'Username must be at least 3 characters';
      _usernameSuggestions = [];
    } else {
      // Show checking state immediately for better perceived performance
      _usernameCheckResult = 'Checking...';
      _usernameSuggestions = [];
    }
    
    notifyListeners();
  }
  
  void updateFullName(String fullName) {
    _data.fullName = fullName;
    notifyListeners();
  }
  
  void updateBirthday(DateTime birthday) {
    _data.birthday = birthday;
    notifyListeners();
  }
  
  void updateGender(String gender) {
    _data.gender = gender;
    notifyListeners();
  }
  
  void updateNotificationPreference(String key, bool value) {
    _data.notificationPreferences[key] = value;
    notifyListeners();
  }
  
  void updateContactPermission(bool granted) {
    _data.contactPermissionGranted = granted;
    notifyListeners();
  }
  
  void updateFriendSuggestions(List<Map<String, dynamic>> suggestions) {
    _data.friendSuggestions = suggestions;
    notifyListeners();
  }
  
  /// Complete onboarding by saving all data to server with retry logic
  Future<bool> completeOnboarding({int retryAttempt = 0}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    const maxRetries = 2; // Less retries for profile completion
    const baseDelay = Duration(milliseconds: 1500);
    
    try {
      debugPrint('🎯 OnboardingService: Completing onboarding (attempt ${retryAttempt + 1})');
      
      final profileData = _data.toProfileUpdateData();
      final response = await _apiService.updateUserProfile(
        username: profileData['username'],
        fullName: profileData['full_name'],
        birthdate: profileData['birthdate'],
        gender: profileData['gender'],
        notificationPreferences: profileData['notification_preferences'],
        privacySettings: profileData['privacy_settings'],
      );
      
      if (response != null) {
        debugPrint('✅ OnboardingService: Onboarding completed successfully');
        _currentStep = OnboardingStep.complete;
        _error = null; // Clear any previous errors
        return true;
      } else {
        throw Exception('Server returned null response for profile update');
      }
      
    } catch (e) {
      debugPrint('❌ OnboardingService: Onboarding completion error (attempt ${retryAttempt + 1}): $e');
      
      // Determine if we should retry
      final shouldRetry = _shouldRetryProfileUpdate(e, retryAttempt, maxRetries);
      
      if (shouldRetry) {
        // Exponential backoff: 1.5s, 3s
        final delay = Duration(milliseconds: baseDelay.inMilliseconds * (1 << retryAttempt));
        debugPrint('🔄 OnboardingService: Retrying profile update in ${delay.inMilliseconds}ms...');
        
        await Future.delayed(delay);
        return completeOnboarding(retryAttempt: retryAttempt + 1);
      } else {
        _error = _getProfileUpdateErrorMessage(e, retryAttempt >= maxRetries);
        return false;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Determine if we should retry the profile update based on error type
  bool _shouldRetryProfileUpdate(dynamic error, int retryAttempt, int maxRetries) {
    if (retryAttempt >= maxRetries) return false;
    
    final errorString = error.toString().toLowerCase();
    
    // Retry on network-related errors
    if (errorString.contains('socket') ||
        errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('network') ||
        errorString.contains('server returned null')) {
      return true;
    }
    
    // Don't retry on validation errors (username conflicts, etc.)
    if (errorString.contains('409') || // Conflict
        errorString.contains('422') || // Unprocessable Entity
        errorString.contains('400')) {  // Bad Request
      return false;
    }
    
    // Retry on server errors
    if (errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504')) {
      return true;
    }
    
    return true; // Default: retry for unknown errors
  }
  
  /// Get user-friendly error message for profile update failures
  String _getProfileUpdateErrorMessage(dynamic error, bool maxRetriesReached) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('409')) {
      return 'Username is already taken. Please choose a different one.';
    }
    
    if (errorString.contains('422')) {
      return 'Please check your information and try again.';
    }
    
    if (errorString.contains('socket') ||
        errorString.contains('connection') ||
        errorString.contains('network')) {
      return maxRetriesReached
          ? 'Connection failed. Your profile will be saved when connection is restored.'
          : 'Saving profile...';
    }
    
    if (errorString.contains('timeout')) {
      return maxRetriesReached
          ? 'Request timed out. Please try again.'
          : 'Saving profile...';
    }
    
    if (errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504')) {
      return maxRetriesReached
          ? 'Server error. Please try again later.'
          : 'Saving profile...';
    }
    
    return maxRetriesReached
        ? 'Failed to save profile. Please try again.'
        : 'Saving profile...';
  }
  
  /// Validate current step data
  bool canProceedFromCurrentStep() {
    switch (_currentStep) {
      case OnboardingStep.welcome:
        return true; // Always can proceed from welcome
      case OnboardingStep.intro:
        return true; // Always can proceed from intro
      case OnboardingStep.username:
        return _data.isUsernameValid && _usernameCheckResult == 'Available';
      case OnboardingStep.usernameConfirmation:
        return true; // Auto-transitions, no user interaction needed
      case OnboardingStep.birthday:
        return true; // Birthday is optional
      case OnboardingStep.gender:
        return true; // Gender is optional
      case OnboardingStep.notifications:
        return true; // Notifications are optional
      case OnboardingStep.findFriends:
        return true; // Friend discovery is optional
      case OnboardingStep.accountChoice:
        return true; // Choice is made by button press, not validation
      case OnboardingStep.complete:
        return false; // Already complete
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  /// Check if device has internet connectivity
  Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }
  
  /// Force retry username check (for manual retry button)
  Future<void> retryUsernameCheck() async {
    if (_data.username != null && _data.username!.isNotEmpty) {
      await checkUsernameAvailability(_data.username!, retryAttempt: 0);
    }
  }
  
  /// Force retry profile completion (for manual retry button)
  Future<bool> retryProfileCompletion() async {
    return await completeOnboarding(retryAttempt: 0);
  }

  void reset() {
    _currentStep = OnboardingStep.welcome;
    _data = OnboardingData();
    _isLoading = false;
    _error = null;
    _usernameCheckResult = null;
    _usernameSuggestions = [];
    notifyListeners();
  }
}