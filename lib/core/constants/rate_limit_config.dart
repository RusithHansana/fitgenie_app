/// Configuration constants for Gemini API rate limiting.
///
/// These limits prevent the app from exceeding Gemini API quotas.
/// The app will stop one request before each limit to avoid hitting the API limit.
///
/// Usage:
/// ```dart
/// if (requestCount >= RateLimitConfig.effectiveRpm) {
///   throw AiException(AiErrorType.localRateLimitExceeded, 'RPM limit reached');
/// }
/// ```
class RateLimitConfig {
  RateLimitConfig._(); // Private constructor to prevent instantiation

  // ==========================================================================
  // REQUEST LIMITS
  // ==========================================================================

  /// Maximum requests per minute allowed by the API.
  static const int requestsPerMinute = 5;

  /// Effective RPM limit (stop one before the actual limit).
  static const int effectiveRpm = requestsPerMinute - 1;

  /// Maximum requests per day allowed by the API.
  static const int requestsPerDay = 20;

  /// Effective RPD limit (stop one before the actual limit).
  static const int effectiveRpd = requestsPerDay - 1;

  // ==========================================================================
  // TOKEN LIMITS
  // ==========================================================================

  /// Maximum input tokens per day allowed by the API.
  static const int maxInputTokensPerDay = 250000;

  /// Effective token limit (stop one token before the actual limit).
  static const int effectiveMaxTokens = maxInputTokensPerDay - 1;

  /// Approximate characters per token for estimation.
  ///
  /// Gemini uses roughly 4 characters per token on average.
  /// This is a conservative estimate for English text.
  static const int charsPerToken = 4;

  // ==========================================================================
  // TIME WINDOWS
  // ==========================================================================

  /// Time window for RPM tracking.
  static const Duration rpmWindow = Duration(minutes: 1);

  // ==========================================================================
  // HIVE STORAGE KEYS
  // ==========================================================================

  /// Hive box name for rate limit data.
  static const String hiveBoxName = 'rate_limits';

  /// Key for storing the last reset date.
  static const String lastResetDateKey = 'lastResetDate';

  /// Key for storing daily request count.
  static const String dailyRequestCountKey = 'dailyRequestCount';

  /// Key for storing daily tokens used.
  static const String dailyTokensUsedKey = 'dailyTokensUsed';

  // ==========================================================================
  // HELPER METHODS
  // ==========================================================================

  /// Estimates the number of tokens in a text string.
  ///
  /// Uses a simple character-based estimation (4 chars = 1 token).
  /// This is conservative and may overestimate slightly.
  static int estimateTokens(String text) {
    if (text.isEmpty) return 0;
    return (text.length / charsPerToken).ceil();
  }
}
