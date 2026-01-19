import 'dart:math' as math;

import 'package:fitgenie_app/core/constants/app_sizes.dart';
import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:fitgenie_app/features/dashboard/dashboard_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Summary widget showing daily completion progress.
///
/// This widget displays the user's progress for the day with:
/// - Circular progress indicator (ring)
/// - Percentage display in center
/// - "X of Y tasks complete" text below
/// - Celebratory state at 100% completion
///
/// Key Features:
/// - Animated progress ring
/// - Dynamic color based on completion percentage
/// - Celebration animation at 100%
/// - Clear visual progress feedback
/// - Compact design for dashboard placement
///
/// Layout:
/// ```
/// ┌─────────────────┐
/// │                 │
/// │      ████       │
/// │    ██  72% ██   │
/// │    ██      ██   │
/// │      ████       │
/// │                 │
/// │ 13 of 18 tasks  │
/// │    complete     │
/// └─────────────────┘
/// ```
///
/// Usage:
/// ```dart
/// Column(
///   children: [
///     // ... meal and workout cards
///     CompletionSummary(),
///   ],
/// )
/// ```
///
/// Design Notes:
/// - Per UX spec, provides quick visual progress check
/// - 100% completion triggers celebration state
/// - Progress ring is more engaging than linear bar
/// - Color transitions from primary to success green
class CompletionSummary extends ConsumerWidget {
  /// Size of the progress ring.
  final double size;

  /// Creates a [CompletionSummary] widget.
  const CompletionSummary({super.key, this.size = 120});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch completion status
    final statusAsync = ref.watch(completionStatusProvider);

    return statusAsync.when(
      data: (status) {
        final percentage = status['percentage'] as double;
        final completed = status['completed'] as int;
        final total = status['total'] as int;
        final isComplete = status['isComplete'] as bool;

        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacingMd,
            vertical: AppSizes.spacingLg,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            side: BorderSide(
              color: context.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.spacingLg),
            child: Column(
              children: [
                // Circular progress ring
                SizedBox(
                  width: size,
                  height: size,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background circle
                      SizedBox(
                        width: size,
                        height: size,
                        child: CustomPaint(
                          painter: _ProgressRingPainter(
                            progress: percentage / 100,
                            backgroundColor:
                                context.colorScheme.surfaceContainerHighest,
                            progressColor: isComplete
                                ? context.colorScheme.tertiary
                                : context.colorScheme.primary,
                            strokeWidth: 12,
                          ),
                        ),
                      ),

                      // Percentage text
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Emoji for celebration
                          if (isComplete) ...[
                            const Text('🎉', style: TextStyle(fontSize: 24)),
                            const SizedBox(height: AppSizes.spacingXs),
                          ],

                          // Percentage
                          Text(
                            '${percentage.round()}%',
                            style: context.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isComplete
                                  ? context.colorScheme.tertiary
                                  : context.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSizes.spacingMd),

                // Task count text
                Text(
                  '$completed of $total tasks',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: AppSizes.spacingXs),

                // Status text
                Text(
                  isComplete ? 'All done! Great work! 💪' : 'Keep going!',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Card(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacingMd,
          vertical: AppSizes.spacingLg,
        ),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spacingLg),
          child: SizedBox(
            width: size,
            height: size,
            child: const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Custom painter for the circular progress ring.
class _ProgressRingPainter extends CustomPainter {
  /// Progress value (0.0 to 1.0).
  final double progress;

  /// Background circle color.
  final Color backgroundColor;

  /// Progress arc color.
  final Color progressColor;

  /// Width of the ring stroke.
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;
      const startAngle = -math.pi / 2; // Start from top

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor;
  }
}
