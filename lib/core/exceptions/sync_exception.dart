import 'package:fitgenie_app/core/exceptions/app_exception.dart';

/// Typed exceptions for offline sync and conflict resolution errors.
///
/// This class handles errors that occur during synchronization between
/// local (Hive) and remote (Firestore) data stores. It provides guidance
/// for conflict resolution and sync queue management.
///
/// Usage in Sync Service:
/// ```dart
/// try {
///   await _syncToFirestore(localData);
/// } catch (e) {
///   if (e is ConflictException) {
///     throw SyncException(
///       SyncErrorType.conflictDetected,
///       'Server data newer than local',
///     );
///   }
/// }
/// ```
///
/// Usage for Conflict Handling:
/// ```dart
/// if (error is SyncException && error.requiresUserAction) {
///   // Show conflict resolution UI
///   await showConflictDialog(localData, serverData);
/// }
/// ```
class SyncException extends AppException {
  /// The specific type of sync error.
  final SyncErrorType type;

  /// Creates a SyncException with the specified error type and message.
  ///
  /// The [type] determines whether user action is required and provides
  /// guidance on resolution strategy.
  /// The [message] contains technical details for debugging.
  const SyncException(this.type, super.message);

  /// Whether this error requires manual user action to resolve.
  ///
  /// When true, the app should:
  /// - Show conflict resolution UI
  /// - Pause automatic sync
  /// - Wait for user decision
  ///
  /// When false, the app can handle resolution automatically.
  bool get requiresUserAction {
    switch (type) {
      case SyncErrorType.conflictDetected:
        // Most conflicts can be auto-resolved using timestamp strategy
        // Only complex conflicts need user intervention
        return false;
      case SyncErrorType.staleData:
        // Auto-resolve by fetching fresh data
        return false;
      case SyncErrorType.queueFull:
        // System can handle by processing queue or discarding old items
        return false;
      case SyncErrorType.syncFailed:
        // Generic sync failures typically retry automatically
        return false;
      case SyncErrorType.invalidData:
        // Data validation failures need developer attention
        return true;
      case SyncErrorType.permissionDenied:
        // User needs to check permissions or re-authenticate
        return true;
    }
  }

  /// Whether this error should trigger an automatic retry.
  ///
  /// Temporary sync failures and network-related errors are retryable.
  bool get isRetryable {
    switch (type) {
      case SyncErrorType.syncFailed:
      case SyncErrorType.staleData:
      case SyncErrorType.queueFull:
        return true;
      case SyncErrorType.conflictDetected:
      case SyncErrorType.invalidData:
      case SyncErrorType.permissionDenied:
        return false;
    }
  }

  /// Resolution strategy for this error type.
  ///
  /// Guidance on how the sync service should handle this error.
  SyncResolutionStrategy get resolutionStrategy {
    switch (type) {
      case SyncErrorType.conflictDetected:
        return SyncResolutionStrategy.useServerTimestamp;
      case SyncErrorType.staleData:
        return SyncResolutionStrategy.fetchFreshData;
      case SyncErrorType.queueFull:
        return SyncResolutionStrategy.processQueueFirst;
      case SyncErrorType.syncFailed:
        return SyncResolutionStrategy.retryWithBackoff;
      case SyncErrorType.invalidData:
        return SyncResolutionStrategy.logAndSkip;
      case SyncErrorType.permissionDenied:
        return SyncResolutionStrategy.requireReauth;
    }
  }

  @override
  String get userFriendlyMessage {
    switch (type) {
      case SyncErrorType.conflictDetected:
        return 'Data conflict detected. Using most recent version.';

      case SyncErrorType.staleData:
        return 'Your data is out of sync. Refreshing...';

      case SyncErrorType.queueFull:
        return 'Too many pending changes. Syncing...';

      case SyncErrorType.syncFailed:
        return 'Sync failed. Will retry when online.';

      case SyncErrorType.invalidData:
        return 'Data validation error. Please contact support.';

      case SyncErrorType.permissionDenied:
        return 'Permission denied. Please check your account.';
    }
  }
}

/// Enumeration of sync error types.
///
/// These types cover common synchronization issues in offline-first apps.
enum SyncErrorType {
  /// Data conflict between local and remote versions
  ///
  /// Both local and remote data have been modified.
  /// Requires conflict resolution strategy.
  conflictDetected,

  /// Local data is older than server data
  ///
  /// The local cache needs to be updated with server version.
  staleData,

  /// Sync queue has reached maximum capacity
  ///
  /// Too many pending operations waiting to sync.
  /// Need to process queue or clear old items.
  queueFull,

  /// Generic sync operation failure
  ///
  /// Sync failed for unknown or network-related reasons.
  /// Should retry automatically.
  syncFailed,

  /// Local or remote data failed validation
  ///
  /// Data structure doesn't match expected schema.
  /// Indicates a bug or schema mismatch.
  invalidData,

  /// User doesn't have permission for sync operation
  ///
  /// Firestore security rules denied the operation.
  /// May need re-authentication.
  permissionDenied,
}

/// Strategy for resolving sync errors.
///
/// Defines how the sync service should handle different error types.
enum SyncResolutionStrategy {
  /// Use server timestamp to determine which version is newer
  ///
  /// Compare timestamps and keep the more recent version.
  /// This is the default conflict resolution strategy.
  useServerTimestamp,

