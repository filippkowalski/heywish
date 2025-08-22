import 'package:flutter/foundation.dart';
import 'api_service.dart';

enum OnboardingStep {
  welcome,
  username,
  profileInfo,
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
  final ApiService _apiService = ApiService();
  
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
        _currentStep = OnboardingStep.username;
        break;
      case OnboardingStep.username:
        _currentStep = OnboardingStep.profileInfo;
        break;
      case OnboardingStep.profileInfo:
        _currentStep = OnboardingStep.notifications;
        break;
      case OnboardingStep.notifications:
        _currentStep = OnboardingStep.findFriends;
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
      case OnboardingStep.username:
        _currentStep = OnboardingStep.welcome;
        break;
      case OnboardingStep.profileInfo:
        _currentStep = OnboardingStep.username;
        break;
      case OnboardingStep.notifications:
        _currentStep = OnboardingStep.profileInfo;
        break;
      case OnboardingStep.findFriends:
        _currentStep = OnboardingStep.notifications;
        break;
      case OnboardingStep.accountChoice:
        _currentStep = OnboardingStep.findFriends;
        break;
      case OnboardingStep.complete:
        _currentStep = OnboardingStep.accountChoice;
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
  
  /// Check username availability with debouncing
  Future<void> checkUsernameAvailability(String username) async {
    if (username.length < 3) {
      _usernameCheckResult = 'Username must be at least 3 characters';
      _usernameSuggestions = [];
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      debugPrint('🔍 OnboardingService: Checking username: $username');
      
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
        _usernameCheckResult = 'Error checking username';
        _usernameSuggestions = [];
      }
      
    } catch (e) {
      debugPrint('❌ OnboardingService: Username check error: $e');
      _usernameCheckResult = 'Error checking username';
      _usernameSuggestions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void updateUsername(String username) {
    _data.username = username;
    _usernameCheckResult = null;
    _usernameSuggestions = [];
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
  
  /// Complete onboarding by saving all data to server
  Future<bool> completeOnboarding() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      debugPrint('🎯 OnboardingService: Completing onboarding');
      
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
        return true;
      } else {
        debugPrint('❌ OnboardingService: Profile update returned null');
        _error = 'Failed to save profile';
        return false;
      }
      
    } catch (e) {
      debugPrint('❌ OnboardingService: Onboarding completion error: $e');
      _error = 'Failed to complete onboarding';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Validate current step data
  bool canProceedFromCurrentStep() {
    switch (_currentStep) {
      case OnboardingStep.welcome:
        return true; // Always can proceed from welcome
      case OnboardingStep.username:
        return _data.isUsernameValid && _usernameCheckResult == 'Available';
      case OnboardingStep.profileInfo:
        return true; // Profile info is optional
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