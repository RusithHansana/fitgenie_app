import 'package:fitgenie_app/core/constants/app_sizes.dart';
import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:fitgenie_app/core/extensions/date_extensions.dart';
import 'package:fitgenie_app/features/dashboard/dashboard_providers.dart';
import 'package:fitgenie_app/features/plan_generation/plan_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Horizontal scrollable day picker for navigating the 7-day plan.
///
/// This widget provides day navigation for the weekly plan, showing all 7 days
/// with visual indicators for:
/// - Today's date (highlighted)
/// - Selected day (different styling)
/// - Completion status per day (checkmark icon)
/// - Day of week and date number
///
/// Key Features:
/// - Horizontal scroll with 7 day buttons
/// - Animated selection transitions
/// - Completion indicators
/// - Swipe-friendly design
/// - Auto-scroll to selected day
///
/// Layout:
/// ```
/// ┌────┬────┬────┬────┬────┬────┬────┐
/// │Mon │Tue │Wed │Thu │Fri │Sat │Sun │
/// │ 15 │ 16 │ 17●│ 18 │ 19 │ 20 │ 21 │
/// │ ✓  │ ✓  │[●]│    │    │    │    │
/// └────┴────┴────┴────┴────┴────┴────┘
/// ● = Today, [●] = Selected, ✓ = Complete
/// ```
///
/// Usage:
/// ```dart
/// Column(
///   children: [
///     TodayHeader(),
///     DaySelector(),
///     Expanded(child: DayContent()),
///   ],
/// )
/// ```
///
/// Design Notes:
/// - Per UX spec, supports swipe navigation
/// - Visual completion feedback for gamification
/// - Today is always visible and highlighted
/// - Smooth animations on selection change
class DaySelector extends ConsumerWidget {
  /// Creates a [DaySelector] widget.
  const DaySelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch current plan to get week dates
    final planAsync = ref.watch(currentPlanProvider);

    // Watch selected date
    final selectedDate = ref.watch(selectedDateProvider);

    return planAsync.when(
      data: (plan) {
        if (plan == null) {
          // No plan - show empty state
          return const SizedBox.shrink();
        }

        // Get all 7 days from the plan
        final days = [
          plan.monday,
          plan.tuesday,
          plan.wednesday,
          plan.thursday,
          plan.friday,
          plan.saturday,
          plan.sunday,
        ];

        return Container(
          height: 95,
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: context.colorScheme.outlineVariant.withValues(
                  alpha: 0.3,
                ),
                width: 1,
              ),
            ),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacingSm,
              vertical: AppSizes.spacingSm,
            ),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final dayPlan = days[index];
              return _DayButton(
                dayPlan: dayPlan,
                isSelected: dayPlan.date.isSameDay(selectedDate),
                isToday: dayPlan.isToday,
                onTap: () {
                  // Update selected date
                  ref.read(selectedDateProvider.notifier).setDate(dayPlan.date);
                },
              );
            },
          ),
        );
      },
      loading: () => Container(
        height: 95,
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: context.colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        child: const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Individual day button within the day selector.
///
/// Displays:
/// - Day of week abbreviation (Mon, Tue, etc.)
/// - Day number (15, 16, etc.)
/// - Completion checkmark if day is complete
/// - Today indicator
/// - Selection state
class _DayButton extends ConsumerWidget {
  /// The day plan to display.
  final dynamic dayPlan;

  /// Whether this day is currently selected.
  final bool isSelected;

  /// Whether this day is today.
  final bool isToday;

  /// Callback when day is tapped.
  final VoidCallback onTap;

  const _DayButton({
    required this.dayPlan,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch completion status for this day
    final completionAsync = ref.watch(dailyCompletionProvider);

    // Determine if this day is complete
    final isComplete = completionAsync.maybeWhen(
      data: (completion) {
        // Check if this is the day we're looking at
        if (!completion.date.isSameDay(dayPlan.date)) return false;

        // Check completion percentage
        final totalMeals = dayPlan.meals.length;
        final totalExercises = dayPlan.workout?.exercises.length ?? 0;
        return completion.isComplete(
          totalMeals: totalMeals,
          totalExercises: totalExercises,
        );
      },
      orElse: () => false,
    );

    // Determine colors based on state
    final backgroundColor = _getBackgroundColor(context, isComplete);
    final textColor = _getTextColor(context, isComplete);
    final borderColor = _getBorderColor(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingXs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 64,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: isSelected
                ? Border.all(color: borderColor, width: 2)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Day of week abbreviation
              Text(
                dayPlan.shortDayName,
                style: context.textTheme.labelSmall?.copyWith(
                  color: textColor.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: AppSizes.spacingXs),

              // Day number with optional today indicator
              Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle for today
                  if (isToday && !isSelected)
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.colorScheme.primaryContainer,
                      ),
                    ),

                  // Day number
                  Text(
                    '${dayPlan.date.day}',
                    style: context.textTheme.titleMedium?.copyWith(
                      color: textColor,
                      fontWeight: isSelected || isToday
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.spacing2xs),

              // Completion indicator
              SizedBox(
                height: 16,
                child: isComplete
                    ? Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: context.colorScheme.onPrimary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.check_circle,
                          size: 16,
                          color: context.colorScheme.tertiary,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Gets background color based on state.
  Color _getBackgroundColor(BuildContext context, bool isComplete) {
    if (isSelected) {
      return context.colorScheme.primary;
    }
    if (isComplete) {
      return context.colorScheme.tertiaryContainer;
    }
    return context.colorScheme.surfaceContainer;
  }

  /// Gets text color based on state.
  Color _getTextColor(BuildContext context, bool isComplete) {
    if (isSelected) {
      return context.colorScheme.onPrimary;
    }
    if (isComplete) {
      return context.colorScheme.onTertiaryContainer;
    }
    return context.colorScheme.onSurface;
  }

  /// Gets border color for selected state.
  Color _getBorderColor(BuildContext context) {
    return context.colorScheme.primary;
  }
}
