import 'dart:async';
import 'dart:io';

import 'package:fitgenie_app/core/exceptions/app_exception.dart';

/// Typed exceptions for network connectivity and HTTP errors.
///
/// This class handles network-related errors that occur during API calls,
/// database operations, and other network-dependent features. It provides
/// offline detection and user-friendly error messaging.
///
/// Usage in Repository:
/// ```dart
/// try {
///   final response = await http.get(url);
/// } on SocketException {
///   throw NetworkException(NetworkErrorType.noConnection, 'No internet');
/// } on TimeoutException {
///   throw NetworkException(NetworkErrorType.timeout, 'Request timeout');
/// }
/// ```
///
/// Usage for Offline Detection:
/// ```dart
/// if (error is NetworkException && error.isOffline) {
///   // Trigger offline mode
///   await syncQueue.queueOperation(operation);
/// }
/// ```
class NetworkException extends AppException {
  /// The specific type of network error.
  final NetworkErrorType type;

  /// Creates a NetworkException with the specified error type and message.
  ///
  /// The [type] determines offline detection and user-friendly messaging.
  /// The [message] contains technical details for debugging.
  const NetworkException(this.type, super.message);

  /// Creates a NetworkException from a SocketException.
  ///
  /// SocketExceptions typically indicate no internet connection.
  factory NetworkException.fromSocketException(SocketException error) {
    return NetworkException(NetworkErrorType.noConnection, error.message);
  }

  /// Creates a NetworkException from a TimeoutException.
  ///
  /// TimeoutExceptions occur when requests take too long.
  factory NetworkException.fromTimeoutException(TimeoutException error) {
    return NetworkException(
      NetworkErrorType.timeout,
      error.message ?? 'Request timed out',
    );
  }

  /// Creates a NetworkException from an HTTP status code.
  ///
  /// Maps common HTTP error codes to appropriate error types.
  factory NetworkException.fromStatusCode(int statusCode, String? message) {
    final type = _mapStatusCode(statusCode);
    return NetworkException(type, message ?? 'HTTP $statusCode error');
  }

  /// Maps HTTP status codes to NetworkErrorType values.
  static NetworkErrorType _mapStatusCode(int statusCode) {
    if (statusCode >= 500) {
      return NetworkErrorType.serverError;
    } else if (statusCode == 408 || statusCode == 504) {
      return NetworkErrorType.timeout;
    } else if (statusCode == 401 || statusCode == 403) {
      return NetworkErrorType.unauthorized;
    } else if (statusCode == 404) {
      return NetworkErrorType.notFound;
    } else if (statusCode >= 400) {
      return NetworkErrorType.clientError;
    }
    return NetworkErrorType.unknown;
  }

  /// Whether this error indicates the device is offline.
  ///
  /// When true, the app should:
  /// - Show offline indicator banner
  /// - Queue operations for later sync
  /// - Use cached data
  /// - Disable features requiring connectivity
  bool get isOffline {
    return type == NetworkErrorType.noConnection;
  }

  /// Whether this error should trigger an automatic retry.
  ///
  /// Temporary network errors and server errors are retryable.
  /// Client errors (bad requests) should not be retried.
  bool get isRetryable {
    switch (type) {
      case NetworkErrorType.noConnection:
      case NetworkErrorType.timeout:
      case NetworkErrorType.serverError:
        return true;
      case NetworkErrorType.unauthorized:
      case NetworkErrorType.notFound:
      case NetworkErrorType.clientError:
      case NetworkErrorType.unknown:
        return false;
    }
  }

  @override
  String get userFriendlyMessage {
    switch (type) {
      case NetworkErrorType.noConnection:
        return 'No internet connection. Please check your network.';

      case NetworkErrorType.timeout:
        return 'Request timed out. Please try again.';

      case NetworkErrorType.serverError:
        return 'Server error. Please try again later.';

      case NetworkErrorType.unauthorized:
        return 'Authentication required. Please sign in again.';

      case NetworkErrorType.notFound:
        return 'Requested resource not found.';

      case NetworkErrorType.clientError:
        return 'Invalid request. Please try again.';

      case NetworkErrorType.unknown:
        return 'Network error occurred. Please try again.';
    }
  }
}

