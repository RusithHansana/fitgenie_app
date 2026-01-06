import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration for multi-environment support.
///
/// This class manages loading of environment-specific configuration files
/// (.env.development, .env.staging, .env.production) using flutter_dotenv.
///
/// Must be initialized in main() before any configuration values are accessed:
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   // Load environment configuration
///   await EnvironmentConfig.load(Environment.development);
///
///   // Now safe to access AppConfig values
///   await Firebase.initializeApp();
///   runApp(MyApp());
/// }
/// ```
///
/// Environment Files:
/// - .env.development - Local development with debug logging
/// - .env.staging - Staging environment for testing
/// - .env.production - Production environment with real API keys
/// - .env.example - Template for required variables (committed to repo)
///
/// Security:
/// - Actual .env files should be in .gitignore
/// - Never commit API keys or secrets to version control
/// - Use .env.example to document required variables
class EnvironmentConfig {
  EnvironmentConfig._(); // Private constructor to prevent instantiation

  /// Currently active environment.
  ///
  /// Set during initialization and remains constant for the app session.
  static Environment? _currentEnvironment;

  /// Gets the current environment.
  ///
  /// Throws [StateError] if environment has not been loaded yet.
  static Environment get current {
    if (_currentEnvironment == null) {
      throw StateError(
        'Environment not initialized. Call EnvironmentConfig.load() first.',
      );
    }
    return _currentEnvironment!;
  }

  /// Checks if an environment has been loaded.
  ///
  /// Returns true if load() has been called successfully.
  static bool get isInitialized => _currentEnvironment != null;

  /// Loads environment configuration from the appropriate .env file.
  ///
  /// This method must be called during app initialization before accessing
  /// any configuration values.
  ///
  /// Example:
  /// ```dart
  /// // Development
  /// await EnvironmentConfig.load(Environment.development);
  ///
  /// // Production
  /// await EnvironmentConfig.load(Environment.production);
  /// ```
  ///
  /// Throws [Exception] if the .env file cannot be loaded.
  static Future<void> load(Environment environment) async {
    try {
      // Construct filename based on environment
      final filename = _getEnvFileName(environment);

      // Load the environment file
      await dotenv.load(fileName: filename);

      // Store the current environment
      _currentEnvironment = environment;
    } catch (e) {
      throw Exception(
        'Failed to load environment configuration for ${environment.name}: $e',
      );
    }
  }

  /// Loads environment based on build mode.
  ///
  /// Automatically selects:
  /// - Development for debug builds
  /// - Production for release builds
  /// - Staging for profile builds
  ///
  /// Example:
  /// ```dart
  /// await EnvironmentConfig.loadFromBuildMode();
  /// ```
  static Future<void> loadFromBuildMode() async {
    const bool isDebug = bool.fromEnvironment('dart.vm.product') == false;
    const bool isProfile = bool.fromEnvironment('dart.vm.profile');

    Environment environment;
    if (isDebug) {
      environment = Environment.development;
    } else if (isProfile) {
      environment = Environment.staging;
    } else {
      environment = Environment.production;
    }

    await load(environment);
  }

  /// Reloads the environment configuration.
  ///
  /// Useful for testing or hot reload scenarios where environment
  /// needs to be changed without restarting the app.
  ///
  /// Example:
  /// ```dart
  /// await EnvironmentConfig.reload(Environment.staging);
  /// ```
  static Future<void> reload(Environment environment) async {
    _currentEnvironment = null;
    await load(environment);
  }

  // ==========================================================================
  // PRIVATE HELPERS
  // ==========================================================================

  /// Gets the .env filename for the given environment.
  ///
  /// Maps Environment enum to actual file names:
  /// - development → .env.development
  /// - staging → .env.staging
  /// - production → .env.production
  static String _getEnvFileName(Environment environment) {
    switch (environment) {
      case Environment.development:
        return '.env.development';
      case Environment.staging:
        return '.env.staging';
      case Environment.production:
        return '.env.production';
    }
  }
}

/// Environment enumeration for multi-environment configuration.
///
/// Defines the available environments for the application.
/// Each environment can have different configuration values
/// (API keys, endpoints, feature flags, etc.).
enum Environment {
  /// Development environment.
  ///
  /// Used for local development with:
  /// - Debug logging enabled
  /// - Relaxed security for testing
  /// - Local or development API endpoints
  /// - Test API keys
  development,

  /// Staging environment.
  ///
  /// Used for pre-production testing with:
  /// - Production-like configuration
  /// - Test data
  /// - Staging API endpoints
  /// - QA and testing activities
  staging,

  /// Production environment.
  ///
  /// Used for live application with:
  /// - Real user data
  /// - Production API keys
  /// - Error reporting enabled
  /// - Performance monitoring
  /// - No debug logging
  production;

  /// Returns whether this is the development environment.
  bool get isDevelopment => this == Environment.development;

  /// Returns whether this is the staging environment.
  bool get isStaging => this == Environment.staging;

  /// Returns whether this is the production environment.
  bool get isProduction => this == Environment.production;

  /// Returns a human-readable display name for the environment.
  ///
  /// Example:
  /// ```dart
  /// Environment.development.displayName; // "Development"
  /// Environment.production.displayName;  // "Production"
  /// ```
  String get displayName {
    switch (this) {
      case Environment.development:
        return 'Development';
      case Environment.staging:
        return 'Staging';
      case Environment.production:
        return 'Production';
    }
  }

  /// Returns an emoji indicator for the environment.
  ///
  /// Useful for debug displays or logging.
  ///
  /// Example:
  /// ```dart
  /// Environment.development.emoji; // "🔧"
  /// Environment.staging.emoji;     // "🧪"
  /// Environment.production.emoji;  // "🚀"
  /// ```
  String get emoji {
    switch (this) {
      case Environment.development:
        return '🔧'; // Development/tools
      case Environment.staging:
        return '🧪'; // Testing/experiments
      case Environment.production:
        return '🚀'; // Live/deployed
    }
  }
}
