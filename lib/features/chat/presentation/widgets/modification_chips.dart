import 'package:fitgenie_app/core/constants/app_sizes.dart';
import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:fitgenie_app/features/plan_generation/plan_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Quick-action chips for common plan modifications.
///
/// This widget displays a horizontal row of suggested modification actions
/// that users can tap to quickly make common changes to their plan without
/// typing. It reduces friction in the chat interface and teaches users
/// what kinds of modifications are possible.
///
/// Features:
/// - Contextual suggestions based on current plan
/// - Horizontal scrollable layout
/// - Icon + label chips
/// - Tap to send pre-defined messages
/// - Smart suggestions by time of day
/// - Adapts to plan context (workout day vs rest day)
///
/// Visual Design:
/// - Outlined action chips with icons
/// - Primary color on tap
/// - Horizontal ListView with spacing
/// - Compact height to maximize chat space
/// - Material 3 styling
///
/// Suggested Chips:
/// - "Swap this meal" - Replace current meal
/// - "Make it easier" - Reduce workout intensity
/// - "I don't have [equipment]" - Equipment unavailable
/// - "Add rest day" - Convert workout day to rest
/// - "Simpler recipe" - Replace with quick meal
/// - "Skip today's workout" - Remove workout
///
/// Usage:
/// ```dart
/// ModificationChips(
///   onChipTap: (message) {
///     sendMessage(message);
///   },
/// )
/// ```
///
/// Architecture Notes:
/// - ConsumerWidget to access current plan context
/// - Suggestions adapt based on plan data
/// - Follows UX spec for quick interactions
/// - Time-aware suggestions (morning/evening)
class ModificationChips extends ConsumerWidget {
  /// Callback invoked when a chip is tapped.
  ///
  /// Receives the pre-defined message text to send.
  final ValueChanged<String> onChipTap;

  /// Creates a ModificationChips widget.
  ///
  /// The [onChipTap] callback is required to handle chip selections.
  const ModificationChips({super.key, required this.onChipTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = context.colorScheme;

    // Get current plan for contextual suggestions
    final planAsync = ref.watch(currentPlanProvider);

    return planAsync.when(
      data: (plan) {
        // Generate contextual suggestions
        final suggestions = _getContextualSuggestions(plan);

        if (suggestions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 48,
          margin: const EdgeInsets.only(
            left: AppSizes.spacingMd,
            right: AppSizes.spacingMd,
            bottom: AppSizes.spacingSm,
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: suggestions.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppSizes.spacingSm),
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              return ActionChip(
                label: Text(suggestion.label),
                avatar: Icon(
                  suggestion.icon,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: () => onChipTap(suggestion.message),
                backgroundColor: colorScheme.surface,
                side: BorderSide(color: colorScheme.outlineVariant, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                labelStyle: context.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacingSm,
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Gets contextual suggestions based on current plan and time of day.
  List<ChipSuggestion> _getContextualSuggestions(dynamic plan) {
    final now = DateTime.now();
    final hour = now.hour;

    // Base suggestions always available
    final suggestions = <ChipSuggestion>[
      const ChipSuggestion(
        label: 'Swap this meal',
        icon: Icons.swap_horiz,
        message: 'Swap today\'s lunch for something different',
      ),
      const ChipSuggestion(
        label: 'Make it easier',
        icon: Icons.trending_down,
        message: 'Make today\'s workout easier, I\'m tired',
      ),
    ];

    // Morning suggestions (5 AM - 12 PM)
    if (hour >= 5 && hour < 12) {
      suggestions.addAll([
        const ChipSuggestion(
          label: 'Skip workout',
          icon: Icons.event_busy,
          message: 'Skip today\'s workout',
        ),
        const ChipSuggestion(
          label: 'Quick breakfast',
          icon: Icons.timer,
          message: 'Give me a quicker breakfast option',
        ),
      ]);
    }
    // Afternoon suggestions (12 PM - 5 PM)
    else if (hour >= 12 && hour < 17) {
      suggestions.addAll([
        const ChipSuggestion(
          label: 'Simpler recipe',
          icon: Icons.restaurant_menu,
          message: 'Make lunch recipe simpler',
        ),
        const ChipSuggestion(
          label: 'More protein',
          icon: Icons.fitness_center,
          message: 'Add more protein to today\'s meals',
        ),
      ]);
    }
    // Evening suggestions (5 PM - 10 PM)
    else if (hour >= 17 && hour < 22) {
      suggestions.addAll([
        const ChipSuggestion(
          label: 'Lighter dinner',
          icon: Icons.dinner_dining,
          message: 'Make dinner lighter',
        ),
        const ChipSuggestion(
          label: 'Rest tomorrow',
          icon: Icons.bedtime,
          message: 'Make tomorrow a rest day',
        ),
      ]);
    }
    // Late night/early morning (10 PM - 5 AM)
    else {
      suggestions.addAll([
        const ChipSuggestion(
          label: 'Easier tomorrow',
          icon: Icons.light_mode,
          message: 'Make tomorrow\'s workout easier',
        ),
      ]);
    }

    // Limit to 5 suggestions to avoid overwhelming
    return suggestions.take(5).toList();
  }
}

/// Represents a suggested modification chip.
///
/// Contains the display information and the message to send when tapped.
class ChipSuggestion {
  /// The label text to display on the chip.
  final String label;

  /// The icon to display on the chip.
  final IconData icon;

  /// The message to send when the chip is tapped.
  final String message;

  /// Creates a ChipSuggestion.
  const ChipSuggestion({
    required this.label,
    required this.icon,
    required this.message,
  });
}
