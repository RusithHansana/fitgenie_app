import 'package:fitgenie_app/core/constants/app_sizes.dart';
import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:fitgenie_app/core/extensions/string_extensions.dart';
import 'package:fitgenie_app/features/dashboard/presentation/widgets/task_checkbox.dart';
import 'package:fitgenie_app/features/plan_generation/domain/exercise.dart';
import 'package:flutter/material.dart';

/// List tile for a single exercise within workout card.
///
/// This widget displays comprehensive exercise information including:
/// - Exercise name
/// - Sets × reps display (e.g., "3 × 10-12 reps")
/// - Rest period info (e.g., "90 sec rest")
/// - Equipment required badges
/// - Completion checkbox
/// - Optional notes expansion for form cues
///
/// Key Features:
/// - Compact display with all essential info
/// - Equipment badges for clarity
/// - Expandable notes section for technique tips
/// - Completion checkbox with haptic feedback
/// - Clean list tile design
///
/// Layout:
/// ```
/// ┌─────────────────────────────────────────┐
/// │ [✓] Push-ups                            │
/// │     3 × 15 reps • 60 sec rest           │
/// │     [Bodyweight]                        │
/// │     💡 Keep core tight and back flat   │
/// └─────────────────────────────────────────┘
/// ```
///
/// Usage:
/// ```dart
/// ListView(
///   children: workout.exercises.map((exercise) {
///     return ExerciseTile(
///       exercise: exercise,
///       isComplete: completion.isExerciseComplete(exercise.id),
///       onToggle: () => toggleExerciseComplete(exercise.id),
///     );
///   }).toList(),
/// )
/// ```
///
/// Design Notes:
/// - Per UX spec, form notes are secondary (collapsible)
/// - Equipment tags make personalization visible
/// - Sets/reps format matches existing Exercise model methods
/// - Rest time helps with workout pacing
class ExerciseTile extends StatefulWidget {
  /// The exercise to display.
  final Exercise exercise;

  /// Whether this exercise is marked as complete.
  final bool isComplete;

  /// Callback when completion checkbox is toggled.
  final VoidCallback onToggle;

  /// Creates an [ExerciseTile] widget.
  const ExerciseTile({
    super.key,
    required this.exercise,
    required this.isComplete,
    required this.onToggle,
  });

  @override
  State<ExerciseTile> createState() => _ExerciseTileState();
}

class _ExerciseTileState extends State<ExerciseTile> {
  /// Whether the notes section is expanded.
  bool _notesExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasNotes =
        widget.exercise.notes != null && widget.exercise.notes!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingSm),
      padding: const EdgeInsets.all(AppSizes.spacingMd),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.3,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main row: checkbox and exercise info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Completion checkbox
              TaskCheckbox(
                isChecked: widget.isComplete,
                onChanged: widget.onToggle,
              ),

              const SizedBox(width: AppSizes.spacingMd),

              // Exercise details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Exercise name
                    Text(
                      widget.exercise.name,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.onSurface,
                        decoration: widget.isComplete
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: context.colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: AppSizes.spacingXs),

                    // Sets, reps, and rest time
                    Text(
                      '${widget.exercise.setsRepsDisplay} • ${widget.exercise.restDisplay}',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),

                    // Equipment badges
                    if (widget.exercise.equipmentRequired.isNotEmpty &&
                        !widget.exercise.isBodyweight) ...[
                      const SizedBox(height: AppSizes.spacingXs),
                      Wrap(
                        spacing: AppSizes.spacingXs,
                        runSpacing: AppSizes.spacingXs,
                        children: widget.exercise.equipmentRequired
                            .map(
                              (equipment) =>
                                  _EquipmentBadge(equipment: equipment),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Notes section (expandable if notes exist)
          if (hasNotes) ...[
            const SizedBox(height: AppSizes.spacingSm),

            // Notes toggle button
            InkWell(
              onTap: () {
                setState(() {
                  _notesExpanded = !_notesExpanded;
                });
              },
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSizes.spacingXs,
                ),
                child: Row(
                  children: [
                    Icon(
                      _notesExpanded
                          ? Icons.lightbulb
                          : Icons.lightbulb_outline,
                      size: 16,
                      color: context.colorScheme.tertiary,
                    ),
                    const SizedBox(width: AppSizes.spacingXs),
                    Text(
                      _notesExpanded ? 'Hide tips' : 'Form tips',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.colorScheme.tertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Notes content (expandable)
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: AppSizes.spacingXs),
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.spacingSm),
                  decoration: BoxDecoration(
                    color: context.colorScheme.tertiaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: context.colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: AppSizes.spacingXs),
                      Expanded(
                        child: Text(
                          widget.exercise.notes!,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onTertiaryContainer,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              crossFadeState: _notesExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ],
      ),
    );
  }
}

/// Badge displaying required equipment.
class _EquipmentBadge extends StatelessWidget {
  /// The equipment name to display.
  final String equipment;

  const _EquipmentBadge({required this.equipment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacingSm,
        vertical: AppSizes.spacing2xs,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(
          color: context.colorScheme.secondary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getEquipmentIcon(equipment),
            style: const TextStyle(fontSize: 10),
          ),
          const SizedBox(width: AppSizes.spacing2xs),
          Text(
            equipment.toLowerCase().capitalize,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// Gets emoji icon for equipment type.
  String _getEquipmentIcon(String equipment) {
    final lower = equipment.toLowerCase();
    if (lower.contains('dumbbell')) return '🏋️';
    if (lower.contains('barbell')) return '🏋️';
    if (lower.contains('bench')) return '🪑';
    if (lower.contains('pull')) return '🔗';
    if (lower.contains('bar')) return '📏';
    if (lower.contains('mat')) return '🧘';
    if (lower.contains('band')) return '🎗️';
    if (lower.contains('ball')) return '⚽';
    if (lower.contains('rope')) return '🪢';
    if (lower.contains('machine')) return '⚙️';
    return '🔧';
  }
}
