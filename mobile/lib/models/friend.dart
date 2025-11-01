import 'friendship_enums.dart';

class Friend {
  final String id;
  final String friendshipId;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;
  final DateTime friendsSince;
  final String status;

  Friend({
    required this.id,
    required this.friendshipId,
    required this.username,
    this.fullName,
    this.avatarUrl,
    this.bio,
    required this.friendsSince,
    required this.status,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['friend_id'],
      friendshipId: json['friendship_id'],
      username: json['username'] ?? '',
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      friendsSince: DateTime.parse(json['friends_since']),
      status: json['status'] ?? 'accepted',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'friend_id': id,
      'friendship_id': friendshipId,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'friends_since': friendsSince.toIso8601String(),
      'status': status,
    };
  }

  String get displayName => fullName ?? username;

  // Enum-based getter for type-safe status checking
  FriendshipStatus get friendshipStatus => FriendshipStatus.fromJson(status);
  bool get isActive => friendshipStatus == FriendshipStatus.accepted;
}

class FriendRequest {
  final String id;
  final String status;
  final DateTime createdAt;
  final String requesterId;
  final String? requesterUsername;
  final String? requesterFullName;
  final String? requesterAvatarUrl;
  final String? addresseeId;
  final String? addresseeUsername;
  final String? addresseeFullName;
  final String? addresseeAvatarUrl;

  FriendRequest({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.requesterId,
    this.requesterUsername,
    this.requesterFullName,
    this.requesterAvatarUrl,
    this.addresseeId,
    this.addresseeUsername,
    this.addresseeFullName,
    this.addresseeAvatarUrl,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      requesterId: json['requester_id'] ?? '',
      requesterUsername: json['requester_username'],
      requesterFullName: json['requester_full_name'],
      requesterAvatarUrl: json['requester_avatar_url'],
      addresseeId: json['addressee_id'],
      addresseeUsername: json['addressee_username'],
      addresseeFullName: json['addressee_full_name'],
      addresseeAvatarUrl: json['addressee_avatar_url'],
    );
  }

  String get requesterDisplayName => requesterFullName ?? requesterUsername ?? 'Unknown';
  String get addresseeDisplayName => addresseeFullName ?? addresseeUsername ?? 'Unknown';

  // Enum-based getter for type-safe status checking
  FriendshipStatus get requestStatus => FriendshipStatus.fromJson(status);
  bool get isPending => requestStatus == FriendshipStatus.pending;
  bool get isAccepted => requestStatus == FriendshipStatus.accepted;
  bool get isDeclined => requestStatus == FriendshipStatus.declined;
}

class UserSearchResult {
  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;
  final String? friendshipStatus;
  final String? requestDirection;

  UserSearchResult({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
    this.bio,
    this.friendshipStatus,
    this.requestDirection,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'],
      username: json['username'] ?? '',
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      friendshipStatus: json['friendship_status'],
      requestDirection: json['request_direction'],
    );
  }

  String get displayName => fullName ?? username;

  // Enum-based getters for type-safe status checking
  FriendshipStatus get status => FriendshipStatus.fromJson(friendshipStatus);
  RequestDirection get direction => RequestDirection.fromJson(requestDirection);

  // Boolean helpers using enums
  bool get isFriend => status == FriendshipStatus.accepted;
  bool get hasPendingRequest => status == FriendshipStatus.pending;
  bool get requestSentByMe => direction == RequestDirection.sent;
  bool get requestSentToMe => direction == RequestDirection.received;
}

class UserProfile {
  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;
  final String? location;
  final DateTime joinedAt;
  final int wishlistCount;
  final int friendCount;
  final String? friendshipStatus;
  final String? requestDirection;

  UserProfile({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
    this.bio,
    this.location,
    required this.joinedAt,
    required this.wishlistCount,
    required this.friendCount,
    this.friendshipStatus,
    this.requestDirection,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'] ?? '',
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      location: json['location'],
      joinedAt: DateTime.parse(json['joined_at']),
      wishlistCount: (json['wishlist_count'] ?? 0).toInt(),
      friendCount: (json['friend_count'] ?? 0).toInt(),
      friendshipStatus: json['friendship_status'],
      requestDirection: json['request_direction'],
    );
  }

  String get displayName => fullName ?? username;

  // Enum-based getters for type-safe status checking
  FriendshipStatus get status => FriendshipStatus.fromJson(friendshipStatus);
  RequestDirection get direction => RequestDirection.fromJson(requestDirection);

  // Boolean helpers using enums
  bool get isFriend => status == FriendshipStatus.accepted;
  bool get hasPendingRequest => status == FriendshipStatus.pending;
  bool get requestSentByMe => direction == RequestDirection.sent;
  bool get requestSentToMe => direction == RequestDirection.received;
}

class Activity {
  final String id;
  final String activityType;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final String username;
  final String? fullName;
  final String? avatarUrl;

  Activity({
    required this.id,
    required this.activityType,
    required this.data,
    required this.createdAt,
    required this.username,
    this.fullName,
    this.avatarUrl,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      activityType: json['activity_type'],
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      username: json['username'] ?? '',
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
    );
  }

  String get userDisplayName => fullName ?? username;

  String get description {
    switch (activityType) {
      case 'collection_created':
        return 'created a new wishlist';
      case 'item_added':
        return 'added an item to their wishlist';
      case 'item_reserved':
        return 'reserved an item';
      case 'item_purchased':
        return 'purchased an item';
      case 'friend_added':
        return 'became friends with someone';
      case 'friend_request_sent':
        return 'sent a friend request';
      default:
        return 'had some activity';
    }
  }
}