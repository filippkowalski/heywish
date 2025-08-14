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
      print('📋 WishlistService: Making API call to /wishlists');
      final response = await _apiService.get('/wishlists');
      print('📋 WishlistService: API response received: $response');
      
      if (response != null && response['wishlists'] != null) {
        _wishlists = (response['wishlists'] as List)
            .map((json) => Wishlist.fromJson(json))
            .toList();
        print('📋 WishlistService: Parsed ${_wishlists.length} wishlists');
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
  
  Future<void> fetchWishlist(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.get('/wishlists/$id');
      _currentWishlist = Wishlist.fromJson(response['wishlist']);
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
      
      // Refresh wishlists to get updated data
      await fetchWishlists();
      
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
      
      // Refresh both lists and current wishlist
      await fetchWishlists();
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
      
      // Refresh the current wishlist
      if (_currentWishlist?.id == wishlistId) {
        print('🎁 WishlistService: Refreshing wishlist $wishlistId');
        await fetchWishlist(wishlistId);
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
      
      // Refresh the current wishlist
      if (_currentWishlist != null) {
        await fetchWishlist(_currentWishlist!.id);
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
      
      // Refresh the current wishlist
      if (_currentWishlist != null) {
        await fetchWishlist(_currentWishlist!.id);
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
      
      // Refresh the current wishlist
      if (_currentWishlist != null) {
        await fetchWishlist(_currentWishlist!.id);
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
      
      // Refresh the current wishlist
      if (_currentWishlist != null) {
        await fetchWishlist(_currentWishlist!.id);
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