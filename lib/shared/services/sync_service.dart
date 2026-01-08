import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitgenie_app/core/constants/app_strings.dart';
import 'package:fitgenie_app/shared/services/sync_queue.dart';
import 'package:fitgenie_app/shared/providers/connectivity_provider.dart';
import 'package:fitgenie_app/core/utils/retry_helper.dart';
import 'package:fitgenie_app/core/exceptions/sync_exception.dart';
import 'package:fitgenie_app/core/exceptions/network_exception.dart';

/// Background synchronization service managing offline queue processing
/// and conflict resolution.
///
/// This service automatically syncs pending changes when connectivity is restored
/// and provides manual refresh capabilities. It implements exponential backoff
/// for failed sync attempts and handles conflicts using predefined strategies.
///
/// Conflict Resolution Strategies:
/// - Streaks/Counters: Server timestamp wins (server is source of truth)
/// - Completions: Last-write-wins based on timestamp
/// - Profile Updates: Last-write-wins with full document replacement
///
/// Usage:
/// ```dart
/// final syncService = SyncService(
///   firestore: firestore,
///   syncQueue: syncQueue,
///   connectivityProvider: connectivityProvider,
/// );
///
/// // Auto-sync on connectivity restoration
/// await syncService.initialize();
///
/// // Manual sync trigger
/// await syncService.syncPendingChanges();
/// ```
class SyncService {
  final FirebaseFirestore _firestore;
  final SyncQueue _syncQueue;
  final ConnectivityProvider _connectivityProvider;

  /// Subscription to connectivity state changes
  StreamSubscription<bool>? _connectivitySubscription;

  /// Flag to prevent concurrent sync operations
  bool _isSyncing = false;

  SyncService({
    required FirebaseFirestore firestore,
    required SyncQueue syncQueue,
    required ConnectivityProvider connectivityProvider,
  }) : _firestore = firestore,
       _syncQueue = syncQueue,
       _connectivityProvider = connectivityProvider;

  /// Initializes the sync service and sets up connectivity listener.
  ///
  /// Call this once during app initialization to enable automatic
  /// synchronization when connectivity is restored.
  void initialize() {
    _connectivitySubscription = _connectivityProvider.isOnlineStream.listen((
      isOnline,
    ) {
      if (isOnline) {
        // Trigger sync when coming back online
        _autoSync();
      }
    });
  }

