import 'package:hive/hive.dart';
import 'package:fitgenie_app/shared/services/hive_service.dart';

part 'sync_queue.g.dart';

/// Represents the type of operation queued for synchronization.
enum SyncOperationType {
  /// Create a new resource on the server
  create,

  /// Update an existing resource on the server
  update,

  /// Delete a resource from the server
  delete,
}

/// Represents a single queued operation awaiting synchronization.
///
/// Each item contains the operation type, serialized data, and metadata
/// for retry management and ordering.
@HiveType(typeId: 30)
class SyncQueueItem {
  /// Unique identifier for this queue item (generated timestamp-based)
  @HiveField(0)
  final String id;

  /// Type of operation to perform (create, update, delete)
  @HiveField(1)
  final SyncOperationType operation;

  /// Collection/resource path (e.g., 'completions', 'plans', 'profile')
  @HiveField(2)
  final String collection;

  /// Serialized JSON data for the operation
  @HiveField(3)
  final Map<String, dynamic> data;

  /// Timestamp when this item was enqueued
  @HiveField(4)
  final DateTime enqueuedAt;

  /// Number of sync attempts for this item
  @HiveField(5)
  final int retryCount;

  /// Timestamp of last sync attempt (null if never attempted)
  @HiveField(6)
  final DateTime? lastAttemptAt;

  SyncQueueItem({
    required this.id,
    required this.operation,
    required this.collection,
    required this.data,
    required this.enqueuedAt,
    this.retryCount = 0,
    this.lastAttemptAt,
  });

  /// Creates a copy with updated fields (for retry tracking)
  SyncQueueItem copyWith({
    String? id,
    SyncOperationType? operation,
    String? collection,
    Map<String, dynamic>? data,
    DateTime? enqueuedAt,
    int? retryCount,
    DateTime? lastAttemptAt,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      operation: operation ?? this.operation,
      collection: collection ?? this.collection,
      data: data ?? this.data,
      enqueuedAt: enqueuedAt ?? this.enqueuedAt,
      retryCount: retryCount ?? this.retryCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
    );
  }
}

/// Manages a persistent FIFO queue for offline operations awaiting synchronization.
///
/// This service provides a reliable queue that survives app restarts, allowing
/// operations performed while offline to be synchronized when connectivity is restored.
///
/// Features:
/// - FIFO ordering ensures operations sync in the correct sequence
/// - Retry tracking with configurable max attempts
/// - Max queue size to prevent unbounded growth
/// - Crash-safe persistence via Hive
///
/// Usage:
/// ```dart
/// final queue = SyncQueue();
///
/// // Enqueue an operation while offline
/// await queue.enqueue(
///   operation: SyncOperationType.create,
///   collection: 'completions',
///   data: completionJson,
/// );
///
/// // Process queue when online
/// while (queue.hasItems) {
///   final item = queue.peek();
///   try {
///     await syncToServer(item);
///     await queue.dequeue();
///   } catch (e) {
///     await queue.markAttemptFailed(item.id);
///   }
/// }
/// ```
class SyncQueue {
  /// Maximum number of items allowed in the queue
  static const int maxQueueSize = 1000;

  /// Maximum retry attempts before permanently failing an item
  static const int maxRetryAttempts = 5;

  /// Internal key for storing queue items in order
  static const String _queueOrderKey = 'queue_order';

  /// Returns the Hive box used for sync queue storage
  Box<dynamic> get _box => HiveService.syncQueueBox;

  /// Returns the current number of items in the queue
  int get length {
    final order = _getQueueOrder();
    return order.length;
  }

  /// Returns true if the queue has items awaiting synchronization
  bool get hasItems => length > 0;

  /// Returns true if the queue is empty
  bool get isEmpty => length == 0;

