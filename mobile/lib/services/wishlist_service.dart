import 'package:flutter/foundation.dart';
import 'dart:io';
import 'api_service.dart';
import '../models/wishlist.dart';
import '../models/wish.dart';

class WishlistService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Wishlist> _wishlists = [];
  Wishlist? _currentWishlist;
  bool _isLoading = false;
  String? _error;
  
  List<Wishlist> get wishlists => _wishlists;
  Wishlist? get currentWishlist => _currentWishlist;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Get a cached wishlist by ID, useful for instant access
  Wishlist? getCachedWishlist(String id) {
    return _wishlists.where((w) => w.id == id).firstOrNull;
  }
  
  Future<void> fetchWishlists({bool preloadItems = true}) async {
    // Prevent multiple simultaneous requests
    if (_isLoading) {
      print('📋 WishlistService: Already loading, skipping request');
      return;
    }
    
    print('📋 WishlistService: Starting fetchWishlists (preloadItems: $preloadItems)...');
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      print('📋 WishlistService: Making API call to /wishlists');
      final response = await _apiService.get('/wishlists');
      print('📋 WishlistService: API response received: $response');
      
      if (response != null && response['wishlists'] != null) {
        _wishlists = (response['wishlists'] as List)
            .map((json) => Wishlist.fromJson(json))
            .toList();
        print('📋 WishlistService: Parsed ${_wishlists.length} wishlists');
        
        // Preload all wishlist details with items if requested
        if (preloadItems && _wishlists.isNotEmpty) {
          print('📋 WishlistService: Preloading items for ${_wishlists.length} wishlists...');
          await _preloadWishlistItems();
        }
      } else {
        print('📋 WishlistService: Response is null or missing wishlists key');
        _wishlists = [];
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('❌ WishlistService: Error fetching wishlists: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _preloadWishlistItems() async {
    try {
      // Fetch details for all wishlists concurrently
      final futures = _wishlists.map((wishlist) async {
        try {
          print('📋 WishlistService: Preloading items for wishlist ${wishlist.id}...');
          final response = await _apiService.get('/wishlists/${wishlist.id}');
          if (response != null && response['wishlist'] != null) {
            final detailedWishlist = Wishlist.fromJson(response['wishlist']);
            print('📋 WishlistService: Loaded ${detailedWishlist.wishes?.length ?? 0} items for ${wishlist.name}');
            return detailedWishlist;
          }
        } catch (e) {
          print('⚠️  WishlistService: Failed to preload items for wishlist ${wishlist.id}: $e');
          // Return original wishlist if detailed fetch fails
          return wishlist;
        }
        return wishlist;
      }).toList();
      
      // Wait for all requests to complete
      final detailedWishlists = await Future.wait(futures);
      
      // Update the wishlists with detailed data
      _wishlists = detailedWishlists;
      
      print('✅ WishlistService: Successfully preloaded items for all wishlists');
      notifyListeners();
    } catch (e) {
      print('❌ WishlistService: Error during preloading: $e');
      // Don't throw error here - we still have basic wishlist data
    }
  }
  
  Future<void> fetchWishlist(String id) async {
    print('📋 WishlistService: fetchWishlist called for ID: $id');
    
    // Check if we already have this wishlist with items preloaded
    final cachedWishlist = _wishlists.where((w) => w.id == id).firstOrNull;
    if (cachedWishlist != null && cachedWishlist.wishes != null) {
      print('📋 WishlistService: Using cached wishlist data for ${cachedWishlist.name}');
      _currentWishlist = cachedWishlist;
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      print('📋 WishlistService: Fetching wishlist details from API...');
      final response = await _apiService.get('/wishlists/$id');
      _currentWishlist = Wishlist.fromJson(response['wishlist']);
      
      // Update the cached wishlist in the main list if it exists
      final index = _wishlists.indexWhere((w) => w.id == id);
      if (index != -1) {
        _wishlists[index] = _currentWishlist!;
        print('📋 WishlistService: Updated cached wishlist data');
      }
      
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching wishlist: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<Wishlist?> createWishlist({
    required String name,
    String? description,
    String? occasionType,
    DateTime? eventDate,
    String visibility = 'private',
  }) async {
    try {
      final response = await _apiService.post('/wishlists', {
        'name': name,
        'description': description,
        'occasion_type': occasionType,
        'event_date': eventDate?.toIso8601String(),
        'visibility': visibility,
      });
      
      // The response structure needs to match our API
      final wishlistData = response is Map<String, dynamic> ? response : {'id': response['id'], 'name': response['name']};
      
      // Refresh wishlists to get updated data (with preloading)
      await fetchWishlists(preloadItems: true);
      
      return _wishlists.where((w) => w.id == wishlistData['id'].toString()).firstOrNull;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating wishlist: $e');
      notifyListeners();
      return null;
    }
  }
  
  Future<bool> updateWishlist(
    String id, {
    String? name,
    String? description,
    String? occasionType,
    DateTime? eventDate,
    String? visibility,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (occasionType != null) data['occasion_type'] = occasionType;
      if (eventDate != null) data['event_date'] = eventDate.toIso8601String();
      if (visibility != null) data['visibility'] = visibility;
      
      await _apiService.patch('/wishlists/$id', data);
      
      // Refresh both lists and current wishlist (with preloading)
      await fetchWishlists(preloadItems: true);
      if (_currentWishlist?.id == id) {
        await fetchWishlist(id);
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating wishlist: $e');
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> deleteWishlist(String id) async {
    try {
      await _apiService.delete('/wishlists/$id');
      
      _wishlists.removeWhere((w) => w.id == id);
      if (_currentWishlist?.id == id) {
        _currentWishlist = null;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting wishlist: $e');
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> addWish({
    required String wishlistId,
    required String title,
    String? description,
    double? price,
    String? currency,
    String? url,
    List<String>? images,
    String? brand,
    String? category,
    String? priority,
    int quantity = 1,
    String? notes,
    File? imageFile,
  }) async {
    print('🎁 WishlistService: Starting addWish...');
    print('🎁 WishlistService: wishlistId: $wishlistId');
    print('🎁 WishlistService: title: $title');
    print('🎁 WishlistService: description: $description');
    print('🎁 WishlistService: price: $price');
    
    try {
      final requestData = {
        'wishlistId': wishlistId,
        'title': title,
        'description': description,
        'price': price,
        'currency': currency ?? 'USD',
        'url': url,
        'images': images ?? [],
        'priority': priority != null ? int.tryParse(priority) ?? 1 : 1,
        'quantity': quantity,
        'notes': notes,
      };
      
      print('🎁 WishlistService: Request data: $requestData');
      
      // If there's an image file, upload it first
      if (imageFile != null) {
        try {
          print('🎁 WishlistService: Uploading image...');
          final imageUrl = await _apiService.uploadImage(imageFile);
          if (imageUrl != null) {
            requestData['images'] = [imageUrl];
            print('🎁 WishlistService: Image uploaded: $imageUrl');
          }
        } catch (imageError) {
          print('⚠️  WishlistService: Image upload failed: $imageError');
          // Continue without image - don't fail the entire request
        }
      }
      
      final response = await _apiService.post('/wishes', requestData);
      print('🎁 WishlistService: API response: $response');
      
      // Refresh the current wishlist and cached data
      print('🎁 WishlistService: Refreshing wishlist $wishlistId');
      await fetchWishlist(wishlistId);
      
      // Also refresh the cached wishlist in the main list
      final index = _wishlists.indexWhere((w) => w.id == wishlistId);
      if (index != -1 && _currentWishlist != null) {
        _wishlists[index] = _currentWishlist!;
        print('🎁 WishlistService: Updated cached wishlist in main list');
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      print('❌ WishlistService: Error adding wish: $e');
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> updateWish(
    String wishId, {
    String? title,
    String? description,
    double? price,
    String? currency,
    String? url,
    List<String>? images,
    String? brand,
    String? category,
    int? priority,
    int? quantity,
    String? notes,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (price != null) data['price'] = price;
      if (currency != null) data['currency'] = currency;
      if (url != null) data['url'] = url;
      if (images != null) data['images'] = images;
      if (priority != null) data['priority'] = priority;
      if (quantity != null) data['quantity'] = quantity;
      if (notes != null) data['notes'] = notes;
      
      await _apiService.patch('/wishes/$wishId', data);
      
      // Refresh the current wishlist and cached data
      if (_currentWishlist != null) {
        await fetchWishlist(_currentWishlist!.id);
        
        // Also refresh the cached wishlist in the main list
        final index = _wishlists.indexWhere((w) => w.id == _currentWishlist!.id);
        if (index != -1) {
          _wishlists[index] = _currentWishlist!;
        }
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating wish: $e');
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> deleteWish(String wishId) async {
    try {
      await _apiService.delete('/wishes/$wishId');
      
      // Refresh the current wishlist and cached data
      if (_currentWishlist != null) {
        await fetchWishlist(_currentWishlist!.id);
        
        // Also refresh the cached wishlist in the main list
        final index = _wishlists.indexWhere((w) => w.id == _currentWishlist!.id);
        if (index != -1) {
          _wishlists[index] = _currentWishlist!;
        }
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting wish: $e');
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> reserveWish(String wishId, String? reserverName) async {
    try {
      await _apiService.post('/wishes/$wishId/reserve', {
        'reserver_name': reserverName,
      });
      
      // Refresh the current wishlist and cached data
      if (_currentWishlist != null) {
        await fetchWishlist(_currentWishlist!.id);
        
        // Also refresh the cached wishlist in the main list
        final index = _wishlists.indexWhere((w) => w.id == _currentWishlist!.id);
        if (index != -1) {
          _wishlists[index] = _currentWishlist!;
        }
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error reserving wish: $e');
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> unreserveWish(String wishId) async {
    try {
      await _apiService.delete('/wishes/$wishId/reserve');
      
      // Refresh the current wishlist and cached data
      if (_currentWishlist != null) {
        await fetchWishlist(_currentWishlist!.id);
        
        // Also refresh the cached wishlist in the main list
        final index = _wishlists.indexWhere((w) => w.id == _currentWishlist!.id);
        if (index != -1) {
          _wishlists[index] = _currentWishlist!;
        }
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error unreserving wish: $e');
      notifyListeners();
      return false;
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}