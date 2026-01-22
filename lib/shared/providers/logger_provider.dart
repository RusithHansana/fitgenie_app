import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fitgenie_app/core/utils/app_logger.dart';

part 'logger_provider.g.dart';

/// Riverpod provider exposing Logger instance for dependency injection.
///
/// This provider creates a singleton Logger instance configured with
/// environment-aware settings via [AppLogger]. It enables clean dependency
/// injection throughout the app and makes logging testable by allowing
/// mock logger injection in tests.
///
/// Features:
/// - Singleton logger instance (keepAlive: true)
/// - Environment-aware configuration (debug in dev, warning in production)
/// - Type-safe dependency injection
/// - Testable through provider overrides
/// - Consistent logging configuration across entire app
///
/// Usage in repositories:
/// ```dart
/// @riverpod
/// class AuthRepository {
///   AuthRepository(this.ref);
///   final Ref ref;
///
///   Future<void> signIn(String email, String password) async {
///     final logger = ref.read(loggerProvider);
///     logger.i('Sign in attempt for: $email');
///
///     try {
///       await _auth.signInWithEmailAndPassword(email: email, password: password);
///       logger.i('Sign in successful');
///     } catch (e, stackTrace) {
///       logger.e('Sign in failed', error: e, stackTrace: stackTrace);
///       rethrow;
///     }
///   }
/// }
/// ```
///
/// Usage in providers:
/// ```dart
/// @riverpod
/// class CurrentPlan extends _$CurrentPlan {
///   late final Logger _logger;
///
///   @override
///   Future<WeeklyPlan?> build() async {
///     _logger = ref.read(loggerProvider);
///     _logger.d('Loading current plan');
///
///     try {
///       final plan = await _loadPlan();
///       _logger.i('Current plan loaded successfully');
///       return plan;
///     } catch (e, stackTrace) {
///       _logger.e('Failed to load plan', error: e, stackTrace: stackTrace);
///       rethrow;
///     }
///   }
/// }
/// ```
///
/// Usage in UI (sparingly):
/// ```dart
/// class DashboardScreen extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final logger = ref.read(loggerProvider);
///
///     return planAsync.when(
///       data: (plan) {
///         logger.d('Dashboard rendered with plan');
///         return _buildDashboard(plan);
///       },
///       error: (error, stack) {
///         logger.w('Dashboard error state', error: error);
///         return ErrorWidget(error);
///       },
///       loading: () => LoadingWidget(),
///     );
///   }
/// }
/// ```
///
/// Testing with mock logger:
/// ```dart
/// testWidgets('Test with mock logger', (tester) async {
///   final mockLogger = MockLogger();
///
///   await tester.pumpWidget(
///     ProviderScope(
///       overrides: [
///         loggerProvider.overrideWithValue(mockLogger),
///       ],
///       child: MyWidget(),
///     ),
///   );
///
///   // Verify logger calls
///   verify(() => mockLogger.i('Expected log message')).called(1);
/// });
/// ```
///
/// Log Level Guidelines:
/// - **debug (logger.d)**: Detailed diagnostic info, development only
///   Example: `logger.d('User profile: ${profile.toJson()}')`
///
/// - **info (logger.i)**: Important business events, major operations
///   Example: `logger.i('Plan generation completed')`
///
/// - **warning (logger.w)**: Recoverable issues, retry attempts
///   Example: `logger.w('API retry attempt 2/3')`
///
/// - **error (logger.e)**: Critical failures with error and stack trace
///   Example: `logger.e('Sync failed', error: e, stackTrace: stackTrace)`
///
/// - **wtf (logger.wtf)**: Should-never-happen scenarios
///   Example: `logger.wtf('Auth token exists but user is null')`
///
/// Architecture Notes:
/// - Replaces all print() statements throughout the app
/// - Used by all layers: data, domain, presentation
/// - Configured via [AppLogger] utility class
/// - Automatically adjusts verbosity based on build mode
/// - Provider is kept alive for consistent singleton behavior
///
/// Security Considerations:
/// - Never log sensitive data (passwords, tokens, PII)
/// - Use debug level for potentially sensitive information
/// - Production builds automatically filter verbose logs
/// - Be mindful of user privacy when logging user actions
@Riverpod(keepAlive: true)
Logger logger(LoggerRef ref) {
  return AppLogger.createLogger();
}
