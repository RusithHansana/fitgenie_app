import 'package:fitgenie_app/core/config/environment.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized access to application configuration values.
///
/// This class provides static getters for all configuration values loaded
/// from environment variables via flutter_dotenv. It acts as a type-safe
/// wrapper around dotenv.env with validation and default values.
///
/// Prerequisites:
/// - EnvironmentConfig.load() must be called first in main()
/// - Appropriate .env file must exist and be loaded
///
/// Usage:
/// ```dart
/// // In main.dart
/// await EnvironmentConfig.load(Environment.development);
///
/// // Access configuration anywhere in the app
/// final apiKey = AppConfig.geminiApiKey;
/// if (AppConfig.isProduction) {
///   // Production-specific logic
/// }
/// ```
///
/// Security:
/// - Never log sensitive configuration values
/// - API keys and secrets should only be accessed, never displayed
/// - Use assertions to catch missing required configuration early
class AppConfig {
  AppConfig._(); // Private constructor to prevent instantiation

  // ==========================================================================
  // APP METADATA
  // ==========================================================================

  /// Application name.
  ///
  /// Used for display in UI, logs, and analytics.
  static const String appName = 'FitGenie';

  /// Application tagline.
  ///
  /// Used in onboarding and marketing materials.
  static const String appTagline = 'Your AI Personal Trainer & Nutritionist';

  /// Application version.
  ///
  /// Should match pubspec.yaml version.
  static const String appVersion = '1.0.0';

  /// Application build number.
  ///
  /// Increments with each release.
  static const int appBuildNumber = 1;

  // ==========================================================================
  // ENVIRONMENT
  // ==========================================================================

  /// Gets the current environment.
  ///
  /// Example:
  /// ```dart
  /// if (AppConfig.environment == Environment.production) {
  ///   // Production-specific code
  /// }
  /// ```
  static Environment get environment => EnvironmentConfig.current;

  /// Returns whether the app is running in production environment.
  ///
  /// Example:
  /// ```dart
  /// if (AppConfig.isProduction) {
  ///   // Disable debug features
  /// }
  /// ```
  static bool get isProduction => environment.isProduction;

  /// Returns whether the app is running in staging environment.
  static bool get isStaging => environment.isStaging;

  /// Returns whether the app is running in development environment.
  static bool get isDevelopment => environment.isDevelopment;

  /// Returns whether the app is running in debug mode.
  ///
  /// Note: This checks the Dart VM debug mode, not the environment.
  /// An app can be in production environment but debug mode during testing.
  static bool get isDebugMode => kDebugMode;

  /// Returns whether the app is running in release mode.
  static bool get isReleaseMode => kReleaseMode;

  /// Returns whether the app is running in profile mode.
  static bool get isProfileMode => kProfileMode;

  // ==========================================================================
  // API KEYS & SECRETS
  // ==========================================================================

