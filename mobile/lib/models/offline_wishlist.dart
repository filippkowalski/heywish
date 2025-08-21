import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'sync_entity.dart';
import 'wishlist.dart';
import 'wish.dart';

/// Offline-capable wishlist that extends SyncEntity
class OfflineWishlist extends Wishlist implements SyncEntity {
  @override
  final int version;
  @override
  final String? deviceId;
  @override
  final SyncState syncState;
  
  OfflineWishlist({
    required super.id,
    required super.name,
    super.description,
    required super.visibility,
    required super.userId,
    super.shareToken,
    super.coverImageUrl,
    super.wishCount,
    super.reservedCount,
    super.wishes,
    required super.createdAt,
    required super.updatedAt,
    this.version = 1,
    this.deviceId,
    this.syncState = SyncState.offline,
  });

  @override
  String get contentHash {
    final content = {
      'id': id,
      'name': name,
      'description': description,
      'visibility': visibility,
      'user_id': userId,
      'share_token': shareToken,
      'cover_image_url': coverImageUrl,
      'wish_count': wishCount,
      'reserved_count': reservedCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'version': version,
    };
    
    final jsonString = jsonEncode(content);
    final bytes = utf8.encode(jsonString);
    return sha256.convert(bytes).toString();
  }

  @override
  Map<String, dynamic> toLocalDb() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'visibility': visibility,
      'user_id': userId,
      'share_token': shareToken,
      'cover_image_url': coverImageUrl,
      'wish_count': wishCount,
      'reserved_count': reservedCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'version': version,
      'device_id': deviceId,
      'sync_state': syncState.toString(),
      'content_hash': contentHash,
    };
  }

  @override
  Map<String, dynamic> toApiSync() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'visibility': visibility,
      'share_token': shareToken,
      'cover_image_url': coverImageUrl,
      'version': version,
    };
  }

  /// Create from local database
  static OfflineWishlist fromLocalDb(Map<String, dynamic> data) {
    return OfflineWishlist(
      id: data['id'],
      name: data['name'],
      description: data['description'],
      visibility: data['visibility'],
      userId: data['user_id'],
      shareToken: data['share_token'],
      coverImageUrl: data['cover_image_url'],
      wishCount: data['wish_count'] ?? 0,
      reservedCount: data['reserved_count'] ?? 0,
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
      version: data['version'] ?? 1,
      deviceId: data['device_id'],
      syncState: SyncState.values.firstWhere(
        (s) => s.toString() == data['sync_state'],
        orElse: () => SyncState.offline,
      ),
    );
  }

  /// Create from API response
  static OfflineWishlist fromApi(Map<String, dynamic> data) {
    return OfflineWishlist(
      id: data['id'],
      name: data['name'],
      description: data['description'],
      visibility: data['visibility'] ?? 'private',
      userId: data['user_id'],
      shareToken: data['share_token'],
      coverImageUrl: data['cover_image_url'],
      wishCount: data['wish_count'] ?? 0,
      reservedCount: data['reserved_count'] ?? 0,
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
      version: data['version'] ?? 1,
      syncState: SyncState.synced,
    );
  }

  /// Convert to regular Wishlist for UI
  Wishlist toWishlist() {
    return Wishlist(
      id: id,
      name: name,
      description: description,
      visibility: visibility,
      userId: userId,
      shareToken: shareToken,
      coverImageUrl: coverImageUrl,
      wishCount: wishCount,
      reservedCount: reservedCount,
      wishes: wishes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create a copy with updated sync state
  OfflineWishlist copyWithSyncState(SyncState newState) {
    return OfflineWishlist(
      id: id,
      name: name,
      description: description,
      visibility: visibility,
      userId: userId,
      shareToken: shareToken,
      coverImageUrl: coverImageUrl,
      wishCount: wishCount,
      reservedCount: reservedCount,
      wishes: wishes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      version: version,
      deviceId: deviceId,
      syncState: newState,
    );
  }

  /// Create a copy with incremented version for updates
  OfflineWishlist copyWithUpdate({
    String? name,
    String? description,
    String? visibility,
    String? coverImageUrl,
    List<Wish>? wishes,
    String? deviceId,
  }) {
    return OfflineWishlist(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      visibility: visibility ?? this.visibility,
      userId: userId,
      shareToken: shareToken,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      wishCount: wishCount,
      reservedCount: reservedCount,
      wishes: wishes ?? this.wishes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      version: version + 1,
      deviceId: deviceId ?? this.deviceId,
      syncState: SyncState.pending,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OfflineWishlist &&
        other.id == id &&
        other.version == version &&
        other.contentHash == contentHash;
  }

  @override
  int get hashCode => Object.hash(id, version, contentHash);

  @override
  String toString() {
    return 'OfflineWishlist(id: $id, name: $name, version: $version, syncState: $syncState)';
  }
}