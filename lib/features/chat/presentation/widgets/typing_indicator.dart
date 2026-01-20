import 'package:fitgenie_app/core/constants/app_sizes.dart';
import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Animated indicator showing AI is generating a response.
///
/// This widget displays a typing animation similar to ChatGPT and other
/// messaging apps, indicating that the AI assistant is processing and
/// generating a response.
///
/// Features:
/// - Three animated dots with pulse/fade effect
/// - Assistant bubble styling (matches ChatBubble)
/// - Optional "FitGenie is thinking..." label
/// - Smooth looping animation
/// - Matches chat bubble design language
///
/// Visual Design:
/// - Three dots arranged horizontally
/// - Sequential fade and scale animation
/// - Assistant message styling (left-aligned, surface color)
/// - Subtle animation (not distracting)
/// - Infinite loop while AI is processing
///
/// Animation:
/// - Each dot fades in/out and scales
/// - Staggered timing (dot 2 starts after dot 1, etc.)
/// - 1.2s total animation duration
/// - Smooth easing curves
///
/// Usage:
/// ```dart
/// // Show during AI response
/// if (isTyping) {
///   TypingIndicator()
/// }
///
/// // With custom label
/// TypingIndicator(
///   showLabel: true,
///   label: 'Updating your plan...',
/// )
/// ```
///
/// Architecture Notes:
/// - Uses flutter_animate for smooth animations
/// - Stateless widget (animation handled by flutter_animate)
/// - Follows assistant message styling from ChatBubble
/// - Minimal performance impact (optimized animations)
class TypingIndicator extends StatelessWidget {
  /// Whether to show the label text.
  ///
  /// When true, displays "FitGenie is thinking..." or custom [label].
  final bool showLabel;

  /// Custom label text to display.
  ///
  /// Defaults to "FitGenie is thinking..."
  final String? label;

  /// Creates a TypingIndicator widget.
  ///
  /// Set [showLabel] to true to display text alongside the dots.
  const TypingIndicator({super.key, this.showLabel = false, this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacingMd,
          vertical: AppSizes.spacingSm,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacingMd,
            vertical: AppSizes.spacingMd,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppSizes.radiusMd),
              topRight: Radius.circular(AppSizes.radiusMd),
              bottomLeft: Radius.circular(AppSizes.spacingSm),
              bottomRight: Radius.circular(AppSizes.radiusMd),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Three animated dots
              _buildDot(colorScheme, delay: 0.ms),
              const SizedBox(width: AppSizes.spacingXs),
              _buildDot(colorScheme, delay: 200.ms),
              const SizedBox(width: AppSizes.spacingXs),
              _buildDot(colorScheme, delay: 400.ms),

              // Optional label
              if (showLabel) ...[
                const SizedBox(width: AppSizes.spacingMd),
                Text(
                  label ?? 'FitGenie is thinking...',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a single animated dot.
  Widget _buildDot(ColorScheme colorScheme, {required Duration delay}) {
    return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: colorScheme.onSurfaceVariant,
            shape: BoxShape.circle,
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .fadeIn(duration: 600.ms, delay: delay, curve: Curves.easeInOut)
        .scale(
          begin: const Offset(0.6, 0.6),
          end: const Offset(1.0, 1.0),
          duration: 600.ms,
          delay: delay,
          curve: Curves.easeInOut,
        )
        .then(delay: 600.ms)
        .fadeOut(duration: 600.ms, curve: Curves.easeInOut)
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(0.6, 0.6),
          duration: 600.ms,
          curve: Curves.easeInOut,
        );
  }
}
