/// Enum representing the status of a friendship between two users
enum FriendshipStatus {
  /// No friendship exists
  none,

  /// Friend request is pending
  pending,

  /// Friendship is accepted and active
  accepted,

  /// Friend request was declined
  declined;

  /// Convert enum to string value for API communication
  String toJson() {
    switch (this) {
      case FriendshipStatus.none:
        return 'none';
      case FriendshipStatus.pending:
        return 'pending';
      case FriendshipStatus.accepted:
        return 'accepted';
      case FriendshipStatus.declined:
        return 'declined';
    }
  }

  /// Create enum from string value
  static FriendshipStatus fromJson(String? value) {
    switch (value) {
      case 'pending':
        return FriendshipStatus.pending;
      case 'accepted':
        return FriendshipStatus.accepted;
      case 'declined':
        return FriendshipStatus.declined;
      default:
        return FriendshipStatus.none;
    }
  }
}

/// Enum representing the direction of a friend request
enum RequestDirection {
  /// No request exists
  none,

  /// Request was sent by the current user
  sent,

  /// Request was received by the current user
  received;

  /// Convert enum to string value for API communication
  String toJson() {
    switch (this) {
      case RequestDirection.none:
        return 'none';
      case RequestDirection.sent:
        return 'sent';
      case RequestDirection.received:
        return 'received';
    }
  }

  /// Create enum from string value
  static RequestDirection fromJson(String? value) {
    switch (value) {
      case 'sent':
        return RequestDirection.sent;
      case 'received':
        return RequestDirection.received;
      default:
        return RequestDirection.none;
    }
  }
}

/// Enum for friend request types when fetching from API
enum FriendRequestType {
  /// Requests sent by the current user
  sent,

  /// Requests received by the current user
  received;

  /// Convert enum to string value for API communication
  String toJson() {
    switch (this) {
      case FriendRequestType.sent:
        return 'sent';
      case FriendRequestType.received:
        return 'received';
    }
  }
}

/// Enum for friend request actions
enum FriendRequestAction {
  /// Accept the friend request
  accept,

  /// Decline the friend request
  decline;

  /// Convert enum to string value for API communication
  String toJson() {
    switch (this) {
      case FriendRequestAction.accept:
        return 'accept';
      case FriendRequestAction.decline:
        return 'decline';
    }
  }
}
