import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitgenie_app/core/exceptions/app_exception.dart';

/// Typed exceptions for Firebase Authentication errors.
///
/// This class maps Firebase Auth error codes to user-friendly error types
/// and messages. It provides a consistent interface for handling authentication
/// failures throughout the app.
///
/// Usage in Repository:
/// ```dart
/// try {
///   await FirebaseAuth.instance.signInWithEmailAndPassword(...);
/// } on FirebaseAuthException catch (e) {
///   throw AuthException.fromFirebaseError(e);
/// }
/// ```
///
/// Usage in UI:
/// ```dart
/// ref.watch(loginProvider).when(
///   error: (error, _) {
///     if (error is AuthException) {
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(content: Text(error.userFriendlyMessage)),
///       );
///     }
///   },
/// );
/// ```
class AuthException extends AppException {
  /// The specific type of authentication error.
  final AuthErrorType type;

  /// Creates an AuthException with the specified error type and message.
  ///
  /// The [type] determines the user-friendly message displayed to the user.
  /// The [message] contains technical details for debugging.
  const AuthException(this.type, super.message);

  /// Creates an AuthException from a FirebaseAuthException.
  ///
  /// Maps Firebase error codes to appropriate AuthErrorType values.
  /// This is the primary way to create AuthException instances in repository code.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await FirebaseAuth.instance.signInWithEmailAndPassword(...);
  /// } on FirebaseAuthException catch (e) {
  ///   throw AuthException.fromFirebaseError(e);
  /// }
  /// ```
  factory AuthException.fromFirebaseError(FirebaseAuthException error) {
    final type = _mapFirebaseErrorCode(error.code);
    return AuthException(type, error.message ?? error.code);
  }

  /// Maps Firebase Auth error codes to AuthErrorType enum values.
  static AuthErrorType _mapFirebaseErrorCode(String code) {
    switch (code) {
      // Invalid email format
      case 'invalid-email':
        return AuthErrorType.invalidEmail;

      // Wrong password
      case 'wrong-password':
      case 'invalid-credential':
        return AuthErrorType.wrongPassword;

      // User not found
      case 'user-not-found':
        return AuthErrorType.userNotFound;

      // Email already in use
      case 'email-already-in-use':
        return AuthErrorType.emailInUse;

      // Weak password
      case 'weak-password':
        return AuthErrorType.weakPassword;

      // User disabled
      case 'user-disabled':
        return AuthErrorType.userDisabled;

      // Too many requests
      case 'too-many-requests':
        return AuthErrorType.tooManyRequests;

      // Operation not allowed
      case 'operation-not-allowed':
        return AuthErrorType.operationNotAllowed;

      // Network errors
      case 'network-request-failed':
        return AuthErrorType.networkError;

      // Token errors
      case 'invalid-verification-code':
      case 'invalid-verification-id':
        return AuthErrorType.invalidVerificationCode;

      // Session expired
      case 'session-expired':
      case 'requires-recent-login':
        return AuthErrorType.sessionExpired;

      // Default to unknown
      default:
        return AuthErrorType.unknown;
    }
  }

  @override
  String get userFriendlyMessage {
    switch (type) {
      case AuthErrorType.invalidEmail:
        return 'Please enter a valid email address';

      case AuthErrorType.wrongPassword:
        return 'Incorrect email or password. Please try again.';

      case AuthErrorType.userNotFound:
        return 'No account found with this email';

      case AuthErrorType.emailInUse:
        return 'This email is already registered';

      case AuthErrorType.weakPassword:
        return 'Password must be at least 6 characters';

      case AuthErrorType.userDisabled:
        return 'This account has been disabled. Please contact support.';

      case AuthErrorType.tooManyRequests:
        return 'Too many attempts. Please try again later.';

      case AuthErrorType.operationNotAllowed:
        return 'This sign-in method is not enabled. Please contact support.';

      case AuthErrorType.networkError:
        return 'Connection failed. Please check your internet.';

      case AuthErrorType.invalidVerificationCode:
        return 'Invalid verification code. Please try again.';

      case AuthErrorType.sessionExpired:
        return 'Your session has expired. Please sign in again.';

      case AuthErrorType.unknown:
        return 'Authentication failed. Please try again.';
    }
  }
}

/// Enumeration of authentication error types.
///
/// These types map to common Firebase Auth errors and provide a typed
/// interface for error handling in the app.
enum AuthErrorType {
  /// Invalid email format
  invalidEmail,

  /// Incorrect password
  wrongPassword,

  /// User account not found
  userNotFound,

  /// Email already registered
  emailInUse,

  /// Password doesn't meet requirements
  weakPassword,

  /// User account has been disabled
  userDisabled,

  /// Too many failed authentication attempts
  tooManyRequests,

  /// Authentication method not enabled
  operationNotAllowed,

  /// Network connection failed
  networkError,

  /// Invalid verification code (for phone auth, etc.)
  invalidVerificationCode,

  /// Session expired or requires recent login
  sessionExpired,

  /// Unknown or unhandled error
  unknown,
}

/// Extension methods for AuthErrorType.
extension AuthErrorTypeExtension on AuthErrorType {
  /// Whether this error type should trigger an automatic retry.
  ///
  /// Network errors are retryable, but user input errors (wrong password,
  /// invalid email) should not be automatically retried.
  bool get isRetryable {
    switch (this) {
      case AuthErrorType.networkError:
      case AuthErrorType.tooManyRequests:
        return true;
      default:
        return false;
    }
  }

  /// Whether this error is related to user input validation.
  ///
  /// These errors should highlight the relevant input field in the UI.
  bool get isValidationError {
    switch (this) {
      case AuthErrorType.invalidEmail:
      case AuthErrorType.weakPassword:
      case AuthErrorType.wrongPassword:
        return true;
      default:
        return false;
    }
  }

  /// Whether this error requires user action (can't be resolved automatically).
  ///
  /// These errors need the user to correct their input or take specific action.
  bool get requiresUserAction {
    switch (this) {
      case AuthErrorType.networkError:
      case AuthErrorType.unknown:
        return false; // System errors that might resolve themselves
      default:
        return true; // User needs to take action
    }
  }
}
