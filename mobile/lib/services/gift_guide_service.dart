import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/gift_guide_category.dart';
import '../models/gift_guide.dart';

/// Service for managing gift guides state and API calls
class GiftGuideService extends ChangeNotifier {
  final ApiService _apiService;

  // State
  List<GiftGuideCategory>? _categories;
  List<GiftGuide>? _allGuides;
  final Map<String, List<GiftGuide>> _guidesByCategory = {};
  final Map<String, GiftGuide> _guideDetails = {};

  bool _isLoading = false;
  String? _error;

  // Getters
  List<GiftGuideCategory>? get categories => _categories;
  List<GiftGuide>? get allGuides => _allGuides;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get categories grouped by section
  Map<String, List<GiftGuideCategory>>? get categoriesGrouped {
    if (_categories == null) return null;

    final Map<String, List<GiftGuideCategory>> grouped = {
      'shopping': [],
      'occasion': [],
      'recipient': [],
      'price_style': [],
    };

    for (final category in _categories!) {
      if (grouped.containsKey(category.group)) {
        grouped[category.group]!.add(category);
      }
    }

    return grouped;
  }

  /// Get guides grouped by category section
  /// Returns guides organized by the 4 main sections
  Map<String, List<GiftGuide>>? get guidesGroupedBySection {
    if (_allGuides == null || _categories == null) return null;

    // Create category slug → group mapping
    final Map<String, String> categoryToGroup = {};
    for (final category in _categories!) {
      categoryToGroup[category.slug] = category.group;
    }

    // Group guides by section
    final Map<String, List<GiftGuide>> grouped = {
      'shopping': [],
      'occasion': [],
      'recipient': [],
      'price_style': [],
    };

    for (final guide in _allGuides!) {
      final group = categoryToGroup[guide.categorySlug];
      if (group != null && grouped.containsKey(group)) {
        grouped[group]!.add(guide);
      } else if (group == null) {
        debugPrint('⚠️ Guide "${guide.title}" has unmapped category: ${guide.categorySlug}');
      }
    }

    return grouped;
  }

  GiftGuideService(this._apiService);

  /// Load all categories from API
  Future<void> loadCategories({bool forceRefresh = false}) async {
    // Return cached data if available and not forcing refresh
    if (_categories != null && !forceRefresh) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getGiftGuideCategories();

      if (response != null) {
        final List<GiftGuideCategory> allCategories = [];

        // Parse each group
        response.forEach((group, categoriesList) {
          for (final json in categoriesList) {
            try {
              allCategories.add(GiftGuideCategory.fromJson(json));
            } catch (e) {
              debugPrint('❌ Error parsing category: $e');
            }
          }
        });

        _categories = allCategories;
        _error = null;
      } else {
        _error = 'Failed to load categories';
      }
    } catch (e) {
      _error = 'Error loading categories: $e';
      debugPrint('❌ GiftGuideService: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load all guides (no category filter)
  Future<void> loadAllGuides({bool forceRefresh = false}) async {
    // Return cached if available
    if (_allGuides != null && !forceRefresh) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final guides = await loadGuidesByCategory(null, forceRefresh: forceRefresh);
      _allGuides = guides;
      _error = null;
    } catch (e) {
      _error = 'Error loading guides: $e';
      debugPrint('❌ GiftGuideService.loadAllGuides: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load guides for a specific category (or all if null)
  Future<List<GiftGuide>> loadGuidesByCategory(
    String? categorySlug, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = categorySlug ?? 'all';

    // Return cached data if available and not forcing refresh
    if (_guidesByCategory.containsKey(cacheKey) && !forceRefresh) {
      return _guidesByCategory[cacheKey]!;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getGiftGuides(
        categorySlug: categorySlug,
      );

      if (response != null) {
        final List<GiftGuide> guides = [];

        for (final json in response) {
          try {
            guides.add(GiftGuide.fromJson(json));
          } catch (e) {
            debugPrint('❌ Error parsing guide: $e');
          }
        }

        _guidesByCategory[cacheKey] = guides;
        _error = null;
        _isLoading = false;
        notifyListeners();

        return guides;
      } else {
        _error = 'Failed to load guides';
        _isLoading = false;
        notifyListeners();
        return [];
      }
    } catch (e) {
      _error = 'Error loading guides: $e';
      debugPrint('❌ GiftGuideService: $e');
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  /// Load full guide details with items
  Future<GiftGuide?> loadGuideDetails(
    String slug, {
    bool forceRefresh = false,
  }) async {
    // Return cached data if available and not forcing refresh
    if (_guideDetails.containsKey(slug) && !forceRefresh) {
      return _guideDetails[slug];
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getGiftGuideDetails(slug);

      if (response != null) {
        final guide = GiftGuide.fromJson(response);
        _guideDetails[slug] = guide;
        _error = null;
        _isLoading = false;
        notifyListeners();
        return guide;
      } else {
        _error = 'Failed to load guide details';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Error loading guide details: $e';
      debugPrint('❌ GiftGuideService: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Clear all cached data
  void clearCache() {
    _categories = null;
    _allGuides = null;
    _guidesByCategory.clear();
    _guideDetails.clear();
    _error = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