/// Enumeration of network error types.
///
/// These types cover common network failure scenarios including
/// connectivity issues, timeouts, and HTTP errors.
enum NetworkErrorType {
  /// No internet connection available
  ///
  /// Device is offline or network is unreachable.
  /// Should trigger offline mode.
  noConnection,

  /// Request timed out
  ///
  /// Request took too long to complete.
  /// May indicate slow connection or server issues.
  timeout,

  /// Server error (5xx HTTP status)
  ///
  /// Problem on the server side.
  /// Usually temporary and retryable.
  serverError,

  /// Unauthorized (401/403 HTTP status)
  ///
  /// Authentication or permission error.
  /// User may need to sign in again.
  unauthorized,

  /// Not found (404 HTTP status)
  ///
  /// Requested resource doesn't exist.
  /// Not retryable.
  notFound,

  /// Client error (4xx HTTP status, excluding 401/403/404)
  ///
  /// Problem with the request itself.
  /// Not retryable without changing the request.
  clientError,

  /// Unknown network error
  unknown,
}

/// Extension methods for NetworkErrorType.
extension NetworkErrorTypeExtension on NetworkErrorType {
  /// Whether this error indicates a temporary condition.
  ///
  /// Temporary errors might resolve with time or retry.
  bool get isTemporary {
    switch (this) {
      case NetworkErrorType.noConnection:
      case NetworkErrorType.timeout:
      case NetworkErrorType.serverError:
        return true;
      case NetworkErrorType.unauthorized:
      case NetworkErrorType.notFound:
      case NetworkErrorType.clientError:
      case NetworkErrorType.unknown:
        return false;
    }
  }

  /// Whether this error should trigger offline mode.
  ///
  /// Only no-connection errors should activate offline mode.
  bool get shouldTriggerOfflineMode {
    return this == NetworkErrorType.noConnection;
  }

  /// Whether this error indicates a problem with user's session.
  ///
  /// Session-related errors should redirect to login.
  bool get isSessionError {
    return this == NetworkErrorType.unauthorized;
  }

  /// HTTP status code range for this error type.
  ///
  /// Returns a string description of the status code range.
  String get statusCodeRange {
    switch (this) {
      case NetworkErrorType.noConnection:
        return 'N/A (Network unreachable)';
      case NetworkErrorType.timeout:
        return '408, 504 (Request Timeout)';
      case NetworkErrorType.serverError:
        return '500-599 (Server Error)';
      case NetworkErrorType.unauthorized:
        return '401, 403 (Unauthorized)';
      case NetworkErrorType.notFound:
        return '404 (Not Found)';
      case NetworkErrorType.clientError:
        return '400-499 (Client Error)';
      case NetworkErrorType.unknown:
        return 'Unknown';
    }
  }

  /// Technical description for logging purposes.
  String get technicalDescription {
    switch (this) {
      case NetworkErrorType.noConnection:
        return 'No network connectivity detected';
      case NetworkErrorType.timeout:
        return 'Network request exceeded timeout threshold';
      case NetworkErrorType.serverError:
        return 'Server returned 5xx error';
      case NetworkErrorType.unauthorized:
        return 'Authentication or authorization failed';
      case NetworkErrorType.notFound:
        return 'Requested resource does not exist';
      case NetworkErrorType.clientError:
        return 'Client request error (4xx)';
      case NetworkErrorType.unknown:
        return 'Unhandled network error';
    }
  }

  /// Recommended action for this error type.
  ///
  /// Guidance for what the app should do when this error occurs.
  String get recommendedAction {
    switch (this) {
      case NetworkErrorType.noConnection:
        return 'Enable offline mode, show offline banner, queue operations';
      case NetworkErrorType.timeout:
        return 'Retry with exponential backoff';
      case NetworkErrorType.serverError:
        return 'Retry with exponential backoff';
      case NetworkErrorType.unauthorized:
        return 'Clear session, redirect to login';
      case NetworkErrorType.notFound:
        return 'Show error, do not retry';
      case NetworkErrorType.clientError:
        return 'Show error, do not retry';
      case NetworkErrorType.unknown:
        return 'Log error, show generic message';
    }
  }
}
