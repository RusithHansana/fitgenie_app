import 'package:fitgenie_app/core/exceptions/app_exception.dart';

/// Typed exceptions for Gemini AI integration errors.
///
/// This class handles errors that occur during AI plan generation and
/// modification operations. It provides user-friendly messaging and retry
/// guidance for different error scenarios.
///
/// Usage in Repository:
/// ```dart
/// try {
///   final response = await geminiModel.generateContent(...);
/// } catch (e) {
///   throw AiException(AiErrorType.invalidResponse, e.toString());
/// }
/// ```
///
/// Usage with RetryHelper:
/// ```dart
/// final result = await RetryHelper.withRetry(
///   operation: () => geminiService.generatePlan(profile),
///   shouldRetry: (e) => e is AiException && e.isRetryable,
/// );
/// ```
class AiException extends AppException {
  /// The specific type of AI error.
  final AiErrorType type;

  /// Creates an AiException with the specified error type and message.
  ///
  /// The [type] determines retry eligibility and user-friendly messaging.
  /// The [message] contains technical details for debugging.
  const AiException(this.type, super.message);

  /// Whether this error should trigger an automatic retry.
  ///
  /// Rate limit errors, network errors, and timeouts are retryable.
  /// Parse errors and invalid API keys are not retryable.
  bool get isRetryable {
    switch (type) {
      case AiErrorType.rateLimited:
      case AiErrorType.timeout:
      case AiErrorType.networkError:
        return true;
      case AiErrorType.invalidResponse:
      case AiErrorType.parseError:
      case AiErrorType.invalidApiKey:
      case AiErrorType.contentFiltered:
      case AiErrorType.invalidRequest:
      case AiErrorType.localRpmExceeded:
      case AiErrorType.localRpdExceeded:
      case AiErrorType.localTokensExceeded:
      case AiErrorType.unknown:
        return false;
    }
  }

  /// Recommended delay before retry (in seconds).
  ///
  /// Rate limit errors should wait longer than regular timeouts.
  int get recommendedRetryDelaySeconds {
    switch (type) {
      case AiErrorType.rateLimited:
        return 5; // Rate limits need longer wait
      case AiErrorType.localRpmExceeded:
        return 60; // Wait for minute window to reset
      case AiErrorType.timeout:
      case AiErrorType.networkError:
        return 2; // Network errors can retry sooner
      case AiErrorType.localRpdExceeded:
      case AiErrorType.localTokensExceeded:
        return -1; // Cannot retry today
      default:
        return 1; // Default delay
    }
  }

  @override
  String get userFriendlyMessage {
    switch (type) {
      case AiErrorType.rateLimited:
        return 'Our AI is taking a short break. Please wait a moment.';

      case AiErrorType.invalidResponse:
        return 'Unable to generate plan. Retrying...';

      case AiErrorType.parseError:
        return 'Couldn\'t understand AI response. Please try again.';

      case AiErrorType.timeout:
        return 'Request timed out. Trying again...';

      case AiErrorType.networkError:
        return 'Connection lost. Please check your internet.';

      case AiErrorType.invalidApiKey:
        return 'Configuration error. Please contact support.';

      case AiErrorType.contentFiltered:
        return 'Unable to generate this content. Please try different parameters.';

      case AiErrorType.invalidRequest:
        return 'This type of modification is not supported. Try changing specific days or meals instead.';

      case AiErrorType.localRpmExceeded:
        return 'Too many requests. Please wait a minute before trying again.';

      case AiErrorType.localRpdExceeded:
        return 'Daily request limit reached. Please try again tomorrow.';

      case AiErrorType.localTokensExceeded:
        return 'Daily usage limit reached. Please try again tomorrow.';

      case AiErrorType.unknown:
        return 'Something went wrong with AI generation. Please try again.';
    }
  }
}

/// Enumeration of AI integration error types.
///
/// These types cover common failure scenarios when interacting with
/// the Gemini API for plan generation and modifications.
enum AiErrorType {
  /// API rate limit exceeded
  ///
  /// The app has made too many requests in a short time period.
  /// Requires waiting before retrying.
  rateLimited,

