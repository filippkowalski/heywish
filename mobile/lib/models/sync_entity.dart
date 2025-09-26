/// Base class for all entities that support offline sync
abstract class SyncEntity {
  String get id;
  DateTime get updatedAt;
  DateTime get createdAt;
  int get version;
  String? get deviceId;
  SyncState get syncState;
  
  /// Unique hash for conflict detection
  String get contentHash;
  
  /// Convert to map for database storage
  Map<String, dynamic> toLocalDb();
  
  /// Convert to map for API sync
  Map<String, dynamic> toApiSync();
  
  /// Create entity from local database
  static T fromLocalDb<T extends SyncEntity>(Map<String, dynamic> data) {
    throw UnimplementedError('fromLocalDb must be implemented by subclass');
  }
}

enum SyncState {
  synced,     // ✅ Matches server exactly
  pending,    // 📤 Local changes waiting to sync
  conflict,   // ⚠️  Server has newer version - needs resolution
  offline,    // 📴 Created offline, never synced
  deleted,    // 🗑️  Marked for deletion
}

enum ConflictResolution {
  useLocal,   // Keep local changes, overwrite server
  useRemote,  // Accept server version, discard local
  merge,      // Attempt automatic merge
  manual,     // User intervention required
}

/// Metadata for sync operations
class SyncMetadata {
  final String entityId;
  final String entityType;
  final DateTime lastSyncAttempt;
  final DateTime? lastSuccessfulSync;
  final int retryCount;
  final String? lastError;
  final SyncState syncState;
  final String? conflictData; // JSON of server version when conflict occurs
  
  const SyncMetadata({
    required this.entityId,
    required this.entityType,
    required this.lastSyncAttempt,
    this.lastSuccessfulSync,
    this.retryCount = 0,
    this.lastError,
    required this.syncState,
    this.conflictData,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'entity_id': entityId,
      'entity_type': entityType,
      'last_sync_attempt': lastSyncAttempt.toIso8601String(),
      'last_successful_sync': lastSuccessfulSync?.toIso8601String(),
      'retry_count': retryCount,
      'last_error': lastError,
      'sync_state': syncState.toString(),
      'conflict_data': conflictData,
    };
  }
  
  factory SyncMetadata.fromMap(Map<String, dynamic> map) {
    return SyncMetadata(
      entityId: map['entity_id'],
      entityType: map['entity_type'],
      lastSyncAttempt: DateTime.parse(map['last_sync_attempt']),
      lastSuccessfulSync: map['last_successful_sync'] != null 
          ? DateTime.parse(map['last_successful_sync'])
          : null,
      retryCount: map['retry_count'] ?? 0,
      lastError: map['last_error'],
      syncState: SyncState.values.firstWhere(
        (e) => e.toString() == map['sync_state'],
        orElse: () => SyncState.offline,
      ),
      conflictData: map['conflict_data'],
    );
  }
  
  SyncMetadata copyWith({
    DateTime? lastSyncAttempt,
    DateTime? lastSuccessfulSync,
    int? retryCount,
    String? lastError,
    SyncState? syncState,
    String? conflictData,
  }) {
    return SyncMetadata(
      entityId: entityId,
      entityType: entityType,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      lastSuccessfulSync: lastSuccessfulSync ?? this.lastSuccessfulSync,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      syncState: syncState ?? this.syncState,
      conflictData: conflictData ?? this.conflictData,
    );
  }
}

/// Change operation for tracking modifications
class ChangeOperation {
  final String id;
  final String entityId;
  final String entityType;
  final String operation; // 'create', 'update', 'delete'
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String deviceId;
  
  const ChangeOperation({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.operation,
    required this.data,
    required this.timestamp,
    required this.deviceId,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity_id': entityId,
      'entity_type': entityType,
      'operation': operation,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'device_id': deviceId,
    };
  }
  
  factory ChangeOperation.fromMap(Map<String, dynamic> map) {
    return ChangeOperation(
      id: map['id'],
      entityId: map['entity_id'],
      entityType: map['entity_type'],
      operation: map['operation'],
      data: Map<String, dynamic>.from(map['data']),
      timestamp: DateTime.parse(map['timestamp']),
      deviceId: map['device_id'],
    );
  }
}