import 'package:flutter/foundation.dart';
import '../models/friend.dart';
import 'api_service.dart' hide Friend, UserSearchResult;

class FriendsService extends ChangeNotifier {
  static final FriendsService _instance = FriendsService._internal();
  factory FriendsService() => _instance;
  FriendsService._internal();

  final ApiService _apiService = ApiService();

  // State management
  List<Friend> _friends = [];
  List<FriendRequest> _friendRequests = [];
  List<FriendRequest> _sentRequests = [];
  List<Activity> _activities = [];
  bool _isLoadingFriends = false;
  bool _isLoadingRequests = false;
  bool _isLoadingActivities = false;
  String? _error;

  // Getters
  List<Friend> get friends => _friends;
  List<FriendRequest> get friendRequests => _friendRequests;
  List<FriendRequest> get sentRequests => _sentRequests;
  List<Activity> get activities => _activities;
  bool get isLoadingFriends => _isLoadingFriends;
  bool get isLoadingRequests => _isLoadingRequests;
  bool get isLoadingActivities => _isLoadingActivities;
  String? get error => _error;

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
  Future<void> loadAllData() async {
    await Future.wait([
      getFriends(),
      getFriendRequests(type: 'received'),
      getFriendRequests(type: 'sent'),
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
  }) async {
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
      
      _updateState(friends: friends, isLoadingFriends: false);
      debugPrint('👥 FriendsService: Found ${friends.length} friends');
      return friends;
    } catch (e) {
      _updateState(isLoadingFriends: false, error: e.toString());
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
      
      if (type == 'received') {
        _updateState(friendRequests: requests, isLoadingRequests: false);
      } else {
        _updateState(sentRequests: requests, isLoadingRequests: false);
      }
      
      debugPrint('📬 FriendsService: Found ${requests.length} $type friend requests');
      return requests;
    } catch (e) {
      _updateState(isLoadingRequests: false, error: e.toString());
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