import 'package:flutter/foundation.dart';
import '../models/friend.dart';
import 'api_service.dart';

class FriendsService {
  static final FriendsService _instance = FriendsService._internal();
  factory FriendsService() => _instance;
  FriendsService._internal();

  final ApiService _apiService = ApiService();

  // Search users
  Future<List<UserSearchResult>> searchUsers(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      debugPrint('🔍 FriendsService: Searching users with query: $query');
      
      final response = await _apiService.get(
        '/search/users',
        queryParameters: {
          'q': query,
          'page': page,
          'limit': limit,
        },
      );

      final List<dynamic> usersData = response['users'] ?? [];
      final users = usersData.map((userData) => UserSearchResult.fromJson(userData)).toList();
      
      debugPrint('🔍 FriendsService: Found ${users.length} users');
      return users;
    } catch (e) {
      debugPrint('❌ FriendsService: Error searching users: $e');
      rethrow;
    }
  }

  // Get friends list
  Future<List<Friend>> getFriends({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      debugPrint('👥 FriendsService: Getting friends list');
      
      final response = await _apiService.get(
        '/friends',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      final List<dynamic> friendsData = response['friends'] ?? [];
      final friends = friendsData.map((friendData) => Friend.fromJson(friendData)).toList();
      
      debugPrint('👥 FriendsService: Found ${friends.length} friends');
      return friends;
    } catch (e) {
      debugPrint('❌ FriendsService: Error getting friends: $e');
      rethrow;
    }
  }

  // Send friend request
  Future<void> sendFriendRequest(String userId) async {
    try {
      debugPrint('📤 FriendsService: Sending friend request to user: $userId');
      
      await _apiService.post('/friends/request', {
        'user_id': userId,
      });
      
      debugPrint('📤 FriendsService: Friend request sent successfully');
    } catch (e) {
      debugPrint('❌ FriendsService: Error sending friend request: $e');
      rethrow;
    }
  }

  // Respond to friend request
  Future<void> respondToFriendRequest(String requestId, String action) async {
    try {
      debugPrint('📩 FriendsService: Responding to friend request $requestId with action: $action');
      
      await _apiService.post('/friends/requests/$requestId/respond', {
        'action': action,
      });
      
      debugPrint('📩 FriendsService: Friend request response sent successfully');
    } catch (e) {
      debugPrint('❌ FriendsService: Error responding to friend request: $e');
      rethrow;
    }
  }

  // Get friend requests
  Future<List<FriendRequest>> getFriendRequests({
    String type = 'received',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      debugPrint('📬 FriendsService: Getting $type friend requests');
      
      final response = await _apiService.get(
        '/friends/requests',
        queryParameters: {
          'type': type,
          'page': page,
          'limit': limit,
        },
      );

      final List<dynamic> requestsData = response['requests'] ?? [];
      final requests = requestsData.map((requestData) => FriendRequest.fromJson(requestData)).toList();
      
      debugPrint('📬 FriendsService: Found ${requests.length} $type friend requests');
      return requests;
    } catch (e) {
      debugPrint('❌ FriendsService: Error getting friend requests: $e');
      rethrow;
    }
  }

  // Get activity feed
  Future<List<Activity>> getActivityFeed({
    String filter = 'friends',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      debugPrint('📰 FriendsService: Getting activity feed with filter: $filter');
      
      final response = await _apiService.get(
        '/feed',
        queryParameters: {
          'filter': filter,
          'page': page,
          'limit': limit,
        },
      );

      final List<dynamic> activitiesData = response['activities'] ?? [];
      final activities = activitiesData.map((activityData) => Activity.fromJson(activityData)).toList();
      
      debugPrint('📰 FriendsService: Found ${activities.length} activities');
      return activities;
    } catch (e) {
      debugPrint('❌ FriendsService: Error getting activity feed: $e');
      rethrow;
    }
  }

  // Get user profile
  Future<UserProfile> getUserProfile(String userId) async {
    try {
      debugPrint('👤 FriendsService: Getting user profile for: $userId');
      
      final response = await _apiService.get('/users/$userId');
      final userData = response['user'];
      
      final profile = UserProfile.fromJson(userData);
      debugPrint('👤 FriendsService: Got profile for: ${profile.username}');
      return profile;
    } catch (e) {
      debugPrint('❌ FriendsService: Error getting user profile: $e');
      rethrow;
    }
  }

  // Accept friend request
  Future<void> acceptFriendRequest(String requestId) async {
    await respondToFriendRequest(requestId, 'accept');
  }

  // Decline friend request
  Future<void> declineFriendRequest(String requestId) async {
    await respondToFriendRequest(requestId, 'decline');
  }

  // Block friend request
  Future<void> blockFriendRequest(String requestId) async {
    await respondToFriendRequest(requestId, 'block');
  }
}