  /// Disposes resources and cancels connectivity listener.
  ///
  /// Call this during app shutdown or when the service is no longer needed.
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  /// Synchronizes all pending changes in the queue to Firestore.
  ///
  /// This method processes the sync queue in FIFO order, attempting to
  /// apply each operation to Firestore. Failed operations are retried
  /// with exponential backoff, and conflicts are resolved automatically.
  ///
  /// Returns a [SyncResult] containing success/failure counts and any errors.
  ///
  /// Throws [NetworkException] if device is offline.
  /// Throws [SyncException] if sync fails critically (queue corrupted, etc.).
  Future<SyncResult> syncPendingChanges() async {
    // Check connectivity first
    final isOnline = await _connectivityProvider.checkConnectivity();
    if (!isOnline) {
      throw const NetworkException(
        NetworkErrorType.noConnection,
        AppStrings.errorNoConnection,
      );
    }

    // Prevent concurrent syncs
    if (_isSyncing) {
      return const SyncResult(
        successCount: 0,
        failureCount: 0,
        isComplete: false,
        message: AppStrings.errorSyncFailed,
      );
    }

    _isSyncing = true;

    int successCount = 0;
    int failureCount = 0;
    final errors = <String, String>{};

    try {
      while (_syncQueue.hasItems) {
        final item = _syncQueue.peek();
        if (item == null) break;

        try {
          // Process item with retry logic
          await RetryHelper.retrySyncOperation(() => _processSyncItem(item));

          // Remove from queue after successful sync
          await _syncQueue.dequeue();
          successCount++;
        } catch (e) {
          // Mark attempt as failed and increment retry count
          final shouldRetry = await _syncQueue.markAttemptFailed(item.id);

          if (!shouldRetry) {
            // Item exceeded max retries, permanently removed
            errors[item.id] = 'Max retry attempts exceeded: $e';
            failureCount++;
          } else {
            // Will retry later
            errors[item.id] = 'Sync failed (will retry): $e';
            failureCount++;
          }

          // Break on first failure to maintain order
          // Will retry on next sync attempt
          break;
        }
      }

      return SyncResult(
        successCount: successCount,
        failureCount: failureCount,
        isComplete: _syncQueue.isEmpty,
        errors: errors.isNotEmpty ? errors : null,
      );
    } catch (e) {
      throw SyncException(SyncErrorType.syncFailed, 'Sync process failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Processes a single sync queue item by applying it to Firestore.
  ///
  /// Handles create, update, and delete operations with conflict resolution.
  Future<void> _processSyncItem(SyncQueueItem item) async {
    final collectionRef = _firestore.collection(item.collection);
    final docId = item.data['id'] as String?;

    if (docId == null) {
      throw SyncException(
        SyncErrorType.invalidData,
        'Sync item missing required "id" field. Item ID: ${item.id}',
      );
    }

    final docRef = collectionRef.doc(docId);

    switch (item.operation) {
      case SyncOperationType.create:
        await _handleCreate(docRef, item);
        break;

      case SyncOperationType.update:
        await _handleUpdate(docRef, item);
        break;

      case SyncOperationType.delete:
        await _handleDelete(docRef, item);
        break;
    }
  }

  /// Handles create operation with conflict detection.
  Future<void> _handleCreate(
    DocumentReference docRef,
    SyncQueueItem item,
  ) async {
    try {
      // Check if document already exists (potential conflict)
      final snapshot = await docRef.get();

      if (snapshot.exists) {
        // Document was created elsewhere (likely by another device)
        // Resolve conflict based on timestamps
        await _handleConflict(
          docRef,
          item,
          snapshot.data() as Map<String, dynamic>?,
        );
      } else {
        // No conflict, create document
        await docRef.set(item.data);
      }
    } catch (e) {
      throw SyncException(
        SyncErrorType.syncFailed,
        'Failed to create document: $e. Item ID: ${item.id}',
      );
    }
  }

  /// Handles update operation with conflict resolution.
  Future<void> _handleUpdate(
    DocumentReference docRef,
    SyncQueueItem item,
  ) async {
    try {
      // Fetch current server state
      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        // Document was deleted on server, treat as create
        await docRef.set(item.data);
        return;
      }

      // Check for conflicts based on timestamp
      await _handleConflict(
        docRef,
        item,
        snapshot.data() as Map<String, dynamic>?,
      );
    } catch (e) {
      throw SyncException(
        SyncErrorType.syncFailed,
        'Failed to update document: $e. Item ID: ${item.id}',
      );
    }
  }

  /// Handles delete operation.
  Future<void> _handleDelete(
    DocumentReference docRef,
    SyncQueueItem item,
  ) async {
    try {
      // Delete is idempotent, safe to execute even if already deleted
      await docRef.delete();
    } catch (e) {
      throw SyncException(
        SyncErrorType.syncFailed,
        'Failed to delete document: $e. Item ID: ${item.id}',
      );
    }
  }

  /// Resolves conflicts between local and server data.
  ///
  /// Strategy depends on collection type:
  /// - Streaks/Counters: Server wins (server is authoritative)
  /// - Completions: Last-write-wins based on timestamp comparison
  /// - Profile: Last-write-wins with merge
  Future<void> _handleConflict(
    DocumentReference docRef,
    SyncQueueItem item,
    Map<String, dynamic>? serverData,
  ) async {
    if (serverData == null) {
      // No server data, write local data
      await docRef.set(item.data);
      return;
    }

    // Extract timestamps for comparison
    final localTimestamp = _extractTimestamp(item.data);
    final serverTimestamp = _extractTimestamp(serverData);

    // Determine collection-specific conflict resolution strategy
    if (item.collection == 'streaks' || item.collection == 'stats') {
      // Server timestamp wins for streaks and stats
      // Local changes are discarded as server is source of truth
      return;
    } else if (item.collection == 'completions') {
      // Last-write-wins for completions
      if (localTimestamp.isAfter(serverTimestamp)) {
        // Local is newer, overwrite server
        await docRef.update(item.data);
      }
      // Otherwise, server is newer, local changes discarded
    } else if (item.collection == 'user_profiles') {
      // Last-write-wins with merge for profile updates
      if (localTimestamp.isAfter(serverTimestamp)) {
        // Merge local changes with server data
        final merged = Map<String, dynamic>.from(serverData)..addAll(item.data);
        await docRef.update(merged);
      }
      // Otherwise, server is newer, local changes discarded
    } else {
      // Default: Last-write-wins without merge
      if (localTimestamp.isAfter(serverTimestamp)) {
        await docRef.update(item.data);
      }
    }
  }

  /// Extracts timestamp from document data for conflict resolution.
  ///
  /// Looks for common timestamp fields in order of preference:
  /// 1. updatedAt
  /// 2. completedAt
  /// 3. createdAt
  /// 4. timestamp
  ///
  /// Returns epoch time (1970) if no timestamp found.
  DateTime _extractTimestamp(Map<String, dynamic> data) {
    // Try common timestamp fields
    final timestampFields = [
      'updatedAt',
      'completedAt',
      'createdAt',
      'timestamp',
    ];

    for (final field in timestampFields) {
      final value = data[field];
      if (value != null) {
        if (value is Timestamp) {
          return value.toDate();
        } else if (value is String) {
          try {
            return DateTime.parse(value);
          } catch (_) {
            continue;
          }
        } else if (value is int) {
          return DateTime.fromMillisecondsSinceEpoch(value);
        }
      }
    }

    // No timestamp found, use epoch as fallback (oldest possible)
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Internal auto-sync triggered by connectivity changes.
  ///
  /// Uses fire-and-forget pattern to avoid blocking connectivity listener.
  Future<void> _autoSync() async {
    try {
      await syncPendingChanges();
    } catch (e) {
      // Silent fail for auto-sync, errors will be retried later
      // In production, consider logging to analytics
    }
  }

  /// Returns true if a sync operation is currently in progress.
  bool get isSyncing => _isSyncing;

  /// Returns the number of items currently in the sync queue.
  int get queueLength => _syncQueue.length;

  /// Returns items that have failed multiple times and may need attention.
  List<SyncQueueItem> getProblematicItems() {
    return _syncQueue.getProblematicItems();
  }
}

/// Result of a sync operation containing success/failure metrics.
class SyncResult {
  /// Number of items successfully synchronized
  final int successCount;

  /// Number of items that failed to synchronize
  final int failureCount;

  /// Whether all items in the queue were processed
  final bool isComplete;

  /// Optional message providing additional context
  final String? message;

  /// Map of item IDs to error messages for failed items
  final Map<String, String>? errors;

  const SyncResult({
    required this.successCount,
    required this.failureCount,
    required this.isComplete,
    this.message,
    this.errors,
  });

  /// Returns true if all items synced successfully
  bool get isFullSuccess => failureCount == 0 && successCount > 0;

  /// Returns true if at least one item synced successfully
  bool get hasPartialSuccess => successCount > 0;

  /// Returns true if no items synced successfully
  bool get isFullFailure => successCount == 0 && failureCount > 0;

  @override
  String toString() {
    return 'SyncResult(success: $successCount, failed: $failureCount, '
        'complete: $isComplete${message != null ? ', message: $message' : ''})';
  }
}
