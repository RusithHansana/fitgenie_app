import 'dart:async';
import 'package:hive/hive.dart';
import 'package:fitgenie_app/core/constants/rate_limit_config.dart';

/// Result of a rate limit check indicating which limit would be exceeded.
enum RateLimitExceeded {
  /// No limit exceeded, request can proceed.
  none,

  /// Requests per minute limit would be exceeded.
  rpm,

  /// Requests per day limit would be exceeded.
  rpd,

  /// Daily token limit would be exceeded.
  tokens,
}

/// Comprehensive rate limiter for Gemini API requests.
///
/// Manages three types of limits:
/// - **RPM (Requests Per Minute)**: In-memory, resets on app restart
/// - **RPD (Requests Per Day)**: Persisted in Hive, survives app restarts
/// - **Tokens**: Daily token budget persisted in Hive
///
/// The limiter stops requests ONE BEFORE the limit to prevent hitting the API limit.
///
/// Usage:
/// ```dart
/// final limiter = RateLimiter();
/// await limiter.initialize();
///
/// // Check before making request
/// final check = limiter.canMakeRequest(estimatedTokens: 5000);
/// if (check != RateLimitExceeded.none) {
///   throw AiException(AiErrorType.localRateLimitExceeded, 'Limit exceeded');
/// }
///
/// // After successful request
/// await limiter.recordRequest(tokensUsed: 5000);
/// ```
class RateLimiter {
  /// Singleton instance for global access.
  static final RateLimiter _instance = RateLimiter._internal();

  /// Factory constructor returns singleton instance.
  factory RateLimiter() => _instance;

  RateLimiter._internal();

  /// Whether the rate limiter has been initialized.
  bool _isInitialized = false;

  /// Hive box for persistent storage.
  Box<dynamic>? _box;

  /// Timestamps of recent requests for RPM tracking (in-memory).
  final List<DateTime> _recentRequests = [];

  /// Queue for serializing operations.
  Future<void> _queue = Future.value();

  // ==========================================================================
  // INITIALIZATION
  // ==========================================================================

  /// Initializes the rate limiter with Hive storage.
  ///
  /// Must be called before using any other methods.
  /// Safe to call multiple times - subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_isInitialized) return;

