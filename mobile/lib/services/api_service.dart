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
    final baseUrl = 'https://openai-rewrite.onrender.com/jinnie/v1';

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }

          // Only log in debug mode to prevent data leakage in production
          if (kDebugMode) {
            debugPrint(
              '🚀 API REQUEST[${options.method}] => ${baseUrl}${options.path}',
            );

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
            debugPrint(
              '✅ API RESPONSE[${response.statusCode}] => ${response.requestOptions.path}',
            );
            // Only log response data in debug builds (contains user data)
            debugPrint('✅ Response Data: ${response.data}');
          }
          handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            debugPrint(
              '❌ API ERROR[${error.response?.statusCode}] => ${error.requestOptions.path}',
            );
            debugPrint('❌ Error Type: ${error.type}');
            debugPrint('❌ Error Message: ${error.message}');
            if (error.response?.data != null) {
              debugPrint('❌ Error Response Data: ${error.response?.data}');
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  bool get hasAuthToken => _authToken != null;

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
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
    String? wishlistId, { // Optional - null for unsorted wishes
    String? fileExtension,
    String contentType = 'image/jpeg',
  }) async {
    try {
      final response = await post('/upload/wish-image', {
        if (wishlistId != null) 'wishlistId': wishlistId,
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
  Future<Map<String, dynamic>?> getWishlistCoverUploadUrl(
    String wishlistId,
  ) async {
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
      debugPrint('🖼️ API: URL: $uploadUrl');
      debugPrint('🖼️ API: Content-Type: $contentType');

      final bytes = await imageFile.readAsBytes();
      debugPrint('🖼️ API: File size: ${bytes.length} bytes');

      final dio = Dio();
      final response = await dio.put(
        uploadUrl,
        data: bytes,
        options: Options(
          headers: {'Content-Type': contentType},
          validateStatus: (status) => true, // Don't throw on any status
        ),
      );

      debugPrint('🖼️ API: Response status: ${response.statusCode}');
      debugPrint('🖼️ API: Response data: ${response.data}');

      if (response.statusCode == 200) {
        debugPrint('✅ API: Image uploaded to presigned URL successfully');
        return true;
      } else {
        debugPrint(
          '❌ API: Upload to presigned URL failed: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ API: Error uploading to presigned URL: $e');
      if (e is DioException) {
        debugPrint('❌ API: DioException response: ${e.response?.data}');
      }
      return false;
    }
  }

  /// Update wishlist cover image URL
  Future<Map<String, dynamic>?> updateWishlistCoverImage(
    String wishlistId,
    String coverImageUrl,
  ) async {
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

  /// Upload wishlist cover image and return the public URL
  Future<String?> uploadWishlistCoverImage({
    required File imageFile,
  }) async {
    try {
      final pathSegments = imageFile.path.split('.');
      final extension = pathSegments.length > 1 ? pathSegments.last : 'jpg';

      final normalizedExtension = extension.toLowerCase();
      String resolvedContentType;
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

      debugPrint('🖼️ API: Getting upload URL for wishlist cover');

      // Get presigned upload URL from backend
      final uploadConfig = await post('/upload/wishlist-cover', {
        'fileExtension': normalizedExtension,
        'contentType': resolvedContentType,
      });

      final uploadUrl = uploadConfig?['uploadUrl'] as String?;
      final publicUrl = uploadConfig?['publicUrl'] as String?;

      if (uploadUrl == null || publicUrl == null) {
        debugPrint('❌ API: Upload config missing URL fields');
        return null;
      }

      debugPrint('🖼️ API: Uploading wishlist cover to presigned URL');

      final success = await uploadImageToPresignedUrl(
        uploadUrl,
        imageFile,
        contentType: resolvedContentType,
      );

      if (success) {
        debugPrint('✅ API: Wishlist cover uploaded successfully');
        return publicUrl;
      } else {
        debugPrint('❌ API: Failed to upload wishlist cover to R2');
        return null;
      }
    } catch (e) {
      debugPrint('❌ API: Failed to upload wishlist cover: $e');
      return null;
    }
  }

  /// Upload avatar image and return the public URL
  Future<String?> uploadAvatarImage({
    required File imageFile,
  }) async {
    try {
      final pathSegments = imageFile.path.split('.');
      final extension = pathSegments.length > 1 ? pathSegments.last : 'jpg';

      final normalizedExtension = extension.toLowerCase();
      String resolvedContentType;
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

      debugPrint('👤 API: Getting upload URL for avatar');

      // Get presigned upload URL from backend
      final uploadConfig = await post('/upload/avatar', {
        'fileExtension': normalizedExtension,
        'contentType': resolvedContentType,
      });

      final uploadUrl = uploadConfig?['uploadUrl'] as String?;
      final publicUrl = uploadConfig?['publicUrl'] as String?;

      if (uploadUrl == null || publicUrl == null) {
        debugPrint('❌ API: Upload config missing URL fields');
        return null;
      }

      debugPrint('👤 API: Uploading avatar to presigned URL');

      final success = await uploadImageToPresignedUrl(
        uploadUrl,
        imageFile,
        contentType: resolvedContentType,
      );

      if (success) {
        debugPrint('✅ API: Avatar uploaded successfully');
        return publicUrl;
      } else {
        debugPrint('❌ API: Failed to upload avatar to R2');
        return null;
      }
    } catch (e) {
      debugPrint('❌ API: Failed to upload avatar: $e');
      return null;
    }
  }

  /// Upload wish image and return the public URL
  Future<String?> uploadWishImage({
    required File imageFile,
    String? wishlistId, // Optional - null for unsorted wishes
  }) async {
    try {
      debugPrint('📸 API: uploadWishImage called');
      debugPrint('📸 API: Image file path: ${imageFile.path}');
      debugPrint('📸 API: Wishlist ID: $wishlistId');

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

      debugPrint('📸 API: File extension: $normalizedExtension');
      debugPrint('📸 API: Content type: $resolvedContentType');

      debugPrint('📸 API: Getting upload URL...');
      final uploadConfig = await getWishImageUploadUrl(
        wishlistId, // Can be null now
        fileExtension: normalizedExtension,
        contentType: resolvedContentType,
      );

      debugPrint('📸 API: Upload config received: $uploadConfig');

      final uploadUrl = uploadConfig?['uploadUrl'] as String?;
      final publicUrl = uploadConfig?['publicUrl'] as String?;

      debugPrint('📸 API: Upload URL: $uploadUrl');
      debugPrint('📸 API: Public URL: $publicUrl');

      if (uploadUrl == null || publicUrl == null) {
        debugPrint('❌ API: Upload config missing URL fields');
        debugPrint('❌ API: uploadUrl is null: ${uploadUrl == null}');
        debugPrint('❌ API: publicUrl is null: ${publicUrl == null}');
        return null;
      }

      debugPrint('📸 API: Uploading to presigned URL...');
      final success = await uploadImageToPresignedUrl(
        uploadUrl,
        imageFile,
        contentType: resolvedContentType,
      );

      debugPrint('📸 API: Upload success: $success');

      if (success) {
        debugPrint('✅ API: Image uploaded successfully, returning public URL: $publicUrl');
        return publicUrl;
      } else {
        debugPrint('❌ API: Upload failed, returning null');
        return null;
      }
    } catch (e) {
      debugPrint('❌ API: Failed to upload wish image: $e');
      debugPrint('❌ API: Error type: ${e.runtimeType}');
      debugPrint('❌ API: Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  /// Enhanced Onboarding API Methods

  /// Check if username is available
  Future<Map<String, dynamic>?> checkUsernameAvailability(
    String username,
  ) async {
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
    List<String>? shoppingInterests,
    Map<String, dynamic>? notificationPreferences,
    Map<String, dynamic>? privacySettings,
    bool? isProfilePublic,
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
      if (shoppingInterests != null) {
        data['shopping_interests'] = shoppingInterests;
      }
      if (notificationPreferences != null) {
        data['notification_preferences'] = notificationPreferences;
      }
      if (privacySettings != null) data['privacy_settings'] = privacySettings;
      if (isProfilePublic != null) data['is_profile_public'] = isProfilePublic;

      final response = await patch('/users/profile', data);
      debugPrint('✅ API: Profile updated successfully');

      return response as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('❌ API: Error updating profile: $e');
      return null;
    }
  }

  /// Privacy-first friend discovery: Send only phone numbers, no contact names
  Future<Map<String, dynamic>?> findFriendsByPhoneNumbers(
    List<String> phoneNumbers,
  ) async {
    try {
      debugPrint(
        '🔍 API: Finding friends by ${phoneNumbers.length} phone numbers (privacy-first)',
      );

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

  /// Update FCM token for push notifications
  Future<bool> updateFCMToken(String token) async {
    try {
      debugPrint('🔔 API: Updating FCM token');
      final response = await post('/auth/fcm-token', {'fcm_token': token});

      if (response != null) {
        debugPrint('✅ API: FCM token updated successfully');
        return true;
      } else {
        debugPrint('❌ API: FCM token update failed - null response');
        return false;
      }
    } catch (e) {
      debugPrint('❌ API: FCM token update error: $e');
      return false;
    }
  }

  /// Scrape URL metadata for smart wish creation
  Future<UrlMetadataResponse> scrapeUrl(String url) async {
    try {
      debugPrint('🔍 API: Scraping URL: $url');

      final response = await post('/wishes/scrape-url', {'url': url});

      if (response != null && response['success'] == true) {
        debugPrint('✅ API: URL scraped successfully');
        return UrlMetadataResponse.fromJson(response);
      } else {
        debugPrint('❌ API: URL scraping failed');
        return UrlMetadataResponse(
          success: false,
          error: response?['error']?['message'] ?? 'Failed to scrape URL',
        );
      }
    } catch (e) {
      debugPrint('❌ API: URL scraping error: $e');
      return UrlMetadataResponse(
        success: false,
        error: e.toString(),
      );
    }
  }

  // Feed/Activity related API methods

  /// Get activity feed for the current user
  /// [filter] can be 'friends', 'all', or 'own'
  /// [page] and [limit] control pagination
  Future<ActivityFeedResponse?> getActivityFeed({
    String filter = 'friends',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      debugPrint('📰 API: Fetching activity feed (filter: $filter, page: $page)');

      final response = await get('/feed', queryParameters: {
        'filter': filter,
        'page': page.toString(),
        'limit': limit.toString(),
      });

      if (response != null) {
        debugPrint('✅ API: Activity feed retrieved successfully');
        return ActivityFeedResponse.fromJson(response);
      } else {
        debugPrint('❌ API: Activity feed returned null');
        return null;
      }
    } catch (e) {
      debugPrint('❌ API: Error fetching activity feed: $e');
      return null;
    }
  }

  /// Search for users by username
  Future<UserSearchResponse?> searchUsers(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      debugPrint('🔍 API: Searching users with query: $query');

      final response = await get('/search/users', queryParameters: {
        'q': query,
        'page': page.toString(),
        'limit': limit.toString(),
      });

      if (response != null) {
        debugPrint('✅ API: User search completed successfully');
        return UserSearchResponse.fromJson(response);
      } else {
        debugPrint('❌ API: User search returned null');
        return null;
      }
    } catch (e) {
      debugPrint('❌ API: Error searching users: $e');
      return null;
    }
  }

  /// Get friends list
  Future<FriendsResponse?> getFriends({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      debugPrint('👥 API: Fetching friends list (page: $page)');

      final response = await get('/friends', queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });

      if (response != null) {
        debugPrint('✅ API: Friends list retrieved successfully');
        return FriendsResponse.fromJson(response);
      } else {
        debugPrint('❌ API: Friends list returned null');
        return null;
      }
    } catch (e) {
      debugPrint('❌ API: Error fetching friends: $e');
      return null;
    }
  }

  /// Send a friend request to a user
  Future<bool> sendFriendRequest(String userId) async {
    try {
      debugPrint('📤 API: Sending friend request to user: $userId');

      final response = await post('/friends/request', {
        'user_id': userId,
      });

      if (response != null) {
        debugPrint('✅ API: Friend request sent successfully');
        return true;
      } else {
        debugPrint('❌ API: Friend request failed - null response');
        return false;
      }
    } catch (e) {
      debugPrint('❌ API: Error sending friend request: $e');
      return false;
    }
  }
}

/// Response model for URL scraping
class UrlMetadataResponse {
  final bool success;
  final UrlMetadata? metadata;
  final String? error;

  UrlMetadataResponse({
    required this.success,
    this.metadata,
    this.error,
  });

  factory UrlMetadataResponse.fromJson(Map<String, dynamic> json) {
    return UrlMetadataResponse(
      success: json['success'] ?? false,
      metadata: json['metadata'] != null
          ? UrlMetadata.fromJson(json['metadata'])
          : null,
      error: json['error']?['message'],
    );
  }
}

/// URL metadata extracted from scraping
class UrlMetadata {
  final String? title;
  final String? description;
  final String? image;
  final double? price;
  final String? currency;
  final String? brand;
  final String source;

  UrlMetadata({
    this.title,
    this.description,
    this.image,
    this.price,
    this.currency,
    this.brand,
    required this.source,
  });

  factory UrlMetadata.fromJson(Map<String, dynamic> json) {
    return UrlMetadata(
      title: json['title'],
      description: json['description'],
      image: json['image'],
      price: json['price']?.toDouble(),
      currency: json['currency'] ?? 'USD',
      brand: json['brand'],
      source: json['source'] ?? 'unknown',
    );
  }
}

// Feed/Activity related models

/// Activity feed response
class ActivityFeedResponse {
  final List<FeedActivity> activities;
  final String filter;
  final FeedPagination pagination;

  ActivityFeedResponse({
    required this.activities,
    required this.filter,
    required this.pagination,
  });

  factory ActivityFeedResponse.fromJson(Map<String, dynamic> json) {
    return ActivityFeedResponse(
      activities: (json['activities'] as List?)
              ?.map((a) => FeedActivity.fromJson(a))
              .toList() ??
          [],
      filter: json['filter'] ?? 'friends',
      pagination: FeedPagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

/// Single activity in the feed
class FeedActivity {
  final String id;
  final String activityType;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final String username;
  final String? fullName;
  final String? avatarUrl;

  FeedActivity({
    required this.id,
    required this.activityType,
    required this.data,
    required this.createdAt,
    required this.username,
    this.fullName,
    this.avatarUrl,
  });

  factory FeedActivity.fromJson(Map<String, dynamic> json) {
    return FeedActivity(
      id: json['id'],
      activityType: json['activity_type'],
      data: json['data'] ?? {},
      createdAt: DateTime.parse(json['created_at']),
      username: json['username'],
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
    );
  }
}

/// Feed pagination info
class FeedPagination {
  final int page;
  final int limit;
  final int total;
  final bool hasMore;

  FeedPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
  });

  factory FeedPagination.fromJson(Map<String, dynamic> json) {
    return FeedPagination(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      hasMore: json['hasMore'] ?? false,
    );
  }
}

/// User search response
class UserSearchResponse {
  final List<UserSearchResult> users;
  final SearchPagination pagination;

  UserSearchResponse({
    required this.users,
    required this.pagination,
  });

  factory UserSearchResponse.fromJson(Map<String, dynamic> json) {
    return UserSearchResponse(
      users: (json['users'] as List?)
              ?.map((u) => UserSearchResult.fromJson(u))
              .toList() ??
          [],
      pagination: SearchPagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

/// Single user in search results
class UserSearchResult {
  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;
  final int wishlistCount;
  final String? friendshipStatus;

  UserSearchResult({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
    this.bio,
    required this.wishlistCount,
    this.friendshipStatus,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'],
      username: json['username'],
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      wishlistCount: json['wishlist_count'] ?? 0,
      friendshipStatus: json['friendship_status'],
    );
  }
}

/// Search pagination info
class SearchPagination {
  final int page;
  final int limit;
  final int total;
  final int pages;

  SearchPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory SearchPagination.fromJson(Map<String, dynamic> json) {
    return SearchPagination(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      pages: json['pages'] ?? 1,
    );
  }
}

/// Friends list response
class FriendsResponse {
  final List<Friend> friends;
  final FriendsPagination pagination;

  FriendsResponse({
    required this.friends,
    required this.pagination,
  });

  factory FriendsResponse.fromJson(Map<String, dynamic> json) {
    return FriendsResponse(
      friends:
          (json['friends'] as List?)?.map((f) => Friend.fromJson(f)).toList() ??
              [],
      pagination: FriendsPagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

/// Single friend entry
class Friend {
  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final DateTime friendsSince;
  final int wishlistCount;

  Friend({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
    required this.friendsSince,
    required this.wishlistCount,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'],
      username: json['username'],
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      friendsSince: DateTime.parse(json['friends_since']),
      wishlistCount: json['wishlist_count'] ?? 0,
    );
  }
}

/// Friends pagination info
class FriendsPagination {
  final int page;
  final int limit;
  final int total;
  final int pages;

  FriendsPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory FriendsPagination.fromJson(Map<String, dynamic> json) {
    return FriendsPagination(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      pages: json['pages'] ?? 1,
    );
  }
}
