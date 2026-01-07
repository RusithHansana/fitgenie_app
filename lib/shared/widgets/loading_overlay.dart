import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';

/// Full-screen loading overlay for blocking operations.
///
/// This widget provides a semi-transparent overlay that covers the entire screen
/// with a centered loading indicator, preventing user interaction during long-running
/// operations such as AI plan generation, authentication, or data synchronization.
///
/// Features:
/// - Semi-transparent black backdrop to dim underlying content
/// - Centered [CircularProgressIndicator]
/// - Optional loading message text below indicator
/// - Blocks all touch interactions via [IgnorePointer]
/// - Wraps child content in a [Stack] for overlay effect
/// - Smooth fade in/out animation when loading state changes
///
/// Usage:
/// ```dart
/// LoadingOverlay(
///   isLoading: _isGeneratingPlan,
///   message: 'Creating your personalized plan...',
///   child: YourScreenContent(),
/// )
/// ```
///
/// Best Practices:
/// - Use for operations taking >2 seconds (shorter operations use inline loaders)
/// - Provide informative messages to keep users engaged
/// - Ensure operations have reasonable timeouts to prevent indefinite blocking
/// - For non-blocking loading states, use [SkeletonLoader] instead
class LoadingOverlay extends StatelessWidget {
  /// Whether the loading overlay should be visible.
  ///
  /// When true, displays the overlay with loading indicator.
  /// When false, shows only the [child] widget.
  final bool isLoading;

  /// Optional message displayed below the loading indicator.
  ///
  /// Use to provide context about the ongoing operation.
  /// Examples: "Creating your plan...", "Signing in...", "Syncing data..."
  final String? message;

  /// The child widget that is wrapped by this overlay.
  ///
  /// This is the main content of the screen that will be dimmed
  /// and made non-interactive when loading.
  final Widget child;

  /// Creates a [LoadingOverlay] that wraps the provided [child].
  ///
  /// The [child] parameter is required. The overlay is shown when
  /// [isLoading] is true.
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    this.message,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        child,

        // Loading overlay layer
        if (isLoading)
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: isLoading ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: _LoadingOverlayContent(message: message),
            ),
          ),
      ],
    );
  }
}

/// Internal widget containing the overlay visual elements.
///
/// Separated into its own widget for better organization and to avoid
/// rebuilding the child when only the overlay state changes.
class _LoadingOverlayContent extends StatelessWidget {
  final String? message;

  const _LoadingOverlayContent({this.message});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: false, // This layer should absorb touches
      child: Container(
        color: Colors.black54, // Semi-transparent black background
        child: Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 24.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Circular progress indicator
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      context.colorScheme.primary,
                    ),
                  ),

                  // Optional loading message
                  if (message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      message!,
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: context.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
