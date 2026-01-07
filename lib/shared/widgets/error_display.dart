import 'package:fitgenie_app/core/constants/app_strings.dart';
import 'package:fitgenie_app/core/exceptions/app_exception.dart';
import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:fitgenie_app/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';

/// User-friendly error display widget with retry functionality.
///
/// This widget provides a consistent interface for displaying errors throughout
/// the app, extracting user-friendly messages from [AppException] instances and
/// providing appropriate fallback messaging for unexpected errors.
///
/// Features:
/// - Extracts [userFriendlyMessage] from [AppException] hierarchy
/// - Fallback messages for non-AppException errors
/// - Optional retry action button
/// - Two display modes: inline and full-screen
/// - Error icon and appropriate styling
/// - Never exposes raw exception details to users
///
/// Usage with Riverpod AsyncValue:
/// ```dart
/// ref.watch(dataProvider).when(
///   data: (data) => DataView(data),
///   loading: () => LoadingIndicator(),
///   error: (error, stack) => ErrorDisplay(
///     error: error,
///     onRetry: () => ref.invalidate(dataProvider),
///   ),
/// )
/// ```
///
/// Full-screen error:
/// ```dart
/// ErrorDisplay(
///   error: exception,
///   onRetry: _retryOperation,
///   fullScreen: true,
/// )
/// ```
///
/// Best Practices:
/// - Always provide onRetry callback for recoverable errors
/// - Use fullScreen mode for critical failures blocking entire screen
/// - Use inline mode for partial content failures (e.g., one section failed)
/// - Log technical details separately for debugging (don't show to users)
class ErrorDisplay extends StatelessWidget {
  /// The error object to display.
  ///
  /// If this is an [AppException], the widget extracts the
  /// [AppException.userFriendlyMessage]. For other error types,
  /// a generic fallback message is displayed.
  final Object error;

  /// Optional callback invoked when user taps the retry button.
  ///
  /// If null, no retry button is shown. Provide this callback for
  /// recoverable errors where retrying the operation makes sense.
  final VoidCallback? onRetry;

  /// Whether to display in full-screen mode.
  ///
  /// - true: Centers content and expands to fill available space
  /// - false: Uses column layout for inline display within other content
  ///
  /// Defaults to false (inline mode).
  final bool fullScreen;

  /// Optional custom error icon.
  ///
  /// Defaults to [Icons.error_outline] if not provided.
  final IconData? icon;

  /// Creates an [ErrorDisplay] widget.
  ///
  /// The [error] parameter is required. Provide [onRetry] callback
  /// for recoverable errors.
  const ErrorDisplay({
    super.key,
    required this.error,
    this.onRetry,
    this.fullScreen = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final errorMessage = _extractUserFriendlyMessage();
    final errorIcon = icon ?? Icons.error_outline;

    final content = Column(
      mainAxisSize: fullScreen ? MainAxisSize.min : MainAxisSize.min,
      crossAxisAlignment: fullScreen
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        // Error icon
        Icon(
          errorIcon,
          size: fullScreen ? 64 : 48,
          color: context.colorScheme.error,
        ),
        const SizedBox(height: 16),

        // Error message
        Text(
          errorMessage,
          style: fullScreen
              ? context.textTheme.titleMedium
              : context.textTheme.bodyLarge,
          textAlign: fullScreen ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 8),

        // Helper text for full-screen mode
        if (fullScreen)
          Text(
            'Please try again or contact support if the problem persists.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

        // Retry button (if callback provided)
        if (onRetry != null) ...[
          const SizedBox(height: 24),
          AppButton(
            label: 'Retry',
            onPressed: onRetry,
            variant: fullScreen
                ? ButtonVariant.primary
                : ButtonVariant.secondary,
            fullWidth: !fullScreen,
            icon: Icons.refresh,
          ),
        ],
      ],
    );

    // Wrap in centered, padded container for full-screen mode
    if (fullScreen) {
      return Center(
        child: Padding(padding: const EdgeInsets.all(32.0), child: content),
      );
    }

    // Return as-is for inline mode
    return Padding(padding: const EdgeInsets.all(16.0), child: content);
  }

  /// Extracts a user-friendly error message from the error object.
  ///
  /// Handles multiple error types:
  /// - [AppException]: Uses [userFriendlyMessage] property
  /// - [Exception]: Attempts to extract message from toString()
  /// - Other types: Returns generic fallback message
  ///
  /// This ensures users never see raw stack traces or technical details.
  String _extractUserFriendlyMessage() {
    // Check if error is an AppException (our typed exceptions)
    if (error is AppException) {
      return (error as AppException).userFriendlyMessage;
    }

    // Check if error is a standard Exception with message
    if (error is Exception) {
      // Try to extract message from Exception.toString()
      final exceptionString = error.toString();

      // Remove "Exception: " prefix if present
      if (exceptionString.startsWith('Exception: ')) {
        final message = exceptionString.substring('Exception: '.length);
        // Only return if it looks like a user-friendly message
        // (not a stack trace or technical error)
        if (!message.contains('at ') && message.length < 200) {
          return message;
        }
      }
    }

    // Fallback to generic error message for unknown error types
    return AppStrings.errorGeneric;
  }
}

/// Compact error banner for inline error display.
///
/// A lightweight alternative to [ErrorDisplay] for showing errors
/// in a compact banner format, suitable for displaying at the top
/// of lists or sections without disrupting the overall layout.
///
/// Usage:
/// ```dart
/// Column(
///   children: [
///     if (hasError)
///       ErrorBanner(
///         message: 'Failed to load updates',
///         onDismiss: () => setState(() => hasError = false),
///       ),
///     // ... rest of content
///   ],
/// )
/// ```
class ErrorBanner extends StatelessWidget {
  /// The error message to display.
  final String message;

  /// Optional callback when user dismisses the banner.
  ///
  /// If provided, shows a close button. If null, banner cannot be dismissed.
  final VoidCallback? onDismiss;

  /// Creates an [ErrorBanner] with the specified message.
  const ErrorBanner({super.key, required this.message, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              size: 20,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
            if (onDismiss != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 20,
                  color: theme.colorScheme.onErrorContainer,
                ),
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Dismiss',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
