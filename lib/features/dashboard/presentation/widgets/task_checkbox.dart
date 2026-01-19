import 'package:fitgenie_app/core/constants/app_sizes.dart';
import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:fitgenie_app/shared/widgets/animated_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Animated checkbox for task completion with haptic feedback.
///
/// This widget provides a custom-styled checkbox matching the FitGenie brand
/// with smooth animations and haptic feedback for task completion. It wraps
/// the shared AnimatedCheck widget with additional touch handling and styling.
///
/// Key Features:
/// - Custom checkbox design matching brand colors
/// - Animated check/uncheck transitions
/// - Haptic feedback on completion (medium impact)
/// - Disabled state styling
/// - Consistent 44dp touch target for accessibility
/// - Works with AnimatedCheck for smooth animations
///
/// Visual States:
/// - Unchecked: Empty square with border
/// - Checked: Filled square with checkmark animation
/// - Disabled: Grayed out appearance
///
/// Layout:
/// ```
/// [ ] Unchecked
/// [✓] Checked (with animation)
/// [◻] Disabled
/// ```
///
/// Usage:
/// ```dart
/// TaskCheckbox(
///   isChecked: meal.isComplete,
///   onChanged: () {
///     // Toggle meal completion
///     toggleMealComplete(meal.id);
///   },
/// )
///
/// // Disabled state
/// TaskCheckbox(
///   isChecked: false,
///   onChanged: null, // Disabled
/// )
/// ```
///
/// Design Notes:
/// - Per UX spec, instant gratification with haptic feedback
/// - Animation creates micro-celebration moment
/// - Touch target meets accessibility guidelines (44dp)
/// - Visual feedback reinforces positive behavior
class TaskCheckbox extends StatelessWidget {
  /// Whether the checkbox is checked.
  final bool isChecked;

  /// Callback when checkbox is tapped.
  ///
  /// If null, checkbox is disabled.
  final VoidCallback? onChanged;

  /// Size of the checkbox.
  ///
  /// Defaults to 24dp.
  final double size;

  /// Creates a [TaskCheckbox] widget.
  const TaskCheckbox({
    super.key,
    required this.isChecked,
    required this.onChanged,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onChanged != null;

    return GestureDetector(
      onTap: isEnabled ? _handleTap : null,
      child: Container(
        width: AppSizes.touchTargetMin,
        height: AppSizes.touchTargetMin,
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: _getBackgroundColor(context, isEnabled),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              border: Border.all(
                color: _getBorderColor(context, isEnabled),
                width: 2,
              ),
            ),
            child: isChecked
                ? AnimatedCheck(
                    isComplete: isChecked,
                    size: size * 0.7,
                    enableHaptic: isEnabled,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  /// Handles checkbox tap with haptic feedback.
  void _handleTap() {
    if (onChanged != null) {
      // Trigger haptic feedback
      HapticFeedback.mediumImpact();

      // Call the callback
      onChanged!();
    }
  }

  /// Gets background color based on state.
  Color _getBackgroundColor(BuildContext context, bool isEnabled) {
    if (!isEnabled) {
      return context.colorScheme.surfaceContainerHighest;
    }

    if (isChecked) {
      return context.colorScheme.primary;
    }

    return context.colorScheme.surface;
  }

  /// Gets border color based on state.
  Color _getBorderColor(BuildContext context, bool isEnabled) {
    if (!isEnabled) {
      return context.colorScheme.outlineVariant;
    }

    if (isChecked) {
      return context.colorScheme.primary;
    }

    return context.colorScheme.outline;
  }
}
