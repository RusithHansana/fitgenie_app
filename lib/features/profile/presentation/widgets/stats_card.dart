import 'package:fitgenie_app/core/constants/app_sizes.dart';
import 'package:fitgenie_app/core/constants/app_strings.dart';
import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:fitgenie_app/features/dashboard/presentation/widgets/streak_badge.dart';
import 'package:fitgenie_app/features/dashboard/domain/streak_data.dart';
import 'package:fitgenie_app/features/profile/domain/user_stats.dart';
import 'package:flutter/material.dart';

/// Card displaying user statistics and achievements.
///
/// This widget presents an overview of the user's progress including:
/// - Current streak with animated StreakBadge
/// - Total workouts completed
/// - Total meals logged
/// - Plans generated count
/// - Membership duration
///
/// The card uses a grid layout for balanced presentation of statistics,
/// with the streak badge prominently displayed at the top.
///
/// Layout:
/// ```
/// ┌─────────────────────────────┐
/// │    Your Progress            │
/// │                             │
/// │    [🔥 Streak Badge]        │
/// │                             │
/// │  ┌──────┐  ┌──────┐        │
/// │  │ 45   │  │ 135  │        │
/// │  │Works │  │Meals │        │
/// │  └──────┘  └──────┘        │
/// │                             │
/// │  ┌──────┐  ┌──────┐        │
/// │  │  3   │  │  2   │        │
/// │  │Plans │  │Months│        │
/// │  └──────┘  └──────┘        │
/// └─────────────────────────────┘
/// ```
///
/// Usage:
/// ```dart
/// // In profile screen
/// StatsCard(stats: userStats)
/// ```
class StatsCard extends StatelessWidget {
  /// The user statistics to display.
  final UserStats stats;

  const StatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    // Convert stats to StreakData for badge display
    final streakData = StreakData(
      currentStreak: stats.currentStreak,
      longestStreak: stats.longestStreak,
      lastCompletedDate: stats.lastActiveDate,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title
            Text(
              AppStrings.profileStatsTitle,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: AppSizes.spacingLg),

            // Streak badge - prominent display
            Center(
              child: StreakBadge(
                streak: streakData,
                size: StreakBadgeSize.large,
              ),
            ),

            const SizedBox(height: AppSizes.spacingXs),

            // Longest streak indicator (if different from current)
            if (stats.longestStreak > stats.currentStreak &&
                stats.longestStreak > 0)
              Center(
                child: Text(
                  '${AppStrings.streakLongest}: ${stats.longestStreak} ${AppStrings.streakDays}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

            const SizedBox(height: AppSizes.spacingLg),

            // Statistics grid
            _buildStatsGrid(context),
          ],
        ),
      ),
    );
  }

  /// Builds the grid of statistics.
  Widget _buildStatsGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                context,
                icon: Icons.fitness_center,
                value: stats.totalWorkouts.toString(),
                label: AppStrings.statTotalWorkouts,
              ),
            ),
            const SizedBox(width: AppSizes.spacingMd),
            Expanded(
              child: _buildStatItem(
                context,
                icon: Icons.restaurant,
                value: stats.totalMeals.toString(),
                label: AppStrings.statTotalMeals,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacingMd),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                context,
                icon: Icons.calendar_today,
                value: stats.plansGenerated.toString(),
                label: AppStrings.statPlansGenerated,
              ),
            ),
            const SizedBox(width: AppSizes.spacingMd),
            Expanded(
              child: _buildStatItem(
                context,
                icon: Icons.access_time,
                value: _getMembershipValue(),
                label: 'Member',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds a single statistic item.
  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingMd),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Column(
        children: [
          // Icon
          Icon(icon, size: 24, color: colorScheme.primary),

          const SizedBox(height: AppSizes.spacingXs),

          // Value
          Text(
            value,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
              height: 1.2,
            ),
          ),

          const SizedBox(height: AppSizes.spacing2xs),

          // Label
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Gets the membership duration value for display.
  ///
  /// Formats the duration as a short string:
  /// - "Today" for same-day
  /// - "{N}d" for days
  /// - "{N}w" for weeks
  /// - "{N}mo" for months
  /// - "{N}y" for years
  String _getMembershipValue() {
    final duration = stats.membershipDuration;

    if (duration == 'Today') {
      return 'Today';
    }

    // Extract number and unit from duration string
    if (duration.contains('day')) {
      final days = int.tryParse(duration.split(' ')[0]) ?? 0;
      return '${days}d';
    } else if (duration.contains('week')) {
      final weeks = int.tryParse(duration.split(' ')[0]) ?? 0;
      return '${weeks}w';
    } else if (duration.contains('month')) {
      final months = int.tryParse(duration.split(' ')[0]) ?? 0;
      return '${months}mo';
    } else if (duration.contains('year')) {
      final years = int.tryParse(duration.split(' ')[0]) ?? 0;
      return '${years}y';
    }

    return duration;
  }
}
