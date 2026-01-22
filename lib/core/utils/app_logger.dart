import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Logger configuration and utilities for consistent logging throughout the app.
///
/// This class provides static methods to create and configure Logger instances
/// with environment-aware settings. It ensures consistent log formatting in
/// development (verbose with emojis and colors) and production (minimal output).
///
/// Features:
/// - Environment-aware log levels (debug in dev, warning in production)
/// - Pretty formatting in development for better debugging
/// - Simple formatting in production to reduce overhead
/// - Configurable output length and stack trace depth
/// - Consistent emoji and color usage
///
/// Usage:
/// ```dart
/// // Create logger instance
/// final logger = AppLogger.createLogger();
///
/// // Use logger with different levels
/// logger.d('Debug information'); // Development only
/// logger.i('User logged in successfully'); // Important events
/// logger.w('API retry attempt 2/3'); // Warnings
/// logger.e('Failed to sync data', error: e, stackTrace: st); // Errors
/// logger.wtf('Should never happen', error: e); // Fatal errors
/// ```
///
/// Log Levels Guide:
/// - **debug (d)**: Detailed diagnostic info, development only
/// - **info (i)**: Important business events, major operations
/// - **warning (w)**: Recoverable issues, retry attempts
/// - **error (e)**: Critical failures, exceptions
/// - **wtf**: Should-never-happen scenarios, invariant violations
///
/// Architecture Integration:
/// - Used by all layers (data, domain, presentation)
/// - Injected via Riverpod [loggerProvider] for testability
/// - Replaces all print() statements throughout the app
/// - Integrates with error handling and exception classes
///
/// Implementation Notes:
/// - Uses kReleaseMode to detect production environment
/// - Logs are automatically filtered in production builds
/// - Stack traces are captured for errors and fatal logs
/// - Color output only works on supported terminals
class AppLogger {
  AppLogger._(); // Private constructor to prevent instantiation

  // ==========================================================================
  // LOGGER CREATION
  // ==========================================================================

  /// Creates a configured Logger instance with environment-aware settings.
  ///
  /// In development (debug builds):
  /// - Pretty formatting with emojis and colors
  /// - All log levels enabled (debug and above)
  /// - 2-line method count for normal logs
  /// - 8-line method count for error logs
  /// - 120-character line length
  /// - Timestamp included
  ///
  /// In production (release builds):
  /// - Simple formatting without colors or emojis
  /// - Only warning and above levels enabled
  /// - Minimal overhead
  ///
  /// Example:
  /// ```dart
  /// final logger = AppLogger.createLogger();
  /// logger.i('Application started');
  /// ```
  static Logger createLogger() {
    return Logger(
      printer: _createPrinter(),
      level: _getLogLevel(),
      filter: _createFilter(),
    );
  }

  // ==========================================================================
  // PRINTER CONFIGURATION
  // ==========================================================================

  /// Creates appropriate log printer based on build mode.
  ///
  /// Development uses [PrettyPrinter] for enhanced readability.
  /// Production uses [SimplePrinter] for minimal overhead.
  static LogPrinter _createPrinter() {
    if (kReleaseMode) {
      // Production: Simple output without colors/emojis
      return SimplePrinter(colors: false, printTime: true);
    } else {
      // Development: Pretty formatting
      return PrettyPrinter(
        methodCount: 2, // Number of method calls to display
        errorMethodCount: 8, // Number of method calls for errors
        lineLength: 120, // Width of output
        colors: true, // Colorful output
        printEmojis: true, // Use emojis for log level
        printTime: true, // Include timestamp
        excludeBox: {Level.debug: false, Level.trace: false},
      );
    }
  }

  // ==========================================================================
  // LOG LEVEL CONFIGURATION
  // ==========================================================================

  /// Returns appropriate log level based on build mode.
  ///
  /// - Development: [Level.debug] - All logs visible
  /// - Production: [Level.warning] - Only warnings and errors visible
  static Level _getLogLevel() {
    return kReleaseMode ? Level.warning : Level.debug;
  }

  // ==========================================================================
  // FILTER CONFIGURATION
  // ==========================================================================

  /// Creates appropriate log filter based on build mode.
  ///
  /// - Development: [DevelopmentFilter] - Allows all logs
  /// - Production: [ProductionFilter] - Filters based on log level
  static LogFilter _createFilter() {
    return kReleaseMode ? ProductionFilter() : DevelopmentFilter();
  }

  // ==========================================================================
  // UTILITY METHODS
  // ==========================================================================

  /// Checks if debug logging is enabled.
  ///
  /// Useful for conditionally expensive operations:
  /// ```dart
  /// if (AppLogger.isDebugEnabled) {
  ///   final expensiveData = computeDebugInfo();
  ///   logger.d('Debug info: $expensiveData');
  /// }
  /// ```
  static bool get isDebugEnabled => !kReleaseMode;

  /// Checks if production logging mode is active.
  ///
  /// Useful for conditional behavior:
  /// ```dart
  /// if (AppLogger.isProduction) {
  ///   // Only log critical errors
  /// }
  /// ```
  static bool get isProduction => kReleaseMode;

  // ==========================================================================
  // HELPER METHODS FOR COMMON LOG PATTERNS
  // ==========================================================================

  /// Helper to format error logs consistently.
  ///
  /// Example:
  /// ```dart
  /// logger.e(
  ///   AppLogger.formatError('Failed to load data', error, stackTrace),
  /// );
  /// ```
  static String formatError(
    String message,
    Object? error, [
    StackTrace? stackTrace,
  ]) {
    final buffer = StringBuffer(message);
    if (error != null) {
      buffer.write('\nError: $error');
    }
    if (stackTrace != null && !kReleaseMode) {
      buffer.write('\nStack trace:\n$stackTrace');
    }
    return buffer.toString();
  }

  /// Helper to format operation logs with context.
  ///
  /// Example:
  /// ```dart
  /// logger.i(AppLogger.formatOperation('Login', userId));
  /// // Output: "Login - User: abc123"
  /// ```
  static String formatOperation(String operation, String? context) {
    return context != null ? '$operation - $context' : operation;
  }

  /// Helper to format timing logs.
  ///
  /// Example:
  /// ```dart
  /// final stopwatch = Stopwatch()..start();
  /// // ... perform operation ...
  /// logger.d(AppLogger.formatTiming('API call', stopwatch.elapsedMilliseconds));
  /// // Output: "API call completed in 234ms"
  /// ```
  static String formatTiming(String operation, int milliseconds) {
    return '$operation completed in ${milliseconds}ms';
  }
}
