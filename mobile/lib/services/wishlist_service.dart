import 'package:flutter/foundation.dart';
import 'dart:io';
import 'api_service.dart';
import '../models/wishlist.dart';
import '../models/wish.dart';

/// Isolate function for parsing large wishlist responses off the main thread
List<Wishlist> _parseWishlistsInIsolate(List<dynamic> wishlistsJson) {
  debugPrint('🔄 Parsing ${wishlistsJson.length} wishlists in isolate');
  
  final wishlists = wishlistsJson
      .map((json) => Wishlist.fromJson(json))
      .toList();
  
  debugPrint('✅ Parsed ${wishlists.length} wishlists in isolate');
  return wishlists;
}

class WishlistService extends ChangeNotifier {
  final ApiService _apiService;

  WishlistService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  List<Wishlist> _wishlists = [];
  List<Wish> _uncategorizedWishes = [];
  Wishlist? _currentWishlist;
  bool _isLoading = false;
  String? _error;

  List<Wishlist> get wishlists => _wishlists;
  List<Wish> get uncategorizedWishes => _uncategorizedWishes;
  Wishlist? get currentWishlist => _currentWishlist;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get all wishes from all sources in a flat list
  List<Wish> get allWishes => [
    ...uncategorizedWishes,
    ...wishlists.expand((wl) => wl.wishes ?? []),
  ];

  /// Get a cached wishlist by ID, useful for instant access
  Wishlist? getCachedWishlist(String id) {
    return _wishlists.where((w) => w.id == id).firstOrNull;
  }

  /// Find a wish by ID across all wishlists and uncategorized wishes
  Wish? findWishById(String wishId) {
    return allWishes.where((w) => w.id == wishId).firstOrNull;
  }

