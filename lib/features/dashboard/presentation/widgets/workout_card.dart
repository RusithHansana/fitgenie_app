import 'package:fitgenie_app/core/constants/app_sizes.dart';
import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:fitgenie_app/core/utils/formatters.dart';
import 'package:fitgenie_app/features/dashboard/presentation/widgets/exercise_tile.dart';
import 'package:fitgenie_app/features/plan_generation/domain/workout.dart';
import 'package:flutter/material.dart';

/// Card displaying workout overview with expandable exercise list.
///
/// This widget shows comprehensive workout information including:
/// - Workout name and type badge (strength, cardio, flexibility, rest)
/// - Duration display
/// - Exercise count and completion progress
/// - Expandable exercise list using ExerciseTile
/// - Overall completion summary bar
///
/// Key Features:
/// - Expandable/collapsible exercise list
/// - Progress bar showing completion percentage
/// - Type-specific styling (strength, cardio, etc.)
/// - Rest day handling (special display)
/// - Clean card design with proper spacing
///
/// Layout:
/// ```
/// ┌─────────────────────────────────────────┐
/// │ Upper Body Strength        💪 Strength  │
/// │ 45 minutes • 5 exercises                │
/// │ ████████░░░░░░░░ 3/5 complete          │
/// │                                          │
/// │ ▼ Exercises (tap to expand)             │
/// │ [✓] Push-ups: 3 × 15 reps               │
/// │ [✓] Dumbbell Rows: 3 × 10-12 reps      │
/// │ [✓] Bench Press: 3 × 8-10 reps         │
/// │ [ ] Shoulder Press: 3 × 10 reps        │
/// │ [ ] Tricep Dips: 3 × 12 reps           │
/// └─────────────────────────────────────────┘
/// ```
///
/// Usage:
/// ```dart
/// Column(
///   children: [
///     if (dayPlan.hasWorkout)
///       WorkoutCard(
///         workout: dayPlan.workout!,
///         completedExerciseIds: completion.completedExerciseIds,
///       ),
///   ],
/// )
/// ```
///
/// Design Notes:
/// - Per UX spec, exercise list collapses by default
/// - Progress bar provides quick visual feedback
/// - Rest days get special "Recovery Day" treatment
/// - Type badges make workout categorization clear
class WorkoutCard extends StatefulWidget {
  /// The workout to display.
  final Workout workout;

  /// List of completed exercise IDs.
  final List<String> completedExerciseIds;

  /// Callback when an exercise completion is toggled.
  final void Function(String exerciseId) onExerciseToggle;

  /// Creates a [WorkoutCard] widget.
  const WorkoutCard({
    super.key,
    required this.workout,
    required this.completedExerciseIds,
    required this.onExerciseToggle,
  });

  @override
  State<WorkoutCard> createState() => _WorkoutCardState();
}

class _WorkoutCardState extends State<WorkoutCard> {
  /// Whether the exercise list is expanded.
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Handle rest days
    if (widget.workout.type == WorkoutType.rest) {
      return _RestDayCard();
    }

    // Calculate completion stats
    final totalExercises = widget.workout.exercises.length;
    final completedCount = widget.workout.exercises
        .where((ex) => widget.completedExerciseIds.contains(ex.id))
        .length;
    final completionPercentage = totalExercises > 0
        ? (completedCount / totalExercises) * 100
        : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacingMd,
        vertical: AppSizes.spacingSm,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        side: BorderSide(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: workout name and type badge
              Row(
                children: [
                  // Workout name
                  Expanded(
                    child: Text(
                      widget.workout.name,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                  ),

                  const SizedBox(width: AppSizes.spacingSm),

                  // Workout type badge
                  _WorkoutTypeBadge(type: widget.workout.type),
                ],
              ),

              const SizedBox(height: AppSizes.spacingSm),

              // Duration and exercise count
              Text(
                '${Formatters.duration(widget.workout.durationMinutes)} • '
                '${Formatters.count(totalExercises, 'exercise')}',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: AppSizes.spacingMd),

              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusFull,
                          ),
                          child: LinearProgressIndicator(
                            value: completionPercentage / 100,
                            minHeight: 8,
                            backgroundColor:
                                context.colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              completionPercentage == 100
                                  ? context.colorScheme.tertiary
                                  : context.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.spacingSm),
                      Text(
                        Formatters.completionRatio(
                          completedCount,
                          totalExercises,
                        ),
                        style: context.textTheme.labelMedium?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.spacingMd),

              // Expand/collapse indicator
              Row(
                children: [
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                    color: context.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSizes.spacingXs),
                  Text(
                    _isExpanded ? 'Hide exercises' : 'Show exercises',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Exercise list (expandable)
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: AppSizes.spacingMd),
                  child: Column(
                    children: widget.workout.exercises.map((exercise) {
                      final isComplete = widget.completedExerciseIds.contains(
                        exercise.id,
                      );
                      return ExerciseTile(
                        exercise: exercise,
                        isComplete: isComplete,
                        onToggle: () => widget.onExerciseToggle(exercise.id),
                      );
                    }).toList(),
                  ),
                ),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge displaying workout type (strength, cardio, flexibility, rest).
class _WorkoutTypeBadge extends StatelessWidget {
  /// The workout type to display.
  final WorkoutType type;

  const _WorkoutTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacingSm,
        vertical: AppSizes.spacing2xs,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(type.icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: AppSizes.spacing2xs),
          Text(
            type.displayName,
            style: context.textTheme.labelSmall?.copyWith(
              color: _getTextColor(context),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// Gets background color based on workout type.
  Color _getBackgroundColor(BuildContext context) {
    switch (type) {
      case WorkoutType.strength:
        return context.colorScheme.primaryContainer;
      case WorkoutType.cardio:
        return context.colorScheme.secondaryContainer;
      case WorkoutType.flexibility:
        return context.colorScheme.tertiaryContainer;
      case WorkoutType.rest:
        return context.colorScheme.surfaceContainerHighest;
    }
  }

  /// Gets text color based on workout type.
  Color _getTextColor(BuildContext context) {
    switch (type) {
      case WorkoutType.strength:
        return context.colorScheme.onPrimaryContainer;
      case WorkoutType.cardio:
        return context.colorScheme.onSecondaryContainer;
      case WorkoutType.flexibility:
        return context.colorScheme.onTertiaryContainer;
      case WorkoutType.rest:
        return context.colorScheme.onSurface;
    }
  }
}

/// Special card for rest days.
class _RestDayCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacingMd,
        vertical: AppSizes.spacingSm,
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
            // Rest emoji
            const Text('😌', style: TextStyle(fontSize: 48)),

            const SizedBox(height: AppSizes.spacingMd),

            // Rest day title
            Text(
              'Rest & Recovery Day',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSizes.spacingSm),

            // Rest day message
            Text(
              'Take this time to let your body recover. Light stretching or walking is great!',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
