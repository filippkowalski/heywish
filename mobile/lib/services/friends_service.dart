import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/friend.dart';
import 'api_service.dart' hide Friend, UserSearchResult;

class FriendsService extends ChangeNotifier {
  // Remove singleton pattern - use Provider for dependency injection
  final ApiService _apiService;

  FriendsService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  // State management
  List<Friend> _friends = [];
  List<FriendRequest> _friendRequests = [];
  List<FriendRequest> _sentRequests = [];
  List<Activity> _activities = [];
  bool _isLoadingFriends = false;
  bool _isLoadingRequests = false;
  bool _isLoadingActivities = false;
  String? _error;
  Future<void>? _loadAllDataFuture;

  final Map<String, Future<List<Friend>>> _friendsRequestsInFlight = {};
  final Set<String> _friendsLoadingKeys = {};
  final Map<String, Future<List<FriendRequest>>> _friendRequestsInFlight = {};
  final Set<String> _friendRequestLoadingKeys = {};

  // Cache management
  DateTime? _lastLoadAllDataTime;
  final Map<String, DateTime> _friendsCacheTime = {};
  final Map<String, DateTime> _friendRequestsCacheTime = {};
  static const _cacheDuration = Duration(seconds: 30);

  // Getters
  List<Friend> get friends => _friends;
  List<FriendRequest> get friendRequests => _friendRequests;
  List<FriendRequest> get sentRequests => _sentRequests;
  List<Activity> get activities => _activities;
  bool get isLoadingFriends => _isLoadingFriends;
  bool get isLoadingRequests => _isLoadingRequests;
  bool get isLoadingActivities => _isLoadingActivities;
  String? get error => _error;
  int get pendingRequestsCount => _friendRequests.length;

  // Helper to update state and notify listeners
  void _updateState({
    List<Friend>? friends,
    List<FriendRequest>? friendRequests,
    List<FriendRequest>? sentRequests,
    List<Activity>? activities,
    bool? isLoadingFriends,
    bool? isLoadingRequests,
    bool? isLoadingActivities,
    String? error,
  }) {
    if (friends != null) _friends = friends;
    if (friendRequests != null) _friendRequests = friendRequests;
    if (sentRequests != null) _sentRequests = sentRequests;
    if (activities != null) _activities = activities;
    if (isLoadingFriends != null) _isLoadingFriends = isLoadingFriends;
    if (isLoadingRequests != null) _isLoadingRequests = isLoadingRequests;
    if (isLoadingActivities != null) _isLoadingActivities = isLoadingActivities;
    if (error != null) _error = error;
    notifyListeners();
  }

  // Load all data for friends screen
  Future<void> loadAllData({bool forceRefresh = false}) async {
    // Check cache age if not forcing refresh
    if (!forceRefresh && _lastLoadAllDataTime != null) {
      final age = DateTime.now().difference(_lastLoadAllDataTime!);
      if (age < _cacheDuration) {
        debugPrint('📦 FriendsService: Using cached loadAllData (${age.inSeconds}s old)');
        return;
      }
      debugPrint('🔄 FriendsService: Cache expired (${age.inSeconds}s old), refreshing');
    }

    if (_loadAllDataFuture != null) {
      if (!forceRefresh) {
        debugPrint('📦 FriendsService: Reusing in-flight loadAllData request');
        return _loadAllDataFuture!;
      }

      try {
        await _loadAllDataFuture!;
      } catch (_) {
        // Allow a refresh even if the previous request failed.
      }
    }

    debugPrint('🚀 FriendsService: Starting loadAllData (forceRefresh: $forceRefresh)');
    final future = _performLoadAllData(forceRefresh: forceRefresh);
    _loadAllDataFuture = future;

    try {
      await future;
      _lastLoadAllDataTime = DateTime.now();
      debugPrint('✅ FriendsService: loadAllData completed and cached');
    } finally {
      if (_loadAllDataFuture == future) {
        _loadAllDataFuture = null;
      }
    }
  }