  /// Helper method to update cached wishlist in the main list
  void _updateCachedWishlist(String wishlistId, Wishlist updatedWishlist) {
    final index = _wishlists.indexWhere((w) => w.id == wishlistId);
    if (index != -1) {
      _wishlists[index] = updatedWishlist;
    }
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
        final wishlistsJson = response['wishlists'] as List;

        // Parse wishlists off main thread if we have many items
        if (wishlistsJson.length > 10) {
          _wishlists = await compute(_parseWishlistsInIsolate, wishlistsJson);
        } else {
          _wishlists = wishlistsJson
              .map((json) => Wishlist.fromJson(json))
              .toList();
        }

        print('📋 WishlistService: Parsed ${_wishlists.length} wishlists');

        // Parse uncategorized wishes
        if (response['uncategorizedWishes'] != null) {
          final uncategorizedJson = response['uncategorizedWishes'] as List;
          _uncategorizedWishes = uncategorizedJson
              .map((json) => Wish.fromJson(json))
              .toList();
          print('📋 WishlistService: Parsed ${_uncategorizedWishes.length} uncategorized wishes');
        } else {
          _uncategorizedWishes = [];
        }

        // Preload all wishlist details with items if requested
        if (preloadItems && _wishlists.isNotEmpty) {
          print('📋 WishlistService: Preloading items for ${_wishlists.length} wishlists...');
          await _preloadWishlistItems();
        }
      } else {
        print('📋 WishlistService: Response is null or missing wishlists key');
        _wishlists = [];
        _uncategorizedWishes = [];
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
            
            // Update the wishCount to match the actual number of items loaded
            final actualItemCount = detailedWishlist.wishes?.length ?? 0;
            final correctedWishlist = detailedWishlist.copyWith(
              wishCount: actualItemCount,
            );
            
            print('📋 WishlistService: Updated wish count to $actualItemCount for ${wishlist.name}');
            return correctedWishlist;
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
    
    // If we have the wishlist but without items, set it as current while we load details
    if (cachedWishlist != null) {
      print('📋 WishlistService: Setting cached wishlist as current while loading details');
      _currentWishlist = cachedWishlist;
      notifyListeners();
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
    String visibility = 'private',
    String? coverImageUrl,
  }) async {
    // Generate optimistic ID
    final optimisticId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    // Create optimistic wishlist for immediate UI update
    final optimisticWishlist = Wishlist(
      id: optimisticId,
      name: name,
      description: description ?? '',
      visibility: visibility,
      coverImageUrl: coverImageUrl,
      userId: 'current_user', // Will be corrected by server
      wishCount: 0,
      reservedCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Add optimistic wishlist to local list immediately
    _wishlists.insert(0, optimisticWishlist);
    notifyListeners();

    try {
      final response = await _apiService.post('/wishlists', {
        'name': name,
        'description': description,
        'visibility': visibility,
        if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
      });
      
      // Remove optimistic wishlist
      _wishlists.removeWhere((w) => w.id == optimisticId);
      
      // Add real wishlist from server
      final realWishlist = Wishlist.fromJson(response['wishlist'] ?? response);
      _wishlists.insert(0, realWishlist);
      
      // Set as current wishlist for immediate navigation
      _currentWishlist = realWishlist;
      notifyListeners();
      
      print('✅ WishlistService: Wishlist created successfully (optimistic)');
      return realWishlist;
      
    } catch (e) {
      // Remove failed optimistic wishlist
      _wishlists.removeWhere((w) => w.id == optimisticId);
      
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
    String? visibility,
    String? coverImageUrl,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (visibility != null) data['visibility'] = visibility;
      if (coverImageUrl != null) data['coverImageUrl'] = coverImageUrl;
      
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
    String? wishlistId, // Now optional for uncategorized wishes
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
    print('🎁 WishlistService: Starting addWish (optimistic)...');

    // Generate optimistic ID
    final optimisticId = 'temp_wish_${DateTime.now().millisecondsSinceEpoch}';

    // Create optimistic wish for immediate UI update
    final optimisticWish = Wish(
      id: optimisticId,
      wishlistId: wishlistId ?? '', // Empty string for uncategorized wishes
      title: title,
      description: description ?? '',
      price: price,
      currency: currency ?? 'USD',
      url: url,
      images: images ?? [],
      brand: brand,
      category: category,
      priority: priority != null ? int.tryParse(priority) ?? 1 : 1,
      quantity: quantity,
      notes: notes,
      status: 'available',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // Add optimistic wish to current wishlist immediately (if wishlist is specified)
    if (wishlistId != null && _currentWishlist?.id == wishlistId) {
      final currentWishes = _currentWishlist!.wishes ?? [];
      final updatedWishlist = _currentWishlist!.copyWith(
        wishes: [optimisticWish, ...currentWishes],
        wishCount: (_currentWishlist!.wishCount) + 1,
      );
      _currentWishlist = updatedWishlist;

      _updateCachedWishlist(wishlistId, updatedWishlist);
      notifyListeners();
    }

    try {
      final requestData = <String, dynamic>{
        if (wishlistId != null) 'wishlistId': wishlistId,
        'title': title,
        'description': description,
        'price': price,
        'currency': currency ?? 'USD',
        'url': url,
        'priority': priority != null ? int.tryParse(priority) ?? 1 : 1,
        'quantity': quantity,
        'notes': notes,
      };

      if (images != null && images.isNotEmpty) {
        requestData['images'] = images;
      }
      
      // If there's an image file, upload it first
      if (imageFile != null) {
        try {
          print('🎁 WishlistService: Uploading image...');
          final imageUrl = await _apiService.uploadWishImage(
            imageFile: imageFile,
            wishlistId: wishlistId,
          );
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

      // Replace optimistic wish with real wish from server (if wishlist is specified)
      if (wishlistId != null && _currentWishlist?.id == wishlistId) {
        final currentWishes = _currentWishlist!.wishes ?? [];
        final realWish = Wish.fromJson(response['wish'] ?? response);

        // Remove optimistic wish and add real wish
        final updatedWishes = currentWishes
            .where((w) => w.id != optimisticId)
            .toList();
        updatedWishes.insert(0, realWish);
        
        final updatedWishlist = _currentWishlist!.copyWith(
          wishes: updatedWishes,
        );
        _currentWishlist = updatedWishlist;

        _updateCachedWishlist(wishlistId, updatedWishlist);
        notifyListeners();
      }
      
      print('✅ WishlistService: Wish added successfully (optimistic)');
      return true;
      
    } catch (e) {
      // Remove failed optimistic wish (if wishlist is specified)
      if (wishlistId != null && _currentWishlist?.id == wishlistId) {
        final currentWishes = _currentWishlist!.wishes ?? [];
        final updatedWishes = currentWishes
            .where((w) => w.id != optimisticId)
            .toList();

        final updatedWishlist = _currentWishlist!.copyWith(
          wishes: updatedWishes,
          wishCount: (_currentWishlist!.wishCount) - 1,
        );
        _currentWishlist = updatedWishlist;

        // Update cached wishlist in main list
        final index = _wishlists.indexWhere((w) => w.id == wishlistId);
        if (index != -1) {
          _wishlists[index] = updatedWishlist;
        }

        notifyListeners();
      }
      
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
        _updateCachedWishlist(_currentWishlist!.id, _currentWishlist!);
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
    Wish? deletedWish;
    
    // Optimistically remove wish from current wishlist
    if (_currentWishlist != null) {
      final currentWishes = _currentWishlist!.wishes ?? [];
      deletedWish = currentWishes.where((w) => w.id == wishId).firstOrNull;
      
      if (deletedWish != null) {
        final updatedWishes = currentWishes.where((w) => w.id != wishId).toList();
        final updatedWishlist = _currentWishlist!.copyWith(
          wishes: updatedWishes,
          wishCount: (_currentWishlist!.wishCount) - 1,
        );
        _currentWishlist = updatedWishlist;
        
        // Update cached wishlist in main list
        final index = _wishlists.indexWhere((w) => w.id == _currentWishlist!.id);
        if (index != -1) {
          _wishlists[index] = updatedWishlist;
        }
        
        notifyListeners();
      }
    }
    
    try {
      await _apiService.delete('/wishes/$wishId');
      print('✅ WishlistService: Wish deleted successfully (optimistic)');
      return true;
      
    } catch (e) {
      // Restore deleted wish on failure
      if (_currentWishlist != null && deletedWish != null) {
        final currentWishes = _currentWishlist!.wishes ?? [];
        final restoredWishes = [...currentWishes, deletedWish];
        
        final updatedWishlist = _currentWishlist!.copyWith(
          wishes: restoredWishes,
          wishCount: (_currentWishlist!.wishCount) + 1,
        );
        _currentWishlist = updatedWishlist;
        
        // Update cached wishlist in main list
        final index = _wishlists.indexWhere((w) => w.id == _currentWishlist!.id);
        if (index != -1) {
          _wishlists[index] = updatedWishlist;
        }
        
        notifyListeners();
      }
      
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
        _updateCachedWishlist(_currentWishlist!.id, _currentWishlist!);
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
        _updateCachedWishlist(_currentWishlist!.id, _currentWishlist!);
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

  /// Upload cover image for wishlist
  Future<bool> uploadWishlistCoverImage(String wishlistId, File imageFile) async {
    try {
      print('🖼️ WishlistService: Starting cover image upload for $wishlistId');
      
      // Step 1: Get presigned upload URL
      final uploadInfo = await _apiService.getWishlistCoverUploadUrl(wishlistId);
      if (uploadInfo == null || uploadInfo['uploadUrl'] == null) {
        _error = 'Failed to get upload URL';
        notifyListeners();
        return false;
      }

      // Step 2: Upload image to presigned URL
      final uploadSuccess = await _apiService.uploadImageToPresignedUrl(
        uploadInfo['uploadUrl'],
        imageFile,
      );

      if (!uploadSuccess) {
        _error = 'Failed to upload image';
        notifyListeners();
        return false;
      }

      // Step 3: Update wishlist with the image URL
      final publicUrl = uploadInfo['publicUrl'];
      final updateResult = await _apiService.updateWishlistCoverImage(
        wishlistId,
        publicUrl,
      );

      if (updateResult == null) {
        _error = 'Failed to update wishlist with image';
        notifyListeners();
        return false;
      }

      // Step 4: Refresh wishlist data
      await fetchWishlist(wishlistId);

      debugPrint('✅ WishlistService: Cover image uploaded successfully');
      return true;

    } catch (e) {
      _error = 'Upload failed: $e';
      debugPrint('❌ WishlistService: Error uploading cover image: $e');
      notifyListeners();
      return false;
    }
  }

  /// Remove cover image from wishlist
  Future<bool> removeWishlistCoverImage(String wishlistId) async {
    try {
      final updateResult = await _apiService.updateWishlistCoverImage(
        wishlistId,
        '', // Empty string removes the image
      );

      if (updateResult == null) {
        _error = 'Failed to remove cover image';
        notifyListeners();
        return false;
      }

      // Refresh wishlist data
      await fetchWishlist(wishlistId);

      return true;
    } catch (e) {
      _error = 'Remove cover image failed: $e';
      debugPrint('❌ WishlistService: Error removing cover image: $e');
      notifyListeners();
      return false;
    }
  }
}