  /// Gemini API key for AI plan generation.
  ///
  /// Required in all environments.
  /// Throws [AssertionError] if not configured.
  ///
  /// Example:
  /// ```dart
  /// final model = GenerativeModel(
  ///   model: 'gemini-pro',
  ///   apiKey: AppConfig.geminiApiKey,
  /// );
  /// ```
  static String get geminiApiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    assert(
      key != null && key.isNotEmpty,
      'GEMINI_API_KEY is required but not configured. '
      'Add it to your .env file.',
    );
    return key!;
  }

  /// Checks if Gemini API key is configured.
  ///
  /// Returns true if the key exists and is not empty.
  /// Useful for conditional feature availability.
  static bool get hasGeminiApiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    return key != null && key.isNotEmpty;
  }

  // ==========================================================================
  // FEATURE FLAGS
  // ==========================================================================

  /// Whether AI plan generation feature is enabled.
  ///
  /// Can be toggled via environment variable for A/B testing or gradual rollout.
  ///
  /// Example in .env:
  /// ```
  /// FEATURE_AI_GENERATION=true
  /// ```
  static bool get featureAiGenerationEnabled {
    return _getBoolEnv('FEATURE_AI_GENERATION', defaultValue: true);
  }

  /// Whether chat modification feature is enabled.
  static bool get featureChatEnabled {
    return _getBoolEnv('FEATURE_CHAT', defaultValue: true);
  }

  /// Whether offline mode is enabled.
  static bool get featureOfflineEnabled {
    return _getBoolEnv('FEATURE_OFFLINE', defaultValue: true);
  }

  /// Whether streak tracking is enabled.
  static bool get featureStreaksEnabled {
    return _getBoolEnv('FEATURE_STREAKS', defaultValue: true);
  }

  /// Whether admin dashboard is accessible.
  ///
  /// Should be false in production unless user has admin privileges.
  static bool get featureAdminDashboardEnabled {
    return _getBoolEnv('FEATURE_ADMIN_DASHBOARD', defaultValue: false);
  }

  // ==========================================================================
  // API CONFIGURATION
  // ==========================================================================

  /// Base timeout for API requests in seconds.
  ///
  /// Example in .env:
  /// ```
  /// API_TIMEOUT_SECONDS=30
  /// ```
  static int get apiTimeoutSeconds {
    return _getIntEnv('API_TIMEOUT_SECONDS', defaultValue: 30);
  }

  /// Timeout specifically for AI generation requests in seconds.
  ///
  /// AI requests may take longer than regular API calls.
  static int get aiGenerationTimeoutSeconds {
    return _getIntEnv('AI_GENERATION_TIMEOUT_SECONDS', defaultValue: 60);
  }

  /// Maximum number of retry attempts for failed requests.
  ///
  /// Used by RetryHelper.
  static int get maxRetryAttempts {
    return _getIntEnv('MAX_RETRY_ATTEMPTS', defaultValue: 3);
  }

  // ==========================================================================
  // LOGGING & DEBUGGING
  // ==========================================================================

  /// Whether verbose logging is enabled.
  ///
  /// When true, logs detailed debug information.
  /// Should be false in production.
  static bool get verboseLogging {
    return _getBoolEnv('VERBOSE_LOGGING', defaultValue: isDevelopment);
  }

  /// Whether to log API requests and responses.
  ///
  /// Useful for debugging but should be disabled in production for privacy.
  static bool get logApiCalls {
    return _getBoolEnv('LOG_API_CALLS', defaultValue: isDevelopment);
  }

  /// Whether to show debug overlays in the UI.
  ///
  /// Displays environment indicator, performance metrics, etc.
  static bool get showDebugOverlay {
    return _getBoolEnv('SHOW_DEBUG_OVERLAY', defaultValue: isDevelopment);
  }

  // ==========================================================================
  // CACHING & PERFORMANCE
  // ==========================================================================

  /// Maximum age of cached plans in days.
  ///
  /// Plans older than this will be regenerated.
  static int get maxCachedPlanAgeDays {
    return _getIntEnv('MAX_CACHED_PLAN_AGE_DAYS', defaultValue: 7);
  }

  /// Maximum number of plans to keep in local cache.
  ///
  /// Older plans are deleted when this limit is reached.
  static int get maxCachedPlansCount {
    return _getIntEnv('MAX_CACHED_PLANS_COUNT', defaultValue: 4);
  }

  // ==========================================================================
  // PRIVATE HELPERS
  // ==========================================================================

  /// Safely gets a boolean environment variable with a default value.
  ///
  /// Accepts: "true", "1", "yes" (case-insensitive) as true.
  /// Everything else is false.
  static bool _getBoolEnv(String key, {required bool defaultValue}) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) return defaultValue;

    final normalized = value.toLowerCase().trim();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  /// Safely gets an integer environment variable with a default value.
  ///
  /// Returns default if the value is not a valid integer.
  static int _getIntEnv(String key, {required int defaultValue}) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) return defaultValue;

    return int.tryParse(value) ?? defaultValue;
  }

  // ==========================================================================
  // DEBUG UTILITIES
  // ==========================================================================

  /// Returns a debug-friendly string representation of the current configuration.
  ///
  /// WARNING: Does NOT include sensitive values like API keys.
  /// Safe to display in debug UI or logs.
  ///
  /// Example:
  /// ```dart
  /// debugPrint(AppConfig.debugInfo);
  /// ```
  static String get debugInfo {
    return '''
╔═══════════════════════════════════════════════════════════════
║ FitGenie Configuration
╠═══════════════════════════════════════════════════════════════
║ Environment: ${environment.displayName} ${environment.emoji}
║ App Version: $appVersion (build $appBuildNumber)
║ Debug Mode: ${isDebugMode ? 'Yes' : 'No'}
║ 
║ Features:
║   AI Generation: ${featureAiGenerationEnabled ? '✓' : '✗'}
║   Chat: ${featureChatEnabled ? '✓' : '✗'}
║   Offline: ${featureOfflineEnabled ? '✓' : '✗'}
║   Streaks: ${featureStreaksEnabled ? '✓' : '✗'}
║   Admin Dashboard: ${featureAdminDashboardEnabled ? '✓' : '✗'}
║ 
║ API Settings:
║   Timeout: ${apiTimeoutSeconds}s
║   AI Timeout: ${aiGenerationTimeoutSeconds}s
║   Max Retries: $maxRetryAttempts
║   Gemini API Key: ${hasGeminiApiKey ? 'Configured ✓' : 'Missing ✗'}
║ 
║ Logging:
║   Verbose: ${verboseLogging ? 'On' : 'Off'}
║   API Calls: ${logApiCalls ? 'On' : 'Off'}
║   Debug Overlay: ${showDebugOverlay ? 'On' : 'Off'}
╚═══════════════════════════════════════════════════════════════
''';
  }

  /// Validates that all required configuration is present.
  ///
  /// Throws [AssertionError] if any required config is missing.
  /// Call this early in main() to fail fast if misconfigured.
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   await EnvironmentConfig.load(Environment.development);
  ///   AppConfig.validate();
  ///   runApp(MyApp());
  /// }
  /// ```
  static void validate() {
    // Check required API keys
    assert(hasGeminiApiKey, 'GEMINI_API_KEY is required but not configured');

    // Validate timeout values
    assert(apiTimeoutSeconds > 0, 'API_TIMEOUT_SECONDS must be positive');
    assert(
      aiGenerationTimeoutSeconds > 0,
      'AI_GENERATION_TIMEOUT_SECONDS must be positive',
    );

    // Validate retry settings
    assert(maxRetryAttempts >= 0, 'MAX_RETRY_ATTEMPTS must be non-negative');

    // Validate cache settings
    assert(
      maxCachedPlanAgeDays > 0,
      'MAX_CACHED_PLAN_AGE_DAYS must be positive',
    );
    assert(maxCachedPlansCount > 0, 'MAX_CACHED_PLANS_COUNT must be positive');

    if (isDebugMode) {
      debugPrint('✓ AppConfig validation passed');
    }
  }
}
