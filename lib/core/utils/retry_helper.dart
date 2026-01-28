import 'dart:async';
import 'dart:math';

import 'package:fitgenie_app/core/exceptions/ai_exception.dart';
import 'package:fitgenie_app/core/exceptions/network_exception.dart';

/// Exponential backoff retry logic for network and AI operations.
///
/// This class provides a generic retry mechanism with exponential backoff
/// for operations that may fail transiently (network issues, rate limits, etc.).
///
/// Critical for reliability:
/// - All Gemini API calls should use this helper
/// - Sync operations should use this for conflict resolution
/// - Network-dependent operations benefit from retry logic
///
/// Usage:
/// ```dart
/// final result = await RetryHelper.withRetry(
///   operation: () => geminiService.generatePlan(profile),
///   shouldRetry: (error) => error is AiException && error.isRetryable,
/// );
/// ```
///
/// Retry Strategy:
/// - Max retries: 3 attempts (4 total including initial attempt)
/// - Delays: 1s, 2s, 4s (exponential backoff with base 2)
/// - Only retries errors that are explicitly retryable
/// - Rethrows final error after max retries
class RetryHelper {
  RetryHelper._(); // Private constructor to prevent instantiation

  /// Maximum number of retry attempts after initial failure.
  ///
  /// Total attempts = maxRetries + 1 (initial attempt).
  /// Example: maxRetries = 3 means 4 total attempts.
  static const int maxRetries = 3;

  /// Base delay in seconds for exponential backoff calculation.
  ///
  /// Delay for attempt N = baseDelay * 2^(N-1)
  /// - Attempt 1: 1s
  /// - Attempt 2: 2s
  /// - Attempt 3: 4s
  static const int baseDelaySeconds = 1;

  /// Executes an async operation with exponential backoff retry logic.
  ///
  /// The [operation] will be attempted up to [maxRetries] + 1 times.
  /// Between attempts, the helper waits with exponentially increasing delays.
  ///
  /// The [shouldRetry] callback determines whether a specific error is
  /// eligible for retry. If null, all errors are retryable by default.
  ///
  /// The [onRetry] callback is called before each retry attempt, useful
  /// for logging or updating UI state.
  ///
  /// Returns the result of the operation if successful.
  /// Throws the last error if all retry attempts fail.
  ///
  /// Example:
  /// ```dart
  /// final plan = await RetryHelper.withRetry<WeeklyPlan>(
  ///   operation: () => geminiService.generatePlan(userProfile),
  ///   shouldRetry: (error) {
  ///     if (error is AiException) {
  ///       return error.isRetryable;
  ///     }
  ///     if (error is NetworkException) {
  ///       return true;
  ///     }
  ///     return false;
  ///   },
  ///   onRetry: (attempt, delay, error) {
  ///     print('Retry attempt $attempt after ${delay}s delay: $error');
  ///   },
  /// );
  /// ```
  static Future<T> withRetry<T>({
    required Future<T> Function() operation,
    bool Function(Object error)? shouldRetry,
    void Function(int attempt, int delaySeconds, Object error)? onRetry,
  }) async {
    int attempt = 0;
    Object? lastError;

    while (attempt <= maxRetries) {
      try {
        // Attempt the operation
        return await operation();
      } catch (error) {
        lastError = error;

        // Check if we should retry
        final canRetry = shouldRetry?.call(error) ?? _defaultShouldRetry(error);

        // If this is the last attempt or error is not retryable, rethrow
        if (attempt >= maxRetries || !canRetry) {
          rethrow;
        }

        // Calculate exponential backoff delay (AI-aware)
        final delaySeconds = _calculateDelay(attempt, error);

        // Notify about retry
        onRetry?.call(attempt + 1, delaySeconds, error);

        // Wait before retrying
        await Future.delayed(Duration(seconds: delaySeconds));

        attempt++;
      }
    }

    // This should never be reached, but throw last error just in case
    throw lastError ?? Exception('Retry failed with unknown error');
  }

  /// Executes an async operation with retry logic and a timeout.
  ///
  /// Combines retry logic with a timeout constraint. The operation must
  /// complete within [timeoutDuration] or it will be cancelled and retried.
  ///
  /// Example:
  /// ```dart
  /// final result = await RetryHelper.withRetryAndTimeout(
  ///   operation: () => apiCall(),
  ///   timeoutDuration: Duration(seconds: 10),
  ///   shouldRetry: (error) => error is TimeoutException || error is NetworkException,
  /// );
  /// ```
  static Future<T> withRetryAndTimeout<T>({
    required Future<T> Function() operation,
    required Duration timeoutDuration,
    bool Function(Object error)? shouldRetry,
    void Function(int attempt, int delaySeconds, Object error)? onRetry,
  }) async {
    return withRetry<T>(
      operation: () => operation().timeout(timeoutDuration),
      shouldRetry: shouldRetry,
      onRetry: onRetry,
    );
  }

