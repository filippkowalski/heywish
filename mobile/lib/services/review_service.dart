import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewService extends ChangeNotifier {
  static const String _hasRequestedReviewKey = 'has_requested_review';
  static const String _wishesAddedCountKey = 'wishes_added_count';
  static const String _appLaunchCountKey = 'app_launch_count';
  static const int _reviewThreshold = 2;
  static const int _launchCountThreshold = 2;

  final InAppReview _inAppReview = InAppReview.instance;
  SharedPreferences? _prefs;

  bool _hasRequestedReview = false;
  int _wishesAddedCount = 0;
  int _appLaunchCount = 0;

  bool get hasRequestedReview => _hasRequestedReview;
  int get wishesAddedCount => _wishesAddedCount;
  int get appLaunchCount => _appLaunchCount;

  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _hasRequestedReview = _prefs?.getBool(_hasRequestedReviewKey) ?? false;
    _wishesAddedCount = _prefs?.getInt(_wishesAddedCountKey) ?? 0;
    _appLaunchCount = _prefs?.getInt(_appLaunchCountKey) ?? 0;
    notifyListeners();
  }

  /// Call this on app launch to track launches and potentially request review
  Future<void> onAppLaunched({required bool hasCompletedOnboarding}) async {
    // Don't track if we've already requested a review
    if (_hasRequestedReview) return;

    _appLaunchCount++;
    await _prefs?.setInt(_appLaunchCountKey, _appLaunchCount);
    notifyListeners();

    debugPrint('🚀 ReviewService: App launch count: $_appLaunchCount');

    // Request review on second launch if onboarding is complete
    if (_appLaunchCount >= _launchCountThreshold && hasCompletedOnboarding) {
      debugPrint('⭐ ReviewService: Requesting review on app launch #$_appLaunchCount');
      await _requestReview();
    }
  }

  /// Call this after successfully adding a wish
  Future<void> onWishAdded() async {
    // Don't track if we've already requested a review
    if (_hasRequestedReview) return;

    _wishesAddedCount++;
    await _prefs?.setInt(_wishesAddedCountKey, _wishesAddedCount);
    notifyListeners();

    debugPrint('🎁 ReviewService: Wishes added count: $_wishesAddedCount');

    // Request review if we've reached the threshold
    if (_wishesAddedCount >= _reviewThreshold) {
      await _requestReview();
    }
  }

  /// Request an in-app review
  Future<void> _requestReview() async {
    if (_hasRequestedReview) {
      debugPrint('⭐ ReviewService: Review already requested, skipping');
      return;
    }

    try {
      // Check if review is available on this device
      final isAvailable = await _inAppReview.isAvailable();

      if (isAvailable) {
        debugPrint('⭐ ReviewService: Requesting in-app review...');
        await _inAppReview.requestReview();

        // Mark as requested so we don't show it again
        _hasRequestedReview = true;
        await _prefs?.setBool(_hasRequestedReviewKey, true);
        notifyListeners();

        debugPrint('✅ ReviewService: Review requested successfully');
      } else {
        debugPrint('⚠️  ReviewService: In-app review not available on this device');
      }
    } catch (e) {
      debugPrint('❌ ReviewService: Error requesting review: $e');
    }
  }

  /// Manually trigger the review prompt (for testing or manual triggers)
  Future<void> manuallyRequestReview() async {
    try {
      final isAvailable = await _inAppReview.isAvailable();

      if (isAvailable) {
        debugPrint('⭐ ReviewService: Manually requesting review...');
        await _inAppReview.requestReview();
      } else {
        // Fallback to opening app store on platforms where requestReview isn't available
        debugPrint('⭐ ReviewService: Opening app store...');
        await _inAppReview.openStoreListing();
      }
    } catch (e) {
      debugPrint('❌ ReviewService: Error manually requesting review: $e');
    }
  }

  /// Reset the review state (useful for testing)
  Future<void> resetReviewState() async {
    _hasRequestedReview = false;
    _wishesAddedCount = 0;
    _appLaunchCount = 0;
    await _prefs?.setBool(_hasRequestedReviewKey, false);
    await _prefs?.setInt(_wishesAddedCountKey, 0);
    await _prefs?.setInt(_appLaunchCountKey, 0);
    notifyListeners();
    debugPrint('🔄 ReviewService: Review state reset');
  }

  Future<void> clearAll() async {
    await resetReviewState();
  }
}
