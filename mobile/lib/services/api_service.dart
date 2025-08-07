import 'package:dio/dio.dart';
import 'auth_service.dart';

class ApiService {
  final AuthService _authService;
  late final Dio _dio;
  
  static const String baseUrl = 'http://localhost:3000/api'; // Change for production
  
  ApiService(this._authService) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    
    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _authService.getIdToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }
  
  // Wishlists
  Future<List<dynamic>> getWishlists() async {
    try {
      final response = await _dio.get('/wishlists');
      return response.data['wishlists'];
    } catch (e) {
      print('Error fetching wishlists: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> getWishlist(String id) async {
    try {
      final response = await _dio.get('/wishlists/$id');
      return response.data;
    } catch (e) {
      print('Error fetching wishlist: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> createWishlist(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/wishlists', data: data);
      return response.data;
    } catch (e) {
      print('Error creating wishlist: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> updateWishlist(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/wishlists/$id', data: data);
      return response.data;
    } catch (e) {
      print('Error updating wishlist: $e');
      rethrow;
    }
  }
  
  Future<void> deleteWishlist(String id) async {
    try {
      await _dio.delete('/wishlists/$id');
    } catch (e) {
      print('Error deleting wishlist: $e');
      rethrow;
    }
  }
  
  // Wishes
  Future<Map<String, dynamic>> addWish(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/wishes', data: data);
      return response.data;
    } catch (e) {
      print('Error adding wish: $e');
      rethrow;
    }
  }
  
  Future<void> deleteWish(String id) async {
    try {
      await _dio.delete('/wishes/$id');
    } catch (e) {
      print('Error deleting wish: $e');
      rethrow;
    }
  }
  
  Future<void> reserveWish(String id) async {
    try {
      await _dio.post('/wishes/$id/reserve');
    } catch (e) {
      print('Error reserving wish: $e');
      rethrow;
    }
  }
  
  Future<void> unreserveWish(String id) async {
    try {
      await _dio.delete('/wishes/$id/reserve');
    } catch (e) {
      print('Error unreserving wish: $e');
      rethrow;
    }
  }
  
  // Scraping
  Future<Map<String, dynamic>> scrapeProduct(String url) async {
    try {
      final response = await _dio.post('/scrape', data: {'url': url});
      return response.data['product'];
    } catch (e) {
      print('Error scraping product: $e');
      rethrow;
    }
  }
}