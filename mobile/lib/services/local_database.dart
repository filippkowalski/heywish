import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/sync_entity.dart';

class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  factory LocalDatabase() => _instance;
  LocalDatabase._internal();

  Database? _database;
  final Completer<Database> _dbCompleter = Completer<Database>();

  /// Initialize the database
  Future<void> initialize() async {
    if (_database != null) return;

    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'heywish_offline.db');

      _database = await openDatabase(
        path,
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );

      _dbCompleter.complete(_database!);
      debugPrint('✅ LocalDatabase: Database initialized at $path');
    } catch (e) {
      debugPrint('❌ LocalDatabase: Failed to initialize: $e');
      _dbCompleter.completeError(e);
      rethrow;
    }
  }

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    return _dbCompleter.future;
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    debugPrint('📦 LocalDatabase: Creating tables...');

    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        firebase_uid TEXT UNIQUE NOT NULL,
        email TEXT,
        full_name TEXT,
        username TEXT,
        avatar_url TEXT,
        bio TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        version INTEGER NOT NULL DEFAULT 1,
        device_id TEXT,
        sync_state TEXT NOT NULL DEFAULT 'offline',
        content_hash TEXT NOT NULL
      )
    ''');

    // Wishlists table
    await db.execute('''
      CREATE TABLE wishlists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        visibility TEXT NOT NULL DEFAULT 'private',
        user_id TEXT NOT NULL,
        share_token TEXT,
        cover_image_url TEXT,
        wish_count INTEGER DEFAULT 0,
        reserved_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        version INTEGER NOT NULL DEFAULT 1,
        device_id TEXT,
        sync_state TEXT NOT NULL DEFAULT 'offline',
        content_hash TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Wishes table
    await db.execute('''
      CREATE TABLE wishes (
        id TEXT PRIMARY KEY,
        wishlist_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        price REAL,
        currency TEXT DEFAULT 'USD',
        url TEXT,
        images TEXT, -- JSON array
        brand TEXT,
        category TEXT,
        priority INTEGER DEFAULT 1,
        quantity INTEGER DEFAULT 1,
        notes TEXT,
        is_reserved INTEGER DEFAULT 0,
        reserved_by TEXT,
        reserved_at TEXT,
        reserver_name TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        version INTEGER NOT NULL DEFAULT 1,
        device_id TEXT,
        sync_state TEXT NOT NULL DEFAULT 'offline',
        content_hash TEXT NOT NULL,
        FOREIGN KEY (wishlist_id) REFERENCES wishlists (id)
      )
    ''');

    // Sync metadata table
    await db.execute('''
      CREATE TABLE sync_metadata (
        entity_id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        last_sync_attempt TEXT NOT NULL,
        last_successful_sync TEXT,
        retry_count INTEGER DEFAULT 0,
        last_error TEXT,
        sync_state TEXT NOT NULL,
        conflict_data TEXT
      )
    ''');

    // Change operations table (for operational transform)
    await db.execute('''
      CREATE TABLE change_operations (
        id TEXT PRIMARY KEY,
        entity_id TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT NOT NULL, -- JSON
        timestamp TEXT NOT NULL,
        device_id TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Sync timestamps table (for incremental sync)
    await db.execute('''
      CREATE TABLE sync_timestamps (
        entity_type TEXT PRIMARY KEY,
        timestamp INTEGER NOT NULL
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_wishlists_user_id ON wishlists(user_id)');
    await db.execute('CREATE INDEX idx_wishes_wishlist_id ON wishes(wishlist_id)');
    await db.execute('CREATE INDEX idx_sync_metadata_state ON sync_metadata(sync_state)');
    await db.execute('CREATE INDEX idx_change_operations_synced ON change_operations(synced)');
    await db.execute('CREATE INDEX idx_change_operations_timestamp ON change_operations(timestamp)');

    debugPrint('✅ LocalDatabase: Tables created successfully');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('🔄 LocalDatabase: Upgrading from $oldVersion to $newVersion');
    
    if (oldVersion < 2) {
      // Add sync_timestamps table for version 2
      await db.execute('''
        CREATE TABLE sync_timestamps (
          entity_type TEXT PRIMARY KEY,
          timestamp INTEGER NOT NULL
        )
      ''');
      debugPrint('✅ LocalDatabase: Added sync_timestamps table');
    }
  }

  // CRUD Operations

  /// Insert or update entity
  Future<void> upsertEntity(String table, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get entity by ID
  Future<Map<String, dynamic>?> getEntity(String table, String id) async {
    final db = await database;
    final result = await db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  /// Get all entities with optional filter
  Future<List<Map<String, dynamic>>> getEntities(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  /// Delete entity
  Future<void> deleteEntity(String table, String id) async {
    final db = await database;
    await db.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Sync-specific operations

  /// Get entities that need syncing
  Future<List<Map<String, dynamic>>> getEntitiesNeedingSync(String table) async {
    final db = await database;
    return await db.query(
      table,
      where: 'sync_state IN (?, ?, ?)',
      whereArgs: [
        SyncState.pending.toString(),
        SyncState.offline.toString(),
        SyncState.deleted.toString(),
      ],
      orderBy: 'updated_at ASC',
    );
  }

  /// Update sync state
  Future<void> updateSyncState(String table, String id, SyncState state) async {
    final db = await database;
    await db.update(
      table,
      {'sync_state': state.toString()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get/Set sync metadata
  Future<SyncMetadata?> getSyncMetadata(String entityId) async {
    final db = await database;
    final result = await db.query(
      'sync_metadata',
      where: 'entity_id = ?',
      whereArgs: [entityId],
      limit: 1,
    );
    return result.isNotEmpty ? SyncMetadata.fromMap(result.first) : null;
  }

  Future<void> setSyncMetadata(SyncMetadata metadata) async {
    final db = await database;
    await db.insert(
      'sync_metadata',
      metadata.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Change operations
  Future<void> addChangeOperation(ChangeOperation operation) async {
    final db = await database;
    await db.insert(
      'change_operations',
      {
        ...operation.toMap(),
        'data': jsonEncode(operation.data),
      },
    );
  }

  Future<List<ChangeOperation>> getUnsyncdChanges() async {
    final db = await database;
    final result = await db.query(
      'change_operations',
      where: 'synced = 0',
      orderBy: 'timestamp ASC',
    );
    
    return result.map((map) {
      final data = Map<String, dynamic>.from(map);
      data['data'] = jsonDecode(data['data']);
      return ChangeOperation.fromMap(data);
    }).toList();
  }

  Future<void> markChangeAsSynced(String changeId) async {
    final db = await database;
    await db.update(
      'change_operations',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [changeId],
    );
  }

  /// Get last sync timestamp for entity type
  Future<int?> getLastSyncTimestamp(String entityType) async {
    final db = await database;
    final result = await db.query(
      'sync_timestamps',
      columns: ['timestamp'],
      where: 'entity_type = ?',
      whereArgs: [entityType],
      limit: 1,
    );
    return result.isNotEmpty ? result.first['timestamp'] as int : null;
  }

  /// Set last sync timestamp for entity type
  Future<void> setLastSyncTimestamp(String entityType, int timestamp) async {
    final db = await database;
    await db.insert(
      'sync_timestamps',
      {'entity_type': entityType, 'timestamp': timestamp},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Save entity from server (simplified version for sync)
  Future<void> saveServerEntity(String entityType, Map<String, dynamic> entity) async {
    final db = await database;
    final tableName = '${entityType}s'; // user -> users, wishlist -> wishlists, etc.
    
    // Convert the entity to match our local schema
    final localEntity = Map<String, dynamic>.from(entity);
    localEntity['sync_state'] = SyncState.synced.toString();
    localEntity['content_hash'] = _generateHash(entity);
    localEntity['version'] = 1; // For now, use simple versioning
    
    await db.insert(
      tableName,
      localEntity,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Simple hash generation for content
  String _generateHash(Map<String, dynamic> data) {
    return data.toString().hashCode.toString();
  }

  /// Clear all data (for testing/reset)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('users');
    await db.delete('wishlists');
    await db.delete('wishes');
    await db.delete('sync_metadata');
    await db.delete('change_operations');
    await db.delete('sync_timestamps');
    debugPrint('🗑️  LocalDatabase: All data cleared');
  }

  /// Close database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}