  /// Executes multiple operations in parallel with retry logic.
  ///
  /// Each operation is retried independently. Returns results in the same
  /// order as the input operations.
  ///
  /// If any operation fails after all retries, the entire future fails.
  ///
  /// Example:
  /// ```dart
  /// final results = await RetryHelper.withRetryParallel([
  ///   () => fetchUser(),
  ///   () => fetchPlan(),
  ///   () => fetchCompletions(),
  /// ]);
  /// ```
  static Future<List<T>> withRetryParallel<T>(
    List<Future<T> Function()> operations, {
    bool Function(Object error)? shouldRetry,
    void Function(int attempt, int delaySeconds, Object error)? onRetry,
  }) async {
    final futures = operations.map((operation) {
      return withRetry<T>(
        operation: operation,
        shouldRetry: shouldRetry,
        onRetry: onRetry,
      );
    }).toList();

    return Future.wait(futures);
  }

  // ==========================================================================
  // PRIVATE HELPERS
  // ==========================================================================

  /// Calculates exponential backoff delay for a given retry attempt.
  ///
  /// Formula: baseDelay * 2^attempt
  /// - Attempt 0: 1 * 2^0 = 1 second
  /// - Attempt 1: 1 * 2^1 = 2 seconds
  /// - Attempt 2: 1 * 2^2 = 4 seconds
  ///
  /// Returns delay in seconds.
  static int _calculateDelay(int attempt, Object error) {
    final baseDelay = baseDelaySeconds * pow(2, attempt).toInt();

    if (error is AiException) {
      return max(baseDelay, error.recommendedRetryDelaySeconds);
    }

    return baseDelay;
  }

  /// Default retry eligibility check.
  ///
  /// By default, retries:
  /// - AiException if isRetryable is true
  /// - NetworkException (all types)
  /// - TimeoutException
  ///
  /// Does not retry:
  /// - Other exception types (parse errors, validation errors, etc.)
  static bool _defaultShouldRetry(Object error) {
    // AiException with retryable flag
    if (error is AiException) {
      return error.isRetryable;
    }

    // Network exceptions are generally retryable
    if (error is NetworkException) {
      return error.isRetryable;
    }

    // Timeout exceptions are retryable
    if (error is TimeoutException) {
      return true;
    }

    // By default, don't retry other exceptions
    return false;
  }

  // ==========================================================================
  // SPECIALIZED RETRY HELPERS
  // ==========================================================================

  /// Specialized retry helper for Gemini API calls.
  ///
  /// Uses AI-specific retry logic with appropriate delays for rate limits.
  ///
  /// Example:
  /// ```dart
  /// final plan = await RetryHelper.retryGeminiCall(
  ///   () => geminiModel.generateContent(prompt),
  /// );
  /// ```
  static Future<T> retryGeminiCall<T>(
    Future<T> Function() operation, {
    void Function(int attempt, int delaySeconds, Object error)? onRetry,
  }) async {
    return withRetry<T>(
      operation: operation,
      shouldRetry: (error) {
        // Retry AI exceptions that are marked as retryable
        if (error is AiException) {
          return error.isRetryable;
        }
        // Also retry timeout exceptions
        if (error is TimeoutException) {
          return true;
        }
        return false;
      },
      onRetry: onRetry,
    );
  }

  /// Specialized retry helper for Firestore operations.
  ///
  /// Uses network-specific retry logic.
  ///
  /// Example:
  /// ```dart
  /// await RetryHelper.retryFirestoreOperation(
  ///   () => firestore.collection('users').doc(uid).set(data),
  /// );
  /// ```
  static Future<T> retryFirestoreOperation<T>(
    Future<T> Function() operation, {
    void Function(int attempt, int delaySeconds, Object error)? onRetry,
  }) async {
    return withRetry<T>(
      operation: operation,
      shouldRetry: (error) {
        // Retry network exceptions
        if (error is NetworkException) {
          return error.isRetryable;
        }
        // Retry timeout exceptions
        if (error is TimeoutException) {
          return true;
        }
        return false;
      },
      onRetry: onRetry,
    );
  }

  /// Specialized retry helper for sync operations.
  ///
  /// Uses aggressive retry for background sync tasks.
  ///
  /// Example:
  /// ```dart
  /// await RetryHelper.retrySyncOperation(
  ///   () => syncService.syncCompletions(),
  /// );
  /// ```
  static Future<T> retrySyncOperation<T>(
    Future<T> Function() operation, {
    void Function(int attempt, int delaySeconds, Object error)? onRetry,
  }) async {
    return withRetry<T>(
      operation: operation,
      shouldRetry: (error) {
        // Retry most errors for sync operations (except parse/validation errors)
        if (error is NetworkException) return true;
        if (error is TimeoutException) return true;
        if (error is AiException) return error.isRetryable;

        // Don't retry programming errors (null checks, type errors, etc.)
        if (error is TypeError) return false;
        if (error is ArgumentError) return false;

        // By default, retry for sync operations
        return true;
      },
      onRetry: onRetry,
    );
  }
}