  /// AI returned invalid or malformed response
  ///
  /// The response structure doesn't match expected JSON schema.
  invalidResponse,

  /// Failed to parse AI response JSON
  ///
  /// JSON was returned but couldn't be decoded or validated.
  parseError,

  /// Request timed out
  ///
  /// The AI took too long to respond (>30 seconds).
  timeout,

  /// Network connection error
  ///
  /// No internet connection or network failure during request.
  networkError,

  /// Invalid or missing API key
  ///
  /// Configuration error - API key not set or invalid.
  invalidApiKey,

  /// Content filtered by AI safety mechanisms
  ///
  /// The AI refused to generate content due to safety policies.
  contentFiltered,

  /// Invalid or unsupported user request
  ///
  /// The user's modification request was rejected (e.g., full plan changes).
  invalidRequest,

  /// Local RPM (requests per minute) limit exceeded
  ///
  /// The app has reached its local per-minute request limit.
  /// Wait for the minute window to reset.
  localRpmExceeded,

  /// Local RPD (requests per day) limit exceeded
  ///
  /// The app has reached its daily request limit.
  /// Try again tomorrow.
  localRpdExceeded,

  /// Local daily token limit exceeded
  ///
  /// The app has used its daily token budget.
  /// Try again tomorrow.
  localTokensExceeded,

  /// Unknown or unhandled AI error
  unknown,
}

/// Extension methods for AiErrorType.
extension AiErrorTypeExtension on AiErrorType {
  /// Whether this error indicates a temporary condition.
  ///
  /// Temporary errors might resolve themselves with time or retry.
  /// Non-temporary errors require user action or configuration changes.
  bool get isTemporary {
    switch (this) {
      case AiErrorType.rateLimited:
      case AiErrorType.timeout:
      case AiErrorType.networkError:
      case AiErrorType.invalidResponse:
      case AiErrorType.localRpmExceeded:
        return true;
      case AiErrorType.parseError:
      case AiErrorType.invalidApiKey:
      case AiErrorType.contentFiltered:
      case AiErrorType.invalidRequest:
      case AiErrorType.localRpdExceeded:
      case AiErrorType.localTokensExceeded:
      case AiErrorType.unknown:
        return false;
    }
  }

  /// Whether this error requires showing a loading/retry indicator to user.
  ///
  /// Retryable errors should show "Retrying..." while non-retryable errors
  /// should show an error state with manual retry option.
  bool get shouldShowRetryIndicator {
    switch (this) {
      case AiErrorType.rateLimited:
      case AiErrorType.timeout:
      case AiErrorType.networkError:
      case AiErrorType.invalidResponse:
        return true;
      default:
        return false;
    }
  }

  /// Whether this error should be logged as critical.
  ///
  /// Critical errors indicate configuration problems or unexpected failures
  /// that need developer attention.
  bool get isCritical {
    switch (this) {
      case AiErrorType.invalidApiKey:
      case AiErrorType.parseError:
        return true;
      default:
        return false;
    }
  }

  /// Technical description for logging purposes.
  String get technicalDescription {
    switch (this) {
      case AiErrorType.rateLimited:
        return 'Gemini API rate limit exceeded';
      case AiErrorType.invalidResponse:
        return 'AI response doesn\'t match expected schema';
      case AiErrorType.parseError:
        return 'Failed to parse JSON from AI response';
      case AiErrorType.timeout:
        return 'AI request exceeded timeout threshold';
      case AiErrorType.networkError:
        return 'Network connection failed during AI request';
      case AiErrorType.invalidApiKey:
        return 'Gemini API key is invalid or missing';
      case AiErrorType.contentFiltered:
        return 'AI safety filters blocked content generation';
      case AiErrorType.invalidRequest:
        return 'User modification request was rejected';
      case AiErrorType.localRpmExceeded:
        return 'Local per-minute request limit exceeded';
      case AiErrorType.localRpdExceeded:
        return 'Local daily request limit exceeded';
      case AiErrorType.localTokensExceeded:
        return 'Local daily token limit exceeded';
      case AiErrorType.unknown:
        return 'Unhandled AI integration error';
    }
  }
}