  /// Enqueues a new operation for synchronization.
  ///
  /// The operation will be added to the end of the queue (FIFO).
  ///
  /// Parameters:
  /// - [operation]: Type of operation (create, update, delete)
  /// - [collection]: Resource collection/path (e.g., 'completions')
  /// - [data]: Serialized operation data as JSON map
  ///
  /// Throws [StateError] if queue is at maximum capacity.
  /// Returns the generated item ID.
  Future<String> enqueue({
    required SyncOperationType operation,
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    if (length >= maxQueueSize) {
      throw StateError(
        'Sync queue is at maximum capacity ($maxQueueSize items). '
        'Cannot enqueue new operations until existing items are synced.',
      );
    }

    // Generate unique ID using timestamp and random component
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final id = '${timestamp}_${data.hashCode.abs()}';

    final item = SyncQueueItem(
      id: id,
      operation: operation,
      collection: collection,
      data: data,
      enqueuedAt: DateTime.now(),
    );

    // Store item data
    await _box.put(id, _serializeItem(item));

    // Update queue order
    final order = _getQueueOrder();
    order.add(id);
    await _box.put(_queueOrderKey, order);

    return id;
  }

  /// Returns the first item in the queue without removing it.
  ///
  /// Returns null if queue is empty.
  ///
  /// Use this to inspect the next item to be processed, then call [dequeue]
  /// after successful synchronization.
  SyncQueueItem? peek() {
    if (isEmpty) return null;

    final order = _getQueueOrder();
    final firstId = order.first;

    final itemData = _box.get(firstId);
    if (itemData == null) {
      // Corrupted state: ID in order but no data
      // Remove from order and try next
      _removeFromOrder(firstId);
      return peek();
    }

    return _deserializeItem(itemData);
  }

  /// Returns all items in the queue in FIFO order.
  ///
  /// Useful for displaying queue status or batch processing.
  List<SyncQueueItem> getAll() {
    final order = _getQueueOrder();
    final items = <SyncQueueItem>[];

    for (final id in order) {
      final itemData = _box.get(id);
      if (itemData != null) {
        items.add(_deserializeItem(itemData));
      }
    }

    return items;
  }

  /// Removes the first item from the queue after successful synchronization.
  ///
  /// Call this after successfully processing the item returned by [peek].
  ///
  /// Returns true if item was removed, false if queue was already empty.
  Future<bool> dequeue() async {
    if (isEmpty) return false;

    final order = _getQueueOrder();
    final firstId = order.first;

    // Remove item data
    await _box.delete(firstId);

    // Update queue order
    order.removeAt(0);
    await _box.put(_queueOrderKey, order);

    return true;
  }

  /// Removes a specific item from the queue by ID.
  ///
  /// Use this to remove items that have exceeded max retry attempts
  /// or need to be manually cleared.
  ///
  /// Returns true if item was found and removed.
  Future<bool> remove(String id) async {
    final order = _getQueueOrder();

    if (!order.contains(id)) {
      return false;
    }

    // Remove item data
    await _box.delete(id);

    // Update queue order
    order.remove(id);
    await _box.put(_queueOrderKey, order);

    return true;
  }

  /// Marks a sync attempt as failed and increments retry count.
  ///
  /// If the item has exceeded [maxRetryAttempts], it will be automatically
  /// removed from the queue.
  ///
  /// Returns true if item was updated, false if item was removed due to
  /// max retries exceeded.
  Future<bool> markAttemptFailed(String id) async {
    final itemData = _box.get(id);
    if (itemData == null) return false;

    final item = _deserializeItem(itemData);
    final newRetryCount = item.retryCount + 1;

    // Check if max retries exceeded
    if (newRetryCount >= maxRetryAttempts) {
      // Remove item permanently
      await remove(id);
      return false;
    }

    // Update item with new retry count and attempt timestamp
    final updatedItem = item.copyWith(
      retryCount: newRetryCount,
      lastAttemptAt: DateTime.now(),
    );

    await _box.put(id, _serializeItem(updatedItem));
    return true;
  }

  /// Clears all items from the queue.
  ///
  /// WARNING: This permanently removes all pending operations.
  /// Use with caution, typically only for logout or data reset scenarios.
  Future<void> clear() async {
    await _box.clear();
  }

  /// Returns items that have failed multiple times and may need attention.
  ///
  /// These items have retry counts above the threshold but haven't yet
  /// reached [maxRetryAttempts].
  List<SyncQueueItem> getProblematicItems({int threshold = 3}) {
    final allItems = getAll();
    return allItems.where((item) => item.retryCount >= threshold).toList();
  }

  /// Retrieves the queue order list from storage.
  List<String> _getQueueOrder() {
    final orderData = _box.get(_queueOrderKey);
    if (orderData == null) return [];

    // Handle both List<dynamic> and List<String>
    if (orderData is List) {
      return orderData.cast<String>();
    }

    return [];
  }

  /// Removes an ID from the queue order list.
  Future<void> _removeFromOrder(String id) async {
    final order = _getQueueOrder();
    order.remove(id);
    await _box.put(_queueOrderKey, order);
  }

  /// Serializes a SyncQueueItem to a Map for Hive storage.
  Map<String, dynamic> _serializeItem(SyncQueueItem item) {
    return {
      'id': item.id,
      'operation': item.operation.index,
      'collection': item.collection,
      'data': item.data,
      'enqueuedAt': item.enqueuedAt.toIso8601String(),
      'retryCount': item.retryCount,
      'lastAttemptAt': item.lastAttemptAt?.toIso8601String(),
    };
  }

  /// Deserializes a Map from Hive storage to a SyncQueueItem.
  SyncQueueItem _deserializeItem(Map<dynamic, dynamic> data) {
    return SyncQueueItem(
      id: data['id'] as String,
      operation: SyncOperationType.values[data['operation'] as int],
      collection: data['collection'] as String,
      data: Map<String, dynamic>.from(data['data'] as Map),
      enqueuedAt: DateTime.parse(data['enqueuedAt'] as String),
      retryCount: data['retryCount'] as int? ?? 0,
      lastAttemptAt: data['lastAttemptAt'] != null
          ? DateTime.parse(data['lastAttemptAt'] as String)
          : null,
    );
  }
}
