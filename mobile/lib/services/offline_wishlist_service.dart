import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/sync_entity.dart';
import '../models/offline_wishlist.dart';
import '../models/wishlist.dart';
import '../models/wish.dart';
import 'local_database.dart';
import 'sync_manager.dart';
import 'api_service.dart';

/// Offline-first wishlist service that works with or without network
class OfflineWishlistService extends ChangeNotifier {
  final LocalDatabase _localDb = LocalDatabase();
  final SyncManager _syncManager = SyncManager();
  final ApiService _apiService = ApiService();
  final Connectivity _connectivity = Connectivity();
  bool _isInitialized = false;
  Future<void>? _initializing;
  
  List<Wishlist> _wishlists = [];
  Wishlist? _currentWishlist;
  bool _isLoading = false;
  String? _error;
  bool _isOnline = true;
  
  // Getters
  List<Wishlist> get wishlists => _wishlists;
  Wishlist? get currentWishlist => _currentWishlist;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOnline => _isOnline;
  int get pendingChanges => _syncManager.pendingChanges;
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_initializing != null) {
      await _initializing;
      return;
    }

    _initializing = _initializeInternal();
    await _initializing;
  }

  Future<void> _initializeInternal() async {
    try {
      await _localDb.initialize();
      await _syncManager.initialize();

      final connectivityResults = await _connectivity.checkConnectivity();
      _isOnline = connectivityResults.any((result) => result != ConnectivityResult.none);

      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
      );

      await _loadWishlistsFromLocal();

      if (_isOnline) {
        _syncInBackground();
      }

      _isInitialized = true;
      debugPrint('✅ OfflineWishlistService: Initialized (online: $_isOnline)');
    } catch (e) {
      debugPrint('❌ OfflineWishlistService: Initialization failed: $e');
      // Don't crash the app - mark as not initialized and continue
      _isInitialized = false;
    } finally {
      _initializing = null;
    }
  }
  
  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = results.any((result) => result != ConnectivityResult.none);
    
    if (!wasOnline && _isOnline) {
      debugPrint('🌐 OfflineWishlistService: Connection restored, syncing...');
      _syncInBackground();
    } else if (wasOnline && !_isOnline) {
      debugPrint('📴 OfflineWishlistService: Connection lost, working offline');
    }
    
    notifyListeners();
  }
  
  /// Load wishlists from local database
  Future<void> _loadWishlistsFromLocal() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final localWishlists = await _localDb.getEntities('wishlists');
      _wishlists = localWishlists
          .map((data) => OfflineWishlist.fromLocalDb(data).toWishlist())
          .toList();
      
      // Sort by updated_at desc
      _wishlists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      debugPrint('📦 OfflineWishlistService: Loaded ${_wishlists.length} wishlists from local');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ OfflineWishlistService: Error loading from local: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Sync in background without blocking UI
  void _syncInBackground() {
    _syncManager.syncIfOnline().then((_) {
      // Reload from local after sync
      _loadWishlistsFromLocal();
    }).catchError((e) {
      debugPrint('⚠️  Background sync failed: $e');
    });
  }
  
  /// Force sync and return result
  Future<SyncResult> forceSync() async {
    _error = null;
    notifyListeners();
    
    try {
      final result = await _syncManager.performFullSync();
      await _loadWishlistsFromLocal();
      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return SyncResult.error(e.toString());
    }
  }
  
  /// Fetch wishlists (tries online first, falls back to local)
  Future<void> fetchWishlists() async {
    if (_isOnline) {
      await _fetchWishlistsOnline();
    } else {
      await _loadWishlistsFromLocal();
    }
  }
  
  /// Fetch wishlists from API and update local
  Future<void> _fetchWishlistsOnline() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final response = await _apiService.get('/wishlists');
      final wishlistsData = response['wishlists'] as List;
      
      // Save to local database
      for (final data in wishlistsData) {
        final offlineWishlist = OfflineWishlist.fromApi(data);
        await _localDb.upsertEntity('wishlists', offlineWishlist.toLocalDb());
      }
      
      // Reload from local
      await _loadWishlistsFromLocal();
      
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ OfflineWishlistService: Error fetching online: $e');
      // Fall back to local data
      await _loadWishlistsFromLocal();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Get wishlist by ID (checks local cache first)
  Future<void> fetchWishlist(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      // Check local cache first
      final localData = await _localDb.getEntity('wishlists', id);
      if (localData != null) {
        final offlineWishlist = OfflineWishlist.fromLocalDb(localData);
        
        // Load wishes for this wishlist
        final wishes = await _loadWishesForWishlist(id);
        _currentWishlist = offlineWishlist.toWishlist().copyWith(wishes: wishes);
        
        debugPrint('📦 OfflineWishlistService: Loaded wishlist from cache');
        notifyListeners();
        
        // If online, try to fetch latest version in background
        if (_isOnline) {
          _fetchWishlistOnline(id);
        }
        return;
      }
      
      // If not in cache and online, fetch from API
      if (_isOnline) {
        await _fetchWishlistOnline(id);
      } else {
        _error = 'Wishlist not found offline';
      }
      
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ OfflineWishlistService: Error fetching wishlist: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Fetch single wishlist from API
  Future<void> _fetchWishlistOnline(String id) async {
    try {
      final response = await _apiService.get('/wishlists/$id');
      final wishlistData = response['wishlist'];
      
      final offlineWishlist = OfflineWishlist.fromApi(wishlistData);
      await _localDb.upsertEntity('wishlists', offlineWishlist.toLocalDb());
      
      // Load and save wishes
      final wishesData = wishlistData['wishes'] as List? ?? [];
      final wishes = <Wish>[];
      
      for (final wishData in wishesData) {
        // Save wish to local DB (implement OfflineWish similarly)
        wishes.add(Wish.fromJson(wishData));
      }
      
      _currentWishlist = offlineWishlist.toWishlist().copyWith(wishes: wishes);
      notifyListeners();
      
    } catch (e) {
      debugPrint('❌ Failed to fetch wishlist online: $e');
      // Don't update error state as we may have cached data
    }
  }
  
  /// Load wishes for a wishlist from local database
  Future<List<Wish>> _loadWishesForWishlist(String wishlistId) async {
    final wishesData = await _localDb.getEntities(
      'wishes',
      where: 'wishlist_id = ?',
      whereArgs: [wishlistId],
      orderBy: 'created_at ASC',
    );
    
    return wishesData.map((data) => _wishFromLocalDb(data)).toList();
  }
  
  /// Convert local DB data to Wish
  Wish _wishFromLocalDb(Map<String, dynamic> data) {
    return Wish(
      id: data['id'],
      wishlistId: data['wishlist_id'],
      title: data['title'],
      description: data['description'],
      price: data['price']?.toDouble(),
      currency: data['currency'] ?? 'USD',
      url: data['url'],
      images: data['images'] != null 
          ? List<String>.from(jsonDecode(data['images']))
          : const [],
      brand: data['brand'],
      category: data['category'],
      priority: data['priority'] ?? 1,
      quantity: data['quantity'] ?? 1,
      notes: data['notes'],
      status: (data['is_reserved'] ?? 0) == 1 ? 'reserved' : 'available',
      reservedBy: data['reserved_by'],
      reservedAt: data['reserved_at'] != null 
          ? DateTime.parse(data['reserved_at'])
          : null,
      reserverName: data['reserver_name'],
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
    );
  }
  
  /// Create new wishlist (works offline)
  Future<Wishlist?> createWishlist({
    required String name,
    String? description,
    String visibility = 'private',
  }) async {
    try {
      final now = DateTime.now();
      final id = _generateId();
      
      final offlineWishlist = OfflineWishlist(
        id: id,
        name: name,
        description: description,
        visibility: visibility,
        userId: 'current_user', // Get from auth service
        createdAt: now,
        updatedAt: now,
        version: 1,
        deviceId: await _getDeviceId(),
        syncState: _isOnline ? SyncState.pending : SyncState.offline,
      );
      
      // Save to local database
      await _localDb.upsertEntity('wishlists', offlineWishlist.toLocalDb());
      
      // Add change operation for sync
      await _addChangeOperation(
        entityId: id,
        entityType: 'wishlist',
        operation: 'create',
        data: offlineWishlist.toApiSync(),
      );
      
      // Reload wishlists
      await _loadWishlistsFromLocal();
      
      // Try to sync if online
      if (_isOnline) {
        _syncInBackground();
      }
      
      debugPrint('✅ OfflineWishlistService: Created wishlist offline');
      return offlineWishlist.toWishlist();
      
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ OfflineWishlistService: Error creating wishlist: $e');
      notifyListeners();
      return null;
    }
  }
  
  /// Update wishlist (works offline)
  Future<bool> updateWishlist(
    String id, {
    String? name,
    String? description,
    String? visibility,
  }) async {
    try {
      final localData = await _localDb.getEntity('wishlists', id);
      if (localData == null) {
        _error = 'Wishlist not found';
        notifyListeners();
        return false;
      }
      
      final offlineWishlist = OfflineWishlist.fromLocalDb(localData);
      final updatedWishlist = offlineWishlist.copyWithUpdate(
        name: name,
        description: description,
        visibility: visibility,
        deviceId: await _getDeviceId(),
      );
      
      // Save to local database
      await _localDb.upsertEntity('wishlists', updatedWishlist.toLocalDb());
      
      // Add change operation for sync
      await _addChangeOperation(
        entityId: id,
        entityType: 'wishlist',
        operation: 'update',
        data: updatedWishlist.toApiSync(),
      );
      
      // Reload wishlists
      await _loadWishlistsFromLocal();
      
      // Update current wishlist if it's the one being edited
      if (_currentWishlist?.id == id) {
        final wishes = await _loadWishesForWishlist(id);
        _currentWishlist = updatedWishlist.toWishlist().copyWith(wishes: wishes);
        notifyListeners();
      }
      
      // Try to sync if online
      if (_isOnline) {
        _syncInBackground();
      }
      
      debugPrint('✅ OfflineWishlistService: Updated wishlist offline');
      return true;
      
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ OfflineWishlistService: Error updating wishlist: $e');
      notifyListeners();
      return false;
    }
  }
  
  /// Delete wishlist (works offline)
  Future<bool> deleteWishlist(String id) async {
    try {
      // Mark as deleted in local database
      await _localDb.updateSyncState('wishlists', id, SyncState.deleted);
      
      // Add change operation for sync
      await _addChangeOperation(
        entityId: id,
        entityType: 'wishlist',
        operation: 'delete',
        data: {'id': id},
      );
      
      // Remove from local list
      _wishlists.removeWhere((w) => w.id == id);
      if (_currentWishlist?.id == id) {
        _currentWishlist = null;
      }
      
      notifyListeners();
      
      // Try to sync if online
      if (_isOnline) {
        _syncInBackground();
      }
      
      debugPrint('✅ OfflineWishlistService: Marked wishlist for deletion');
      return true;
      
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ OfflineWishlistService: Error deleting wishlist: $e');
      notifyListeners();
      return false;
    }
  }
  
  /// Add change operation for sync
  Future<void> _addChangeOperation({
    required String entityId,
    required String entityType,
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    final changeOperation = ChangeOperation(
      id: _generateId(),
      entityId: entityId,
      entityType: entityType,
      operation: operation,
      data: data,
      timestamp: DateTime.now(),
      deviceId: await _getDeviceId(),
    );
    
    await _localDb.addChangeOperation(changeOperation);
  }
  
  /// Generate unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }
  
  /// Get device ID
  Future<String> _getDeviceId() async {
    // In a real app, you'd use device_info_plus
    return 'device_${Random().nextInt(10000)}';
  }
  
  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
