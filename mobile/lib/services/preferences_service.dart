import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService extends ChangeNotifier {
  static const String _hasSeenOnboardingKey = 'has_seen_onboarding';
  static const String _themeMode = 'theme_mode';
  static const String _hasSeenAddItemTipKey = 'has_seen_add_item_tip';

  SharedPreferences? _prefs;
  bool _hasSeenOnboarding = false;
  String _themeModeString = 'system';
  bool _hasSeenAddItemTip = false;

  bool get hasSeenOnboarding => _hasSeenOnboarding;
  String get themeModeString => _themeModeString;
  bool get hasSeenAddItemTip => _hasSeenAddItemTip;
  
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();
  
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _hasSeenOnboarding = _prefs?.getBool(_hasSeenOnboardingKey) ?? false;
    _themeModeString = _prefs?.getString(_themeMode) ?? 'system';
    _hasSeenAddItemTip = _prefs?.getBool(_hasSeenAddItemTipKey) ?? false;
    notifyListeners();
  }
  
  Future<void> setHasSeenOnboarding(bool value) async {
    _hasSeenOnboarding = value;
    await _prefs?.setBool(_hasSeenOnboardingKey, value);
    notifyListeners();
  }
  
  Future<void> setThemeMode(String value) async {
    _themeModeString = value;
    await _prefs?.setString(_themeMode, value);
    notifyListeners();
  }

  Future<void> setHasSeenAddItemTip(bool value) async {
    _hasSeenAddItemTip = value;
    await _prefs?.setBool(_hasSeenAddItemTipKey, value);
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _prefs?.clear();
    _hasSeenOnboarding = false;
    _themeModeString = 'system';
    _hasSeenAddItemTip = false;
    notifyListeners();
  }
}