  /// Fetch fresh data from server
  ///
  /// Discard local cache and get latest from server.
  fetchFreshData,

  /// Process sync queue before attempting new operations
  ///
  /// Clear pending operations to make room for new ones.
  processQueueFirst,

  /// Retry with exponential backoff
  ///
  /// Wait and retry, increasing delay with each attempt.
  retryWithBackoff,

  /// Log error and skip this item
  ///
  /// Continue syncing other items, log this failure for review.
  logAndSkip,

  /// Require user to re-authenticate
  ///
  /// Session or permissions issue - user needs to sign in again.
  requireReauth,
}

/// Extension methods for SyncErrorType.
extension SyncErrorTypeExtension on SyncErrorType {
  /// Whether this error indicates a data integrity issue.
  ///
  /// Data integrity errors need careful handling to avoid data loss.
  bool get isDataIntegrityIssue {
    switch (this) {
      case SyncErrorType.conflictDetected:
      case SyncErrorType.invalidData:
        return true;
      case SyncErrorType.staleData:
      case SyncErrorType.queueFull:
      case SyncErrorType.syncFailed:
      case SyncErrorType.permissionDenied:
        return false;
    }
  }

  /// Whether this error should be logged as critical.
  ///
  /// Critical errors indicate bugs or configuration problems.
  bool get isCritical {
    switch (this) {
      case SyncErrorType.invalidData:
      case SyncErrorType.permissionDenied:
        return true;
      case SyncErrorType.conflictDetected:
      case SyncErrorType.staleData:
      case SyncErrorType.queueFull:
      case SyncErrorType.syncFailed:
        return false;
    }
  }

  /// Whether this error should pause automatic sync.
  ///
  /// Some errors require stopping sync until resolved.
  bool get shouldPauseSync {
    switch (this) {
      case SyncErrorType.permissionDenied:
      case SyncErrorType.invalidData:
        return true;
      default:
        return false;
    }
  }

  /// Priority level for sync queue processing.
  ///
  /// Higher priority errors should be processed first.
  /// Returns 0 (lowest) to 3 (highest).
  int get queuePriority {
    switch (this) {
      case SyncErrorType.conflictDetected:
        return 3; // Highest - resolve conflicts immediately
      case SyncErrorType.staleData:
        return 2; // High - user needs fresh data
      case SyncErrorType.permissionDenied:
        return 2; // High - blocks other operations
      case SyncErrorType.invalidData:
        return 1; // Medium - needs investigation
      case SyncErrorType.syncFailed:
        return 1; // Medium - retry when possible
      case SyncErrorType.queueFull:
        return 0; // Low - queue management issue
    }
  }

  /// Technical description for logging purposes.
  String get technicalDescription {
    switch (this) {
      case SyncErrorType.conflictDetected:
        return 'Local and remote data both modified - conflict resolution needed';
      case SyncErrorType.staleData:
        return 'Local cache is older than server version';
      case SyncErrorType.queueFull:
        return 'Sync queue capacity exceeded';
      case SyncErrorType.syncFailed:
        return 'Synchronization operation failed';
      case SyncErrorType.invalidData:
        return 'Data validation failed - schema mismatch';
      case SyncErrorType.permissionDenied:
        return 'Firestore security rules denied operation';
    }
  }

  /// Recommended action for developers.
  String get developerGuidance {
    switch (this) {
      case SyncErrorType.conflictDetected:
        return 'Review conflict resolution strategy - ensure timestamp comparison is working';
      case SyncErrorType.staleData:
        return 'Check cache invalidation logic and sync frequency';
      case SyncErrorType.queueFull:
        return 'Increase queue size or implement queue cleanup strategy';
      case SyncErrorType.syncFailed:
        return 'Check network connectivity and Firestore connection';
      case SyncErrorType.invalidData:
        return 'CRITICAL: Data schema mismatch - review Firestore schema and Freezed models';
      case SyncErrorType.permissionDenied:
        return 'CRITICAL: Check Firestore security rules and user authentication';
    }
  }
}

/// Extension methods for SyncResolutionStrategy.
extension SyncResolutionStrategyExtension on SyncResolutionStrategy {
  /// Human-readable description of the resolution strategy.
  String get description {
    switch (this) {
      case SyncResolutionStrategy.useServerTimestamp:
        return 'Compare timestamps and use newer version';
      case SyncResolutionStrategy.fetchFreshData:
        return 'Discard local cache and fetch from server';
      case SyncResolutionStrategy.processQueueFirst:
        return 'Process pending operations before new ones';
      case SyncResolutionStrategy.retryWithBackoff:
        return 'Retry with increasing delay between attempts';
      case SyncResolutionStrategy.logAndSkip:
        return 'Log error and continue with other items';
      case SyncResolutionStrategy.requireReauth:
        return 'User must sign in again';
    }
  }

  /// Whether this strategy can be executed automatically.
  ///
  /// Some strategies require user intervention.
  bool get isAutomatic {
    switch (this) {
      case SyncResolutionStrategy.useServerTimestamp:
      case SyncResolutionStrategy.fetchFreshData:
      case SyncResolutionStrategy.processQueueFirst:
      case SyncResolutionStrategy.retryWithBackoff:
      case SyncResolutionStrategy.logAndSkip:
        return true;
      case SyncResolutionStrategy.requireReauth:
        return false;
    }
  }
}
