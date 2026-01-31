import 'package:fitgenie_app/core/constants/app_sizes.dart';
import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:fitgenie_app/core/utils/formatters.dart';
import 'package:fitgenie_app/features/dashboard/presentation/widgets/task_checkbox.dart';
import 'package:fitgenie_app/features/plan_generation/domain/meal.dart';
import 'package:flutter/material.dart';

/// Card displaying a single meal with completion toggle.
///
/// This widget shows comprehensive meal information including:
/// - Meal name and type badge (breakfast, lunch, dinner, snack)
/// - Calorie and macronutrient display
/// - Collapsible ingredient list
/// - Preparation instructions
/// - Completion checkbox
/// - Dietary restriction badges (if applicable)
///
/// Key Features:
/// - Expandable/collapsible ingredient list
/// - Animated completion state
/// - Dietary compliance indicators
/// - Clean card design with proper spacing
/// - Haptic feedback on completion
///
/// Layout:
/// ```
/// ┌─────────────────────────────────────────┐
/// │ [✓] Greek Yogurt Parfait   [Breakfast]  │
/// │     350 cal • P:25g C:45g F:8g          │
/// │     🥬 Vegetarian                        │
/// │                                          │
/// │     ▼ Ingredients (tap to expand)       │
/// │     • 1 cup Greek yogurt                │
/// │     • 1/2 cup granola                   │
/// │     • 1/2 cup berries                   │
/// │                                          │
/// │     Instructions: Layer and enjoy       │
/// └─────────────────────────────────────────┘
/// ```
///
/// Usage:
/// ```dart
/// ListView(
///   children: dayPlan.meals.map((meal) {
///     return MealCard(
///       meal: meal,
///       isComplete: completion.isMealComplete(meal.id),
///       onToggle: () => toggleMealComplete(meal.id),
///     );
///   }).toList(),
/// )
/// ```
///
/// Design Notes:
/// - Per UX spec, completion should feel rewarding
/// - Ingredient list collapses by default to reduce scroll
/// - Dietary badges make personalization visible
/// - Clear macro breakdown for nutrition awareness
class MealCard extends StatefulWidget {
  /// The meal to display.
  final Meal meal;

  /// Whether this meal is marked as complete.
  final bool isComplete;

  /// Callback when completion checkbox is toggled.
  final VoidCallback onToggle;

  /// Creates a [MealCard] widget.
  const MealCard({
    super.key,
    required this.meal,
    required this.isComplete,
    required this.onToggle,
  });

  @override
  State<MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<MealCard> {
  /// Whether the ingredient list is expanded.
  bool _isExpanded = false;

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
              // Header row: checkbox, name, type badge
              Row(
                children: [
                  // Completion checkbox
                  TaskCheckbox(
                    isChecked: widget.isComplete,
                    onChanged: widget.onToggle,
                  ),

                  const SizedBox(width: AppSizes.spacingMd),

                  // Meal name
                  Expanded(
                    child: Text(
                      widget.meal.name,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.onSurface,
                        decoration: widget.isComplete
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),

                  const SizedBox(width: AppSizes.spacingSm),

                  // Meal type badge
                  _MealTypeBadge(type: widget.meal.type),
                ],
              ),

              const SizedBox(height: AppSizes.spacingSm),

              // Nutrition info
              Padding(
                padding: const EdgeInsets.only(left: 52), // Align with name
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Calories and macros
                    Text(
                      '${Formatters.calories(widget.meal.calories)} • '
                      'P:${widget.meal.protein}g C:${widget.meal.carbs}g F:${widget.meal.fat}g',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),

                    // Dietary restriction badges (if any)
                    if (widget.meal.dietaryInfo.isNotEmpty) ...[
                      const SizedBox(height: AppSizes.spacingXs),
                      Wrap(
                        spacing: AppSizes.spacingXs,
                        runSpacing: AppSizes.spacingXs,
                        children: widget.meal.dietaryInfo
                            .map((info) => _DietaryBadge(label: info))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),

              // Expandable ingredients section
              const SizedBox(height: AppSizes.spacingMd),

              // Expand/collapse indicator
              Padding(
                padding: const EdgeInsets.only(left: 52),
                child: Row(
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
                      _isExpanded ? 'Hide ingredients' : 'Show ingredients',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Ingredients list (expandable)
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(
                    left: 52,
                    top: AppSizes.spacingMd,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ingredients
                      ...widget.meal.ingredients.map((ingredient) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSizes.spacingXs,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: context.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  ingredient,
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    color: context.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      // Instructions (if available)
                      if (widget.meal.instructions != null &&
                          widget.meal.instructions!.isNotEmpty) ...[
                        const SizedBox(height: AppSizes.spacingMd),
                        Text(
                          'Instructions:',
                          style: context.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacingXs),
                        Text(
                          widget.meal.instructions!,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
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

/// Badge displaying meal type (breakfast, lunch, dinner, snack).
class _MealTypeBadge extends StatelessWidget {
  /// The meal type to display.
  final MealType type;

  const _MealTypeBadge({required this.type});

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

  /// Gets background color based on meal type.
  Color _getBackgroundColor(BuildContext context) {
    switch (type) {
      case MealType.breakfast:
        return context.colorScheme.primaryContainer;
      case MealType.lunch:
        return context.colorScheme.secondaryContainer;
      case MealType.dinner:
        return context.colorScheme.tertiaryContainer;
      case MealType.snack:
        return context.colorScheme.surfaceContainer;
    }
  }

  /// Gets text color based on meal type.
  Color _getTextColor(BuildContext context) {
    switch (type) {
      case MealType.breakfast:
        return context.colorScheme.onPrimaryContainer;
      case MealType.lunch:
        return context.colorScheme.onSecondaryContainer;
      case MealType.dinner:
        return context.colorScheme.onTertiaryContainer;
      case MealType.snack:
        return context.colorScheme.onSurface;
    }
  }
}

/// Badge displaying dietary restriction or compliance.
class _DietaryBadge extends StatelessWidget {
  /// The dietary label to display.
  final String label;

  const _DietaryBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacingSm,
        vertical: AppSizes.spacing2xs,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(
          color: context.colorScheme.tertiary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🥬', style: TextStyle(fontSize: 10)),
          const SizedBox(width: AppSizes.spacing2xs),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
