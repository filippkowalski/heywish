import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PublicApiService {
  late final Dio _dio;
  static const String baseUrl = 'http://localhost:3000/api'; // Change for production
  String? _reserverId;
  
  PublicApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    
    _initReserverId();
  }
  
  Future<void> _initReserverId() async {
    final prefs = await SharedPreferences.getInstance();
    _reserverId = prefs.getString('heywish_reserver_id');
  }
  
  // Get public wishlist by share token
  Future<Map<String, dynamic>> getPublicWishlist(String token) async {
    try {
      final response = await _dio.get(
        '/public/wishlists/$token',
        options: Options(
          headers: _reserverId != null ? {'X-Reserver-Id': _reserverId} : {},
        ),
      );
      return response.data;
    } catch (e) {
      print('Error fetching public wishlist: $e');
      rethrow;
    }
  }
  
  // Reserve an item
  Future<Map<String, dynamic>> reserveItem(
    String token,
    String wishId, {
    String? reserverName,
    String? reserverEmail,
  }) async {
    try {
      // Include existing reserver ID if we have one
      final headers = <String, dynamic>{};
      if (_reserverId != null) {
        headers['X-Reserver-Id'] = _reserverId;
      }
      
      final response = await _dio.post(
        '/public/wishlists/$token',
        data: {
          'wishId': wishId,
          'reserverName': reserverName ?? 'Anonymous',
          'reserverEmail': reserverEmail,
        },
        options: Options(headers: headers),
      );
      
      // Save the reserver ID for future requests
      if (response.data['reserverId'] != null) {
        _reserverId = response.data['reserverId'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('heywish_reserver_id', _reserverId!);
      }
      
      return response.data;
    } catch (e) {
      print('Error reserving item: $e');
      rethrow;
    }
  }
  
  // Unreserve an item
  Future<void> unreserveItem(String token, String wishId) async {
    if (_reserverId == null) {
      throw Exception('No reserver ID found');
    }
    
    try {
      await _dio.delete(
        '/public/wishlists/$token',
        queryParameters: {
          'wishId': wishId,
          'reserverId': _reserverId,
        },
      );
    } catch (e) {
      print('Error unreserving item: $e');
      rethrow;
    }
  }
  
  // Check if an item was reserved by the current user
  bool isReservedByMe(Map<String, dynamic> wish) {
    return wish['reserved_by_viewer'] == true;
  }
}