import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import '../models/sync_entity.dart';
import 'local_database.dart';
import 'api_service.dart';
import 'fcm_service.dart';

class SyncManager extends ChangeNotifier {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  final LocalDatabase _localDb = LocalDatabase();
  final ApiService _apiService = ApiService();
  final Connectivity _connectivity = Connectivity();
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicSyncTimer;
  bool _isSyncing = false;
  
  // Sync statistics
  int _pendingChanges = 0;
  int _conflictCount = 0;
  DateTime? _lastSyncAttempt;
  DateTime? _lastSuccessfulSync;
  
  // Getters
  bool get isSyncing => _isSyncing;
  int get pendingChanges => _pendingChanges;
  int get conflictCount => _conflictCount;
  DateTime? get lastSyncAttempt => _lastSyncAttempt;
  DateTime? get lastSuccessfulSync => _lastSuccessfulSync;
  
  /// Initialize sync manager
  Future<void> initialize() async {
    await _localDb.initialize();
    
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
    
    // Start periodic sync
    _startPeriodicSync();
    
    // Update statistics
    await _updateStatistics();
    
    debugPrint('✅ SyncManager: Initialized');
  }
  
  /// Start periodic background sync
  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(
      const Duration(minutes: 5), // Sync every 5 minutes
      (_) => syncIfOnline(),
    );
  }
  
  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final hasConnection = results.any((result) => result != ConnectivityResult.none);
    if (hasConnection) {
      debugPrint('🌐 SyncManager: Connection restored, starting sync');
      syncIfOnline();
    }
  }
  
  /// Check if device is online and sync if possible
  Future<void> syncIfOnline() async {
    // Don't sync if not authenticated
    if (!_apiService.hasAuthToken) {
      debugPrint('⚠️  SyncManager: No auth token, skipping sync');
      return;
    }

    final connectivityResults = await _connectivity.checkConnectivity();
    final hasConnection = connectivityResults.any((result) => result != ConnectivityResult.none);
    if (hasConnection) {
      await performFullSync();
    }
  }
  
  /// Perform full bidirectional sync
  Future<SyncResult> performFullSync() async {
    if (_isSyncing) {
      debugPrint('⚠️  SyncManager: Sync already in progress');
      return SyncResult.inProgress();
    }

    // Check if we have a valid auth token before attempting sync
    if (!_apiService.hasAuthToken) {
      debugPrint('⚠️  SyncManager: No auth token available, skipping sync');
      return SyncResult.error('Not authenticated');
    }
    
    _isSyncing = true;
    _lastSyncAttempt = DateTime.now();
    notifyListeners();
    
    try {
      debugPrint('🔄 SyncManager: Starting full sync...');
      
      final result = SyncResult();
      
      // 1. Push local changes to server
      await _pushLocalChanges(result);
      
      // 2. Pull server changes to local
      await _pullServerChanges(result);
      
      // 3. Resolve conflicts
      await _resolveConflicts(result);
      
      _lastSuccessfulSync = DateTime.now();
      await _updateStatistics();

      if (!result.hasErrors) {
        debugPrint('🔔 SyncManager: Triggering FCM token retry after successful sync');
        FCMService().retryTokenRegistration();
      }
      
      debugPrint('✅ SyncManager: Full sync completed');
      debugPrint('📊 Sync result: ${result.toString()}');
      
      return result;
    } catch (e) {
      debugPrint('❌ SyncManager: Sync failed: $e');
      return SyncResult.error(e.toString());
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
  
  /// Push local changes to server
  Future<void> _pushLocalChanges(SyncResult result) async {
    final changes = await _localDb.getUnsyncdChanges();
    debugPrint('📤 SyncManager: Pushing ${changes.length} local changes');
    
    for (final change in changes) {
      try {
        await _pushSingleChange(change);
        await _localDb.markChangeAsSynced(change.id);
        result.pushedChanges++;
      } catch (e) {
        debugPrint('❌ Failed to push change ${change.id}: $e');
        result.pushErrors++;
      }
    }
  }
  
  /// Push single change to server
  Future<void> _pushSingleChange(ChangeOperation change) async {
    final endpoint = _resolveEndpointForEntity(change.entityType);
    switch (change.operation) {
      case 'create':
        await _apiService.post(endpoint, change.data);
        break;
      case 'update':
        await _apiService.patch('$endpoint/${change.entityId}', change.data);
        break;
      case 'delete':
        await _apiService.delete('$endpoint/${change.entityId}');
        break;
    }
  }

  String _resolveEndpointForEntity(String entityType) {
    switch (entityType) {
      case 'user':
        return '/users';
      case 'wishlist':
        return '/wishlists';
      case 'wish':
        return '/wishes';
      default:
        return '/${entityType}s';
    }
  }
  
  /// Pull server changes to local
  Future<void> _pullServerChanges(SyncResult result) async {
    debugPrint('📥 SyncManager: Pulling server changes');
    
    // Pull users, wishlists, and wishes from server
    await _pullEntitiesOfType('user', result);
    await _pullEntitiesOfType('wishlist', result);
    await _pullEntitiesOfType('wish', result);
  }
  
  /// Pull entities of specific type from server
  Future<void> _pullEntitiesOfType(String entityType, SyncResult result) async {
    try {
      // Get last sync timestamp for this entity type from local storage
      final lastSyncTimestamp = await _localDb.getLastSyncTimestamp(entityType);
      
      // Build query parameters
      Map<String, dynamic>? queryParams;
      if (lastSyncTimestamp != null) {
        queryParams = {'since': lastSyncTimestamp.toString()};
      }
      
      // Map entity types to correct endpoint plurals
      final endpointMap = {
        'user': 'users',
        'wishlist': 'wishlists', 
        'wish': 'wishes'
      };
      
      final endpoint = endpointMap[entityType] ?? '${entityType}s';
      final response = await _apiService.get('/$endpoint/sync', queryParameters: queryParams);
      final entities = response[endpoint] as List;
      final serverTimestamp = response['server_timestamp'] as int;
      
      debugPrint('🔄 SyncManager: Received ${entities.length} $entityType entities from server');
      
      for (final entityData in entities) {
        final serverEntity = Map<String, dynamic>.from(entityData);
        await _localDb.saveServerEntity(entityType, serverEntity);
        result.pulledChanges++;
      }
      
      // Update last sync timestamp
      await _localDb.setLastSyncTimestamp(entityType, serverTimestamp);
      
    } catch (e) {
      debugPrint('❌ Failed to pull $entityType entities: $e');
      result.pullErrors++;
    }
  }
  
  /// Process single entity from server
  Future<void> _processServerEntity(
    String entityType, 
    Map<String, dynamic> serverEntity, 
    SyncResult result
  ) async {
    final entityId = serverEntity['id'];
    final localEntity = await _localDb.getEntity('${entityType}s', entityId);
    
    if (localEntity == null) {
      // New entity from server
      await _saveServerEntity(entityType, serverEntity);
      result.pulledChanges++;
    } else {
      // Check for conflicts
      final localVersion = localEntity['version'] as int;
      final serverVersion = serverEntity['version'] as int;
      final localSyncState = SyncState.values.firstWhere(
        (s) => s.toString() == localEntity['sync_state'],
      );
      
      if (serverVersion > localVersion) {
        if (localSyncState == SyncState.pending) {
          // Conflict detected
          await _handleConflict(entityType, entityId, localEntity, serverEntity);
          result.conflicts++;
        } else {
          // Accept server version
          await _saveServerEntity(entityType, serverEntity);
          result.pulledChanges++;
        }
      }
      // If local version >= server version, no action needed
    }
  }
  
  /// Save server entity to local database
  Future<void> _saveServerEntity(String entityType, Map<String, dynamic> entity) async {
    entity['sync_state'] = SyncState.synced.toString();
    entity['content_hash'] = _calculateContentHash(entity);
    await _localDb.upsertEntity('${entityType}s', entity);
  }
  
  /// Handle conflict between local and server versions
  Future<void> _handleConflict(
    String entityType,
    String entityId,
    Map<String, dynamic> localEntity,
    Map<String, dynamic> serverEntity,
  ) async {
    debugPrint('⚠️  SyncManager: Conflict detected for $entityType $entityId');
    
    // Store conflict metadata
    final metadata = SyncMetadata(
      entityId: entityId,
      entityType: entityType,
      lastSyncAttempt: DateTime.now(),
      syncState: SyncState.conflict,
      conflictData: jsonEncode(serverEntity),
    );
    
    await _localDb.setSyncMetadata(metadata);
    await _localDb.updateSyncState('${entityType}s', entityId, SyncState.conflict);
  }
  
  /// Resolve conflicts with user input or automatic strategies
  Future<void> _resolveConflicts(SyncResult result) async {
    // For now, implement automatic conflict resolution
    // In a real app, you'd show UI for user to choose
    
    final conflictEntities = await _getConflictEntities();
    
    for (final conflict in conflictEntities) {
      final resolution = await _autoResolveConflict(conflict);
      await _applyConflictResolution(conflict, resolution);
      result.resolvedConflicts++;
    }
  }
  
  /// Get entities in conflict state
  Future<List<Map<String, dynamic>>> _getConflictEntities() async {
    final conflicts = <Map<String, dynamic>>[];
    
    // Check all entity types
    for (final table in ['users', 'wishlists', 'wishes']) {
      final entities = await _localDb.getEntities(
        table,
        where: 'sync_state = ?',
        whereArgs: [SyncState.conflict.toString()],
      );
      
      for (final entity in entities) {
        final metadata = await _localDb.getSyncMetadata(entity['id']);
        if (metadata != null && metadata.conflictData != null) {
          conflicts.add({
            'table': table,
            'local': entity,
            'server': jsonDecode(metadata.conflictData!),
            'metadata': metadata,
          });
        }
      }
    }
    
    return conflicts;
  }
  
  /// Automatic conflict resolution strategy
  Future<ConflictResolution> _autoResolveConflict(Map<String, dynamic> conflict) async {
    final local = conflict['local'] as Map<String, dynamic>;
    final server = conflict['server'] as Map<String, dynamic>;
    
    // Simple strategy: most recent wins
    final localUpdated = DateTime.parse(local['updated_at']);
    final serverUpdated = DateTime.parse(server['updated_at']);
    
    if (localUpdated.isAfter(serverUpdated)) {
      return ConflictResolution.useLocal;
    } else {
      return ConflictResolution.useRemote;
    }
  }
  
  /// Apply conflict resolution
  Future<void> _applyConflictResolution(
    Map<String, dynamic> conflict,
    ConflictResolution resolution,
  ) async {
    final table = conflict['table'];
    final local = conflict['local'] as Map<String, dynamic>;
    final server = conflict['server'] as Map<String, dynamic>;
    final entityId = local['id'];
    
    switch (resolution) {
      case ConflictResolution.useLocal:
        // Push local version to server
        final change = ChangeOperation(
          id: _generateId(),
          entityId: entityId,
          entityType: table.substring(0, table.length - 1), // Remove 's'
          operation: 'update',
          data: local,
          timestamp: DateTime.now(),
          deviceId: await _getDeviceId(),
        );
        await _localDb.addChangeOperation(change);
        break;
        
      case ConflictResolution.useRemote:
        // Accept server version
        await _saveServerEntity(table.substring(0, table.length - 1), server);
        break;
        
      case ConflictResolution.merge:
        // Implement merge logic (app-specific)
        final merged = _mergeEntities(local, server);
        await _localDb.upsertEntity(table, merged);
        break;
        
      case ConflictResolution.manual:
        // Keep in conflict state for manual resolution
        return;
    }
    
    // Clear conflict state
    await _localDb.updateSyncState(table, entityId, SyncState.synced);
  }
  
  /// Merge two entity versions (basic implementation)
  Map<String, dynamic> _mergeEntities(
    Map<String, dynamic> local,
    Map<String, dynamic> server,
  ) {
    // Simple merge: take newer fields, prefer local for user-editable content
    final merged = Map<String, dynamic>.from(server);
    
    // Prefer local values for user-editable fields
    const userFields = ['name', 'description', 'title', 'notes'];
    for (final field in userFields) {
      if (local.containsKey(field) && local[field] != null) {
        merged[field] = local[field];
      }
    }
    
    // Always use latest timestamp and increment version
    merged['updated_at'] = DateTime.now().toIso8601String();
    merged['version'] = max(local['version'] ?? 1, server['version'] ?? 1) + 1;
    merged['sync_state'] = SyncState.pending.toString();
    
    return merged;
  }
  
  /// Update sync statistics
  Future<void> _updateStatistics() async {
    _pendingChanges = (await _localDb.getUnsyncdChanges()).length;
    
    final conflictCounts = await Future.wait([
      _localDb.getEntities('users', where: 'sync_state = ?', whereArgs: [SyncState.conflict.toString()]),
      _localDb.getEntities('wishlists', where: 'sync_state = ?', whereArgs: [SyncState.conflict.toString()]),
      _localDb.getEntities('wishes', where: 'sync_state = ?', whereArgs: [SyncState.conflict.toString()]),
    ]);
    
    _conflictCount = conflictCounts.fold(0, (sum, list) => sum + list.length);
    notifyListeners();
  }
  
  /// Calculate content hash for entity
  String _calculateContentHash(Map<String, dynamic> entity) {
    // Remove sync-specific fields
    final content = Map<String, dynamic>.from(entity);
    content.removeWhere((key, value) => 
      ['sync_state', 'content_hash', 'device_id'].contains(key));
    
    final jsonString = jsonEncode(content);
    final bytes = utf8.encode(jsonString);
    return sha256.convert(bytes).toString();
  }
  
  /// Generate unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }
  
  /// Get device ID
  Future<String> _getDeviceId() async {
    // In a real app, you'd use device_info_plus or similar
    return 'device_${Random().nextInt(10000)}';
  }
  
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
    super.dispose();
  }
}

/// Result of sync operation
class SyncResult {
  int pushedChanges = 0;
  int pulledChanges = 0;
  int conflicts = 0;
  int resolvedConflicts = 0;
  int pushErrors = 0;
  int pullErrors = 0;
  String? error;
  
  SyncResult();
  
  SyncResult.error(this.error);
  
  SyncResult.inProgress() {
    error = 'Sync already in progress';
  }
  
  bool get hasErrors => pushErrors > 0 || pullErrors > 0 || error != null;
  bool get hasConflicts => conflicts > 0;
  bool get isSuccessful => !hasErrors && conflicts == 0;
  
  @override
  String toString() {
    return 'SyncResult(pushed: $pushedChanges, pulled: $pulledChanges, '
           'conflicts: $conflicts, resolved: $resolvedConflicts, '
           'pushErrors: $pushErrors, pullErrors: $pullErrors, '
           'error: $error)';
  }
}
