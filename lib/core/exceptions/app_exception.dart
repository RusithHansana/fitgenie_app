/// Base exception class for all FitGenie app exceptions.
///
/// This abstract class defines the contract that all typed exceptions in the
/// app must implement. It provides a consistent interface for error handling
/// throughout the application.
///
/// All feature-specific exceptions (auth, AI, network, sync) must extend this
/// class to ensure uniform error handling and user-friendly messaging.
///
/// Usage:
/// ```dart
/// class AuthException extends AppException {
///   final AuthErrorType type;
///
///   AuthException(this.type, String message) : super(message);
///
///   @override
///   String get userFriendlyMessage => // ... type-specific message
/// }
/// ```
///
/// Error Handling Pattern:
/// - Repository layer: Catch platform exceptions, transform to AppException
/// - Provider layer: Propagate exceptions unchanged (AsyncValue handles)
/// - UI layer: Display exception.userFriendlyMessage to user
abstract class AppException implements Exception {
  /// Technical error message for logging and debugging.
  ///
  /// This message may contain implementation details and should NOT be
  /// displayed directly to end users. Use [userFriendlyMessage] for UI display.
  ///
  /// Example: "SocketException: Failed host lookup: 'api.example.com'"
  final String message;

  /// Creates an AppException with a technical error message.
  ///
  /// The [message] should describe the technical cause of the error for
  /// debugging purposes.
  const AppException(this.message);

  /// User-friendly error message suitable for display in the UI.
  ///
  /// This message should be:
  /// - Clear and non-technical
  /// - Actionable (tell users what they can do)
  /// - Empathetic in tone
  /// - Free of implementation details
  ///
  /// Example: "No internet connection. Please check your network."
  ///
  /// All subclasses MUST override this getter to provide appropriate
  /// user-facing messages.
  String get userFriendlyMessage;

  /// String representation for logging and debugging.
  ///
  /// Includes both the exception type and the technical message.
  @override
  String toString() {
    return '$runtimeType: $message';
  }
}
