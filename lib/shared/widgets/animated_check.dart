import 'package:fitgenie_app/core/constants/app_colors.dart';
import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Animated checkmark widget for task completion feedback with haptic.
///
/// This widget provides satisfying visual and tactile feedback when users
/// complete tasks (workouts, meals, etc.). It animates a checkmark icon with
/// scale and fade effects while triggering haptic feedback per UX specification.
///
/// Features:
/// - Scale animation on completion (~300ms)
/// - Fade in/out transitions
/// - Haptic feedback (medium impact)
/// - Success color from theme
/// - Only animates on false → true transition
/// - Optimized to prevent unnecessary rebuilds
///
/// Usage:
/// ```dart
/// AnimatedCheck(
///   isComplete: _isTaskComplete,
///   onComplete: () => print('Task completed!'),
/// )
/// ```
///
/// Integration with checkbox:
/// ```dart
/// CheckboxListTile(
///   value: isComplete,
///   onChanged: (value) => setState(() => isComplete = value!),
///   secondary: AnimatedCheck(isComplete: isComplete),
/// )
/// ```
///
/// Design Notes:
/// Per UX spec, completion should feel rewarding with instant gratification.
/// The animation creates a micro-celebration moment that reinforces positive
/// behavior and encourages habit formation.
class AnimatedCheck extends StatefulWidget {
  /// Whether the checkmark should be in completed state.
  ///
  /// Animation triggers when this changes from false to true.
  final bool isComplete;

  /// Optional callback invoked when completion animation starts.
  ///
  /// Useful for triggering side effects like updating streak counts
  /// or logging completion events.
  final VoidCallback? onComplete;

  /// Size of the checkmark icon.
  ///
  /// Defaults to 24dp.
  final double size;

  /// Whether to trigger haptic feedback on completion.
  ///
  /// Defaults to true. Set to false for silent completions.
  final bool enableHaptic;

  /// Creates an [AnimatedCheck] widget.
  ///
  /// The [isComplete] parameter is required and determines the visual state.
  const AnimatedCheck({
    super.key,
    required this.isComplete,
    this.onComplete,
    this.size = 24,
    this.enableHaptic = true,
  });

  @override
  State<AnimatedCheck> createState() => _AnimatedCheckState();
}

class _AnimatedCheckState extends State<AnimatedCheck> {
  /// Previous completion state to detect transitions.
  late bool _wasComplete;

  @override
  void initState() {
    super.initState();
    _wasComplete = widget.isComplete;
  }

  @override
  void didUpdateWidget(AnimatedCheck oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Detect completion transition (false → true)
    if (!_wasComplete && widget.isComplete) {
      _handleCompletion();
    }

    // Update previous state
    _wasComplete = widget.isComplete;
  }

  /// Handles completion transition with haptic feedback and callback.
  void _handleCompletion() {
    // Trigger haptic feedback if enabled
    if (widget.enableHaptic) {
      HapticFeedback.mediumImpact();
    }

    // Invoke completion callback if provided
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    // Determine icon and color based on completion state
    final icon = widget.isComplete
        ? Icons.check_circle
        : Icons.check_circle_outline;

    final color = widget.isComplete
        ? AppColors.success
        : context.colorScheme.outline;

    return Icon(icon, size: widget.size, color: color)
        // Apply scale animation when completing
        .animate(target: widget.isComplete ? 1 : 0)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          duration: 300.ms,
          curve: Curves.easeOutBack,
        )
        // Apply fade animation
        .fade(begin: 0.0, end: 1.0, duration: 200.ms);
  }
}

/// Animated checkbox with integrated checkmark animation.
///
/// A complete checkbox implementation that combines standard checkbox
/// behavior with [AnimatedCheck] visual feedback. This is a convenience
/// widget for common task completion UX patterns.
///
/// Usage:
/// ```dart
/// AnimatedCheckbox(
///   value: isComplete,
///   onChanged: (value) => setState(() => isComplete = value),
///   label: 'Complete workout',
/// )
/// ```
class AnimatedCheckbox extends StatelessWidget {
  /// Current checkbox state.
  final bool value;

  /// Callback invoked when checkbox is toggled.
  final ValueChanged<bool>? onChanged;

  /// Optional label text displayed next to checkbox.
  final String? label;

  /// Whether the checkbox is enabled for interaction.
  ///
  /// Defaults to true.
  final bool enabled;

  /// Creates an [AnimatedCheckbox] with integrated animation.
  const AnimatedCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnChanged = enabled ? onChanged : null;

    return InkWell(
      onTap: effectiveOnChanged != null
          ? () => effectiveOnChanged(!value)
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Row(
          children: [
            AnimatedCheck(isComplete: value, enableHaptic: enabled),
            if (label != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label!,
                  style: context.textTheme.bodyLarge?.copyWith(
                    decoration: value ? TextDecoration.lineThrough : null,
                    color: value
                        ? context.colorScheme.onSurfaceVariant
                        : context.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
