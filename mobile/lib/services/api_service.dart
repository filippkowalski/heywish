import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:io';

class ApiService {
  late final Dio _dio;
  String? _authToken;
  
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() => _instance;
  
  ApiService._internal() {
    // Use production URL for all environments
    final baseUrl = 'https://openai-rewrite.onrender.com/heywish/v1';
        
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        
        // Only log in debug mode to prevent data leakage in production
        if (kDebugMode) {
          debugPrint('🚀 API REQUEST[${options.method}] => ${baseUrl}${options.path}');
          
          // Log headers but mask sensitive data
          final sanitizedHeaders = Map<String, dynamic>.from(options.headers);
          if (sanitizedHeaders.containsKey('Authorization')) {
            sanitizedHeaders['Authorization'] = 'Bearer [REDACTED]';
          }
          debugPrint('🚀 Headers: $sanitizedHeaders');
          
          // Only log request data in debug builds (contains sensitive info)
          if (options.data != null) {
            debugPrint('🚀 Request Data: ${options.data}');
          }
        }
        
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint('✅ API RESPONSE[${response.statusCode}] => ${response.requestOptions.path}');
          // Only log response data in debug builds (contains user data)
          debugPrint('✅ Response Data: ${response.data}');
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          debugPrint('❌ API ERROR[${error.response?.statusCode}] => ${error.requestOptions.path}');
          debugPrint('❌ Error Type: ${error.type}');
          debugPrint('❌ Error Message: ${error.message}');
          if (error.response?.data != null) {
            debugPrint('❌ Error Response Data: ${error.response?.data}');
          }
        }
        handler.next(error);
      },
    ));
  }
  
  void setAuthToken(String? token) {
    _authToken = token;
  }
  
  void clearAuthToken() {
    _authToken = null;
  }

  bool get hasAuthToken => _authToken != null;
  
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<dynamic> post(String path, dynamic data) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<dynamic> put(String path, dynamic data) async {
    try {
      final response = await _dio.put(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<dynamic> patch(String path, dynamic data) async {
    try {
      final response = await _dio.patch(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<dynamic> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>?> getWishImageUploadUrl(
    String wishlistId, {
    String? fileExtension,
    String contentType = 'image/jpeg',
  }) async {
    try {
      final response = await post('/upload/wish-image', {
        'wishlistId': wishlistId,
        if (fileExtension != null) 'fileExtension': fileExtension,
        'contentType': contentType,
      });

      return response as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('❌ API: Error getting wish image upload URL: $e');
      return null;
    }
  }

  /// Get presigned upload URL for wishlist cover image
  Future<Map<String, dynamic>?> getWishlistCoverUploadUrl(String wishlistId) async {
    try {
      debugPrint('🖼️ API: Getting wishlist cover upload URL for $wishlistId');
      
      final response = await post('/upload/wishlist-cover', {
        'wishlistId': wishlistId,
      });
      
      debugPrint('✅ API: Got wishlist cover upload URL');
      return response as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('❌ API: Error getting wishlist cover upload URL: $e');
      return null;
    }
  }

  /// Upload image directly to presigned URL
  Future<bool> uploadImageToPresignedUrl(
    String uploadUrl,
    File imageFile, {
    String contentType = 'image/jpeg',
  }) async {
    try {
      debugPrint('🖼️ API: Uploading to presigned URL');
      
      final bytes = await imageFile.readAsBytes();
      
      final dio = Dio();
      final response = await dio.put(
        uploadUrl,
        data: bytes,
        options: Options(
          headers: {
            'Content-Type': contentType,
          },
        ),
      );
      
      if (response.statusCode == 200) {
        debugPrint('✅ API: Image uploaded to presigned URL successfully');
        return true;
      } else {
        debugPrint('❌ API: Upload to presigned URL failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ API: Error uploading to presigned URL: $e');
      return false;
    }
  }

  /// Update wishlist cover image URL
  Future<Map<String, dynamic>?> updateWishlistCoverImage(String wishlistId, String coverImageUrl) async {
    try {
      debugPrint('🖼️ API: Updating wishlist cover image for $wishlistId');
      
      final response = await put('/wishlists/$wishlistId/cover-image', {
        'coverImageUrl': coverImageUrl,
      });
      
      debugPrint('✅ API: Wishlist cover image updated');
      return response as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('❌ API: Error updating wishlist cover image: $e');
      return null;
    }
  }

  /// Upload wish image and return the public URL
  Future<String?> uploadWishImage({
    required File imageFile,
    required String wishlistId,
  }) async {
    try {
      final pathSegments = imageFile.path.split('.');
      final extension = pathSegments.length > 1 ? pathSegments.last : 'jpg';
      final contentType = 'image/jpeg';

      final normalizedExtension = extension.toLowerCase();
      String resolvedContentType = contentType;
      switch (normalizedExtension) {
        case 'png':
          resolvedContentType = 'image/png';
          break;
        case 'webp':
          resolvedContentType = 'image/webp';
          break;
        case 'jpeg':
        case 'jpg':
        default:
          resolvedContentType = 'image/jpeg';
      }

      final uploadConfig = await getWishImageUploadUrl(
        wishlistId,
        fileExtension: normalizedExtension,
        contentType: resolvedContentType,
      );

      final uploadUrl = uploadConfig?['uploadUrl'] as String?;
      final publicUrl = uploadConfig?['publicUrl'] as String?;

      if (uploadUrl == null || publicUrl == null) {
        debugPrint('❌ API: Upload config missing URL fields');
        return null;
      }

      final success = await uploadImageToPresignedUrl(
        uploadUrl,
        imageFile,
        contentType: resolvedContentType,
      );

      return success ? publicUrl : null;
    } catch (e) {
      debugPrint('❌ API: Failed to upload wish image: $e');
      return null;
    }
  }

  /// Enhanced Onboarding API Methods

  /// Check if username is available
  Future<Map<String, dynamic>?> checkUsernameAvailability(String username) async {
    try {
      debugPrint('🔍 API: Checking username availability for: $username');

      final response = await get('/auth/check-username/$username');
      if (kDebugMode) {
        debugPrint('✅ API: Username check response: $response');
      }

      return response as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('❌ API: Error checking username: $e');
      return null;
    }
  }

  /// Check if user exists by email
  Future<Map<String, dynamic>?> checkEmailExists() async {
    try {
      debugPrint('📧 API: Checking if email exists in database');

      final response = await get('/auth/check-email');
      if (kDebugMode) {
        debugPrint('✅ API: Email check response: $response');
      }

      return response as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('❌ API: Error checking email: $e');
      return null;
    }
  }

  /// Update user profile with onboarding data
  Future<Map<String, dynamic>?> updateUserProfile({
    String? username,
    String? fullName,
    String? bio,
    String? birthdate,
    String? gender,
    String? phoneNumber,
    Map<String, dynamic>? notificationPreferences,
    Map<String, dynamic>? privacySettings,
  }) async {
    try {
      debugPrint('👤 API: Updating user profile');
      
      final data = <String, dynamic>{};
      if (username != null) data['username'] = username;
      if (fullName != null) data['full_name'] = fullName;
      if (bio != null) data['bio'] = bio;
      if (birthdate != null) data['birthdate'] = birthdate;
      if (gender != null) data['gender'] = gender;
      if (phoneNumber != null) data['phone_number'] = phoneNumber;
      if (notificationPreferences != null) data['notification_preferences'] = notificationPreferences;
      if (privacySettings != null) data['privacy_settings'] = privacySettings;
      
      final response = await patch('/users/profile', data);
      debugPrint('✅ API: Profile updated successfully');
      
      return response as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('❌ API: Error updating profile: $e');
      return null;
    }
  }

  /// Privacy-first friend discovery: Send only phone numbers, no contact names
  Future<Map<String, dynamic>?> findFriendsByPhoneNumbers(List<String> phoneNumbers) async {
    try {
      debugPrint('🔍 API: Finding friends by ${phoneNumbers.length} phone numbers (privacy-first)');
      
      final response = await post('/friends/find-by-phone-numbers', {
        'phone_numbers': phoneNumbers,
      });
      
      debugPrint('✅ API: Friend suggestions retrieved');
      return response as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('❌ API: Error finding friends: $e');
      return null;
    }
  }
  
  String _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'errors.timeout'.tr();
      
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'An error occurred';
        
        switch (statusCode) {
          case 400:
            return 'errors.validation_required'.tr();
          case 401:
            return 'errors.unauthorized'.tr();
          case 403:
            return 'errors.forbidden'.tr();
          case 404:
            return 'errors.not_found'.tr();
          case 500:
            return 'errors.server_error'.tr();
          default:
            return message;
        }
      
      case DioExceptionType.cancel:
        return 'errors.cancelled'.tr();
      
      case DioExceptionType.unknown:
        if (error.error?.toString().contains('SocketException') ?? false) {
          return 'errors.network_error'.tr();
        }
        return 'errors.unknown'.tr();
      
      default:
        return 'errors.unknown'.tr();
    }
  }

  /// Delete user account and all associated data
  Future<bool> deleteAccount() async {
    try {
      debugPrint('🗑️ API: Deleting user account');
      final response = await delete('/auth/delete-account');
      
      if (response != null) {
        debugPrint('✅ API: Account deleted successfully');
        return true;
      } else {
        debugPrint('❌ API: Account deletion failed - null response');
        return false;
      }
    } catch (e) {
      debugPrint('❌ API: Account deletion error: $e');
      return false;
    }
  }
}
