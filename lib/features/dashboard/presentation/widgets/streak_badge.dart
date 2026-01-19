import 'package:fitgenie_app/core/constants/app_sizes.dart';
import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:fitgenie_app/features/dashboard/domain/streak_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Visual badge displaying current streak with fire emoji and animation.
///
/// This widget shows the user's consecutive day completion streak with:
/// - Fire emoji 🔥
/// - Streak count (display large number)
/// - "day streak" label
/// - Celebration animation on milestones (7, 14, 30 days)
/// - Subtle pulse animation when active
///
/// Key Features:
/// - Prominent display for gamification
/// - Milestone celebrations (confetti-style animation)
/// - Pulse animation for active streaks
/// - Compact design for header placement
/// - Different states: no streak, active, milestone
///
/// Layout:
/// ```
/// ┌──────────────┐
/// │  🔥  12      │
/// │  day streak  │
/// └──────────────┘
/// ```
///
/// Usage:
/// ```dart
/// // In dashboard header
/// StreakBadge(streak: streakData)
///
/// // In profile screen
/// Center(
///   child: StreakBadge(
///     streak: streakData,
///     size: StreakBadgeSize.large,
///   ),
/// )
/// ```
///
/// Design Notes:
/// - Per UX spec, streak is prominent for motivation
/// - Milestone animations celebrate achievements
/// - Pulse effect creates "alive" feeling
/// - Fire emoji is universally recognized for streaks
class StreakBadge extends StatefulWidget {
  /// The streak data to display.
  final StreakData streak;

  /// Size variant of the badge.
  final StreakBadgeSize size;

  /// Creates a [StreakBadge] widget.
  const StreakBadge({
    super.key,
    required this.streak,
    this.size = StreakBadgeSize.medium,
  });

  @override
  State<StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends State<StreakBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    // Initialize pulse animation controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Start pulse if streak is active
    if (widget.streak.hasActiveStreak) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StreakBadge oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update pulse animation based on streak status
    if (widget.streak.hasActiveStreak && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.streak.hasActiveStreak && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // No streak - show minimal state
    if (!widget.streak.hasActiveStreak) {
      return _buildNoStreakBadge(context);
    }

    // Get size-specific dimensions
    final dimensions = _getSizeDimensions();

    return Container(
          padding: EdgeInsets.symmetric(
            horizontal: dimensions.horizontalPadding,
            vertical: dimensions.verticalPadding,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                context.colorScheme.primaryContainer,
                context.colorScheme.primaryContainer.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            border: Border.all(
              color: context.colorScheme.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: context.colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fire emoji with pulse animation
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_pulseController.value * 0.15),
                    child: child,
                  );
                },
                child: Text(
                  '🔥',
                  style: TextStyle(fontSize: dimensions.emojiSize),
                ),
              ),

              SizedBox(width: dimensions.spacing),

              // Streak count
              Text(
                '${widget.streak.currentStreak}',
                style: context.textTheme.titleLarge?.copyWith(
                  fontSize: dimensions.numberSize,
                  fontWeight: FontWeight.w800,
                  color: context.colorScheme.onPrimaryContainer,
                  height: 1,
                ),
              ),
            ],
          ),
        )
        .animate(
          onPlay: (controller) {
            // Trigger celebration animation on milestones
            if (widget.streak.isMilestone) {
              controller.forward();
            }
          },
        )
        .shimmer(duration: 2000.ms, color: Colors.white.withValues(alpha: 0.3))
        .animate(
          // Additional celebration for milestones
          target: widget.streak.isMilestone ? 1 : 0,
        )
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.2, 1.2),
          duration: 300.ms,
          curve: Curves.elasticOut,
        )
        .then()
        .scale(
          begin: const Offset(1.2, 1.2),
          end: const Offset(1, 1),
          duration: 300.ms,
        );
  }

  /// Builds the badge for when there's no active streak.
  Widget _buildNoStreakBadge(BuildContext context) {
    final dimensions = _getSizeDimensions();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dimensions.horizontalPadding,
        vertical: dimensions.verticalPadding,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: context.colorScheme.outlineVariant, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gray emoji
          Text('💪', style: TextStyle(fontSize: dimensions.emojiSize)),

          SizedBox(width: dimensions.spacing),

          // Zero streak
          Text(
            '0',
            style: context.textTheme.titleMedium?.copyWith(
              fontSize: dimensions.numberSize,
              fontWeight: FontWeight.w700,
              color: context.colorScheme.onSurfaceVariant,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// Gets size-specific dimensions based on badge size.
  _BadgeDimensions _getSizeDimensions() {
    switch (widget.size) {
      case StreakBadgeSize.small:
        return _BadgeDimensions(
          emojiSize: 16,
          numberSize: 16,
          horizontalPadding: AppSizes.spacingSm,
          verticalPadding: AppSizes.spacing2xs,
          spacing: AppSizes.spacingXs,
        );
      case StreakBadgeSize.medium:
        return _BadgeDimensions(
          emojiSize: 20,
          numberSize: 20,
          horizontalPadding: AppSizes.spacingMd,
          verticalPadding: AppSizes.spacingXs,
          spacing: AppSizes.spacingSm,
        );
      case StreakBadgeSize.large:
        return _BadgeDimensions(
          emojiSize: 32,
          numberSize: 32,
          horizontalPadding: AppSizes.spacingLg,
          verticalPadding: AppSizes.spacingMd,
          spacing: AppSizes.spacingMd,
        );
    }
  }
}

/// Size variants for StreakBadge.
enum StreakBadgeSize {
  /// Small badge (16px emoji, compact padding)
  small,

  /// Medium badge (20px emoji, standard padding) - default
  medium,

  /// Large badge (32px emoji, generous padding)
  large,
}

/// Internal class holding size-specific dimensions.
class _BadgeDimensions {
  final double emojiSize;
  final double numberSize;
  final double horizontalPadding;
  final double verticalPadding;
  final double spacing;

  _BadgeDimensions({
    required this.emojiSize,
    required this.numberSize,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.spacing,
  });
}
