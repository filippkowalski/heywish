import 'package:flutter/foundation.dart';
import 'dart:io';
import 'api_service.dart';
import 'review_service.dart';
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

  // Simplified state: wishlists are just metadata, all wishes in a flat list
  List<Wishlist> _wishlists = [];
  List<Wish> _allWishes = [];
  bool _isLoading = false;
  String? _error;

  List<Wishlist> get wishlists => _wishlists;
  List<Wish> get allWishes => _allWishes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get wishes for a specific wishlist (filtered from _allWishes)
  List<Wish> getWishesForWishlist(String? wishlistId) {
    return _allWishes.where((w) => w.wishlistId == wishlistId).toList();
  }

  /// Get wishes that don't belong to any wishlist (unsorted)
  List<Wish> get unsortedWishes {
    return _allWishes.where((w) => w.wishlistId == '').toList();
  }

  /// Get a cached wishlist by ID
  Wishlist? getCachedWishlist(String id) {
    return _wishlists.where((w) => w.id == id).firstOrNull;
  }

  /// Find a wish by ID in the flat list
  Wish? findWishById(String wishId) {
    return _allWishes.where((w) => w.id == wishId).firstOrNull;
  }

  Future<void> fetchWishlists() async {
    // Prevent multiple simultaneous requests
    if (_isLoading) {
      print('📋 WishlistService: Already loading, skipping request');
      return;
    }

    print('📋 WishlistService: Starting fetchWishlists...');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch wishlists and wishes in parallel
      final results = await Future.wait([
        _apiService.get('/wishlists'),
        _apiService.get('/wishes'),
      ]);

      final wishlistsResponse = results[0];
      final wishesResponse = results[1];

      // Parse wishlists (metadata only)
      if (wishlistsResponse != null && wishlistsResponse['wishlists'] != null) {
        final wishlistsJson = wishlistsResponse['wishlists'] as List;

        // Parse wishlists off main thread if we have many items
        if (wishlistsJson.length > 10) {
          _wishlists = await compute(_parseWishlistsInIsolate, wishlistsJson);
        } else {
          _wishlists = wishlistsJson
              .map((json) => Wishlist.fromJson(json))
              .toList();
        }

        print('📋 WishlistService: Parsed ${_wishlists.length} wishlists');
      } else {
        _wishlists = [];
      }

      // Parse all wishes (flat list)
      if (wishesResponse != null && wishesResponse['wishes'] != null) {
        final wishesJson = wishesResponse['wishes'] as List;
        _allWishes = wishesJson
            .map((json) => Wish.fromJson(json))
            .toList();
        print('📋 WishlistService: Parsed ${_allWishes.length} wishes');
      } else {
        _allWishes = [];
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      print('❌ WishlistService: Error fetching data: $e');
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
      notifyListeners();

      print('✅ WishlistService: Wishlist created successfully (optimistic)');
      return realWishlist;
      
    } catch (e) {
      // Remove failed optimistic wishlist
      _wishlists.removeWhere((w) => w.id == optimisticId);

      debugPrint('Error creating wishlist: $e');
      // Don't set _error - let the caller handle the error with a snackbar
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

      final response = await _apiService.patch('/wishlists/$id', data);

      // Update wishlist in cache
      final wishlistIndex = _wishlists.indexWhere((w) => w.id == id);
      if (wishlistIndex != -1) {
        final updatedWishlist = Wishlist.fromJson(response['wishlist'] ?? response);
        _wishlists[wishlistIndex] = updatedWishlist;
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error updating wishlist: $e');
      // Don't set _error - let the caller handle the error with a snackbar
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> deleteWishlist(String id) async {
    try {
      await _apiService.delete('/wishlists/$id');

      _wishlists.removeWhere((w) => w.id == id);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting wishlist: $e');
      // Don't set _error - let the caller handle the error with a snackbar
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> addWish({
    String? wishlistId, // Optional - null for unsorted wishes
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
      wishlistId: wishlistId ?? '', // Empty string for unsorted wishes
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

    // Add optimistic wish to flat list immediately
    _allWishes.insert(0, optimisticWish);
    notifyListeners();

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
          print('🎁 WishlistService: Image file path: ${imageFile.path}');
          print('🎁 WishlistService: Image file exists: ${await imageFile.exists()}');
          print('🎁 WishlistService: Image file size: ${await imageFile.length()} bytes');

          final imageUrl = await _apiService.uploadWishImage(
            imageFile: imageFile,
            wishlistId: wishlistId,
          );

          print('🎁 WishlistService: Image upload result: $imageUrl');

          if (imageUrl != null) {
            requestData['images'] = [imageUrl];
            print('🎁 WishlistService: Image uploaded successfully: $imageUrl');
            print('🎁 WishlistService: Request data images: ${requestData['images']}');
          } else {
            print('⚠️  WishlistService: Image upload returned null');
          }
        } catch (imageError) {
          print('⚠️  WishlistService: Image upload failed with error: $imageError');
          print('⚠️  WishlistService: Error stack trace: ${imageError.toString()}');
          // Continue without image - don't fail the entire request
        }
      }
      
      final response = await _apiService.post('/wishes', requestData);

      // Replace optimistic wish with real wish from server
      final realWish = Wish.fromJson(response['wish'] ?? response);
      final optimisticIndex = _allWishes.indexWhere((w) => w.id == optimisticId);
      if (optimisticIndex != -1) {
        _allWishes[optimisticIndex] = realWish;
        notifyListeners();
      }

      print('✅ WishlistService: Wish added successfully');

      // Track wish addition for review prompt
      try {
        await ReviewService().onWishAdded();
      } catch (e) {
        debugPrint('⚠️  Error tracking wish for review: $e');
        // Don't fail the wish creation if review tracking fails
      }

      return true;

    } catch (e) {
      // Remove failed optimistic wish
      _allWishes.removeWhere((w) => w.id == optimisticId);

      debugPrint('Error adding wish: $e');
      // Don't set _error - let the caller handle the error with a snackbar
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateWishPositions(String wishlistId, List<Map<String, dynamic>> positions) async {
    try {
      await _apiService.patch('/wishlists/$wishlistId/wishes/positions', {
        'positions': positions,
      });

      // Refetch wishes to get updated positions
      final wishesResponse = await _apiService.get('/wishes');
      if (wishesResponse != null && wishesResponse['wishes'] != null) {
        final wishesJson = wishesResponse['wishes'] as List;
        _allWishes = wishesJson.map((json) => Wish.fromJson(json)).toList();
        notifyListeners();
      }

      return true;
    } catch (e) {
      _isLoading = false;
      debugPrint('Error updating wish positions: $e');
      // Don't set _error - let the caller handle the error with a snackbar
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
    String? wishlistId,
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
      if (wishlistId != null) data['wishlistId'] = wishlistId;

      final response = await _apiService.patch('/wishes/$wishId', data);

      // Update wish in flat list
      final wishIndex = _allWishes.indexWhere((w) => w.id == wishId);
      if (wishIndex != -1) {
        final updatedWish = Wish.fromJson(response['wish'] ?? response);
        _allWishes[wishIndex] = updatedWish;
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error updating wish: $e');
      // Don't set _error - let the caller handle the error with a snackbar
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> deleteWish(String wishId) async {
    // Find and optimistically remove wish from flat list
    final wishIndex = _allWishes.indexWhere((w) => w.id == wishId);
    final deletedWish = wishIndex != -1 ? _allWishes[wishIndex] : null;

    if (deletedWish != null) {
      _allWishes.removeAt(wishIndex);
      notifyListeners();
    }

    try {
      await _apiService.delete('/wishes/$wishId');
      print('✅ WishlistService: Wish deleted successfully');
      return true;

    } catch (e) {
      // Restore deleted wish on failure
      if (deletedWish != null) {
        _allWishes.insert(wishIndex, deletedWish);
      }

      debugPrint('Error deleting wish: $e');
      // Don't set _error here - the wish is restored, so UI should show the list
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> reserveWish(String wishId, String? reserverName) async {
    try {
      final response = await _apiService.post('/wishes/$wishId/reserve', {
        'reserver_name': reserverName,
      });

      // Update wish in flat list
      final wishIndex = _allWishes.indexWhere((w) => w.id == wishId);
      if (wishIndex != -1) {
        final updatedWish = Wish.fromJson(response['wish'] ?? response);
        _allWishes[wishIndex] = updatedWish;
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error reserving wish: $e');
      // Don't set _error - let the caller handle the error with a snackbar
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> unreserveWish(String wishId) async {
    try {
      final response = await _apiService.delete('/wishes/$wishId/reserve');

      // Update wish in flat list
      final wishIndex = _allWishes.indexWhere((w) => w.id == wishId);
      if (wishIndex != -1) {
        final updatedWish = Wish.fromJson(response['wish'] ?? response);
        _allWishes[wishIndex] = updatedWish;
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error unreserving wish: $e');
      // Don't set _error - let the caller handle the error with a snackbar
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

      // Step 4: Update wishlist in cache
      final wishlistIndex = _wishlists.indexWhere((w) => w.id == wishlistId);
      if (wishlistIndex != -1) {
        final updatedWishlist = _wishlists[wishlistIndex].copyWith(
          coverImageUrl: publicUrl,
        );
        _wishlists[wishlistIndex] = updatedWishlist;
        notifyListeners();
      }

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

      // Update wishlist in cache
      final wishlistIndex = _wishlists.indexWhere((w) => w.id == wishlistId);
      if (wishlistIndex != -1) {
        final updatedWishlist = _wishlists[wishlistIndex].copyWith(
          coverImageUrl: null,
        );
        _wishlists[wishlistIndex] = updatedWishlist;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = 'Remove cover image failed: $e';
      debugPrint('❌ WishlistService: Error removing cover image: $e');
      notifyListeners();
      return false;
    }
  }
}