  Future<void> _performLoadAllData({required bool forceRefresh}) async {
    await Future.wait([
      getFriends(forceRefresh: forceRefresh),
      getFriendRequests(type: 'received', forceRefresh: forceRefresh),
      getFriendRequests(type: 'sent', forceRefresh: forceRefresh),
    ]);
  }

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
    bool forceRefresh = false,
  }) async {
    final requestKey = '$page-$limit';

    // Check cache age if not forcing refresh
    if (!forceRefresh && _friendsCacheTime.containsKey(requestKey)) {
      final age = DateTime.now().difference(_friendsCacheTime[requestKey]!);
      if (age < _cacheDuration) {
        debugPrint('📦 FriendsService: Using cached getFriends (${age.inSeconds}s old)');
        return _friends;
      }
      debugPrint('🔄 FriendsService: getFriends cache expired (${age.inSeconds}s old)');
    }

    final existingRequest = _friendsRequestsInFlight[requestKey];

    if (existingRequest != null) {
      if (!forceRefresh) {
        debugPrint('📦 FriendsService: Reusing in-flight getFriends request');
        return existingRequest;
      }

      try {
        await existingRequest;
      } catch (_) {
        // Previous request failed; continue with a fresh fetch.
      }
    }

    debugPrint('🚀 FriendsService: Starting getFriends (forceRefresh: $forceRefresh)');
    final fetch = _fetchFriends(
      requestKey: requestKey,
      page: page,
      limit: limit,
    );
    _friendsRequestsInFlight[requestKey] = fetch;
    return fetch;
  }

  Future<List<Friend>> _fetchFriends({
    required String requestKey,
    required int page,
    required int limit,
  }) async {
    _friendsLoadingKeys.add(requestKey);
    _updateState(isLoadingFriends: true, error: null);

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

      _friendsLoadingKeys.remove(requestKey);
      final stillLoading = _friendsLoadingKeys.isNotEmpty;
      _updateState(friends: friends, isLoadingFriends: stillLoading);
      _friendsCacheTime[requestKey] = DateTime.now();
      debugPrint('✅ FriendsService: Found ${friends.length} friends (cached)');
      return friends;
    } catch (e) {
      _friendsLoadingKeys.remove(requestKey);
      final stillLoading = _friendsLoadingKeys.isNotEmpty;
      _updateState(isLoadingFriends: stillLoading, error: e.toString());
      debugPrint('❌ FriendsService: Error getting friends: $e');
      rethrow;
    } finally {
      _friendsRequestsInFlight.remove(requestKey);
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

  // Cancel friend request
  Future<void> cancelFriendRequest(String userId) async {
    try {
      debugPrint('🗑️ FriendsService: Cancelling friend request to user: $userId');

      await _apiService.delete('/friends/request/$userId');

      debugPrint('🗑️ FriendsService: Friend request cancelled successfully');
    } catch (e) {
      debugPrint('❌ FriendsService: Error cancelling friend request: $e');
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
    bool forceRefresh = false,
  }) async {
    final requestKey = '$type-$page-$limit';

    // Check cache age if not forcing refresh
    if (!forceRefresh && _friendRequestsCacheTime.containsKey(requestKey)) {
      final age = DateTime.now().difference(_friendRequestsCacheTime[requestKey]!);
      if (age < _cacheDuration) {
        debugPrint('📦 FriendsService: Using cached getFriendRequests[$type] (${age.inSeconds}s old)');
        return type == 'received' ? _friendRequests : _sentRequests;
      }
      debugPrint('🔄 FriendsService: getFriendRequests[$type] cache expired (${age.inSeconds}s old)');
    }

    final existingRequest = _friendRequestsInFlight[requestKey];

    if (existingRequest != null) {
      if (!forceRefresh) {
        debugPrint('📦 FriendsService: Reusing in-flight getFriendRequests[$type] request');
        return existingRequest;
      }

      try {
        await existingRequest;
      } catch (_) {
        // Previous request failed; continue with a new fetch.
      }
    }

    debugPrint('🚀 FriendsService: Starting getFriendRequests[$type] (forceRefresh: $forceRefresh)');
    final fetch = _fetchFriendRequests(
      requestKey: requestKey,
      type: type,
      page: page,
      limit: limit,
    );
    _friendRequestsInFlight[requestKey] = fetch;
    return fetch;
  }

  Future<List<FriendRequest>> _fetchFriendRequests({
    required String requestKey,
    required String type,
    required int page,
    required int limit,
  }) async {
    _friendRequestLoadingKeys.add(requestKey);
    _updateState(isLoadingRequests: true, error: null);
    
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
      _friendRequestLoadingKeys.remove(requestKey);
      final stillLoading = _friendRequestLoadingKeys.isNotEmpty;

      if (type == 'received') {
        _updateState(friendRequests: requests, isLoadingRequests: stillLoading);
      } else {
        _updateState(sentRequests: requests, isLoadingRequests: stillLoading);
      }

      _friendRequestsCacheTime[requestKey] = DateTime.now();
      debugPrint('✅ FriendsService: Found ${requests.length} $type friend requests (cached)');
      return requests;
    } catch (e) {
      _friendRequestLoadingKeys.remove(requestKey);
      final stillLoading = _friendRequestLoadingKeys.isNotEmpty;
      _updateState(isLoadingRequests: stillLoading, error: e.toString());
      debugPrint('❌ FriendsService: Error getting friend requests: $e');
      rethrow;
    } finally {
      _friendRequestsInFlight.remove(requestKey);
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