    _box = await Hive.openBox(RateLimitConfig.hiveBoxName);
    await _resetIfNewDay();
    _isInitialized = true;
  }

  /// Ensures the rate limiter is initialized before use.
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('RateLimiter not initialized. Call initialize() first.');
    }
  }

  // ==========================================================================
  // RATE LIMIT CHECKING
  // ==========================================================================

  /// Checks if a request can be made without exceeding any limits.
  ///
  /// Returns [RateLimitExceeded.none] if the request can proceed.
  /// Otherwise returns which limit would be exceeded.
  ///
  /// Parameters:
  /// - [estimatedTokens]: Estimated tokens for the request prompt
  RateLimitExceeded canMakeRequest({required int estimatedTokens}) {
    _ensureInitialized();

    // Check RPM (in-memory)
    _cleanupExpiredTimestamps();
    if (_recentRequests.length >= RateLimitConfig.effectiveRpm) {
      return RateLimitExceeded.rpm;
    }

    // Check RPD (persisted)
    final dailyCount =
        _box!.get(RateLimitConfig.dailyRequestCountKey, defaultValue: 0) as int;
    if (dailyCount >= RateLimitConfig.effectiveRpd) {
      return RateLimitExceeded.rpd;
    }

    // Check tokens (persisted)
    final dailyTokens =
        _box!.get(RateLimitConfig.dailyTokensUsedKey, defaultValue: 0) as int;
    if (dailyTokens + estimatedTokens > RateLimitConfig.effectiveMaxTokens) {
      return RateLimitExceeded.tokens;
    }

    return RateLimitExceeded.none;
  }

  /// Removes timestamps outside the RPM window.
  void _cleanupExpiredTimestamps() {
    final now = DateTime.now();
    _recentRequests.removeWhere(
      (t) => now.difference(t) >= RateLimitConfig.rpmWindow,
    );
  }

  // ==========================================================================
  // REQUEST RECORDING
  // ==========================================================================

  /// Records a successful request and updates all counters.
  ///
  /// Call this after a successful API request to track usage.
  ///
  /// Parameters:
  /// - [tokensUsed]: Actual tokens used in the request
  Future<void> recordRequest({required int tokensUsed}) async {
    _ensureInitialized();

    // Serialize to prevent race conditions
    _queue = _queue.then((_) => _recordRequestInternal(tokensUsed));
    return _queue;
  }

  Future<void> _recordRequestInternal(int tokensUsed) async {
    // Check for day rollover before recording
    await _resetIfNewDay();

    // Record RPM timestamp (in-memory)
    _recentRequests.add(DateTime.now());

    // Update daily request count
    final currentCount =
        _box!.get(RateLimitConfig.dailyRequestCountKey, defaultValue: 0) as int;
    await _box!.put(RateLimitConfig.dailyRequestCountKey, currentCount + 1);

    // Update daily token usage
    final currentTokens =
        _box!.get(RateLimitConfig.dailyTokensUsedKey, defaultValue: 0) as int;
    await _box!.put(
      RateLimitConfig.dailyTokensUsedKey,
      currentTokens + tokensUsed,
    );
  }

  // ==========================================================================
  // DAY RESET LOGIC
  // ==========================================================================

  /// Resets daily counters if a new day has started.
  Future<void> _resetIfNewDay() async {
    final today = _getTodayString();
    final lastReset =
        _box!.get(RateLimitConfig.lastResetDateKey, defaultValue: '') as String;

    if (lastReset != today) {
      await _box!.put(RateLimitConfig.lastResetDateKey, today);
      await _box!.put(RateLimitConfig.dailyRequestCountKey, 0);
      await _box!.put(RateLimitConfig.dailyTokensUsedKey, 0);
    }
  }

  /// Returns today's date as ISO string (YYYY-MM-DD).
  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ==========================================================================
  // STATUS GETTERS
  // ==========================================================================

  /// Gets the current daily request count.
  int get dailyRequestCount {
    _ensureInitialized();
    return _box!.get(RateLimitConfig.dailyRequestCountKey, defaultValue: 0)
        as int;
  }

  /// Gets the current daily token usage.
  int get dailyTokensUsed {
    _ensureInitialized();
    return _box!.get(RateLimitConfig.dailyTokensUsedKey, defaultValue: 0)
        as int;
  }

  /// Gets the remaining requests for today.
  int get remainingDailyRequests {
    _ensureInitialized();
    final used = dailyRequestCount;
    final remaining = RateLimitConfig.effectiveRpd - used;
    return remaining > 0 ? remaining : 0;
  }

  /// Gets the remaining tokens for today.
  int get remainingDailyTokens {
    _ensureInitialized();
    final used = dailyTokensUsed;
    final remaining = RateLimitConfig.effectiveMaxTokens - used;
    return remaining > 0 ? remaining : 0;
  }

  /// Gets the number of requests in the current minute window.
  int get requestsInCurrentWindow {
    _cleanupExpiredTimestamps();
    return _recentRequests.length;
  }

  /// Gets remaining requests in the current minute window.
  int get remainingRpmRequests {
    _cleanupExpiredTimestamps();
    final remaining = RateLimitConfig.effectiveRpm - _recentRequests.length;
    return remaining > 0 ? remaining : 0;
  }

  // ==========================================================================
  // LEGACY SUPPORT
  // ==========================================================================

  /// Legacy acquire method for backward compatibility.
  ///
  /// Waits until an RPM slot is available.
  /// Prefer using [canMakeRequest] and [recordRequest] for new code.
  @Deprecated('Use canMakeRequest() and recordRequest() instead')
  Future<void> acquire() async {
    _queue = _queue.then((_) => _acquireLegacy());
    return _queue;
  }

  Future<void> _acquireLegacy() async {
    while (true) {
      _cleanupExpiredTimestamps();

      if (_recentRequests.length < RateLimitConfig.effectiveRpm) {
        _recentRequests.add(DateTime.now());
        return;
      }

      // Wait until oldest request expires
      final oldest = _recentRequests.first;
      final wait =
          RateLimitConfig.rpmWindow - DateTime.now().difference(oldest);
      if (wait.isNegative) continue;

      await Future.delayed(wait);
    }
  }
}
