import 'package:fitgenie_app/core/constants/app_sizes.dart';
import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:fitgenie_app/core/extensions/date_extensions.dart';
import 'package:fitgenie_app/core/extensions/string_extensions.dart';
import 'package:fitgenie_app/features/dashboard/dashboard_providers.dart';
import 'package:fitgenie_app/features/auth/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dashboard header showing current date, greeting, and streak badge.
///
/// This widget appears at the top of the dashboard screen and provides:
/// - Formatted date display (e.g., "Monday, January 15")
/// - Time-based personalized greeting (e.g., "Good morning, Alex!")
/// - Streak badge showing current streak
/// - Navigation icon to profile/settings
///
/// Key Features:
/// - Dynamic greeting based on time of day
/// - User's first name in greeting (if available)
/// - Prominent streak display for motivation
/// - Clean, minimal design per UX specification
///
/// Layout:
/// ```
/// ┌─────────────────────────────────────────┐
/// │ Monday, January 15          [Settings]  │
/// │ Good morning, Alex!         🔥 5 days   │
/// └─────────────────────────────────────────┘
/// ```
///
/// Usage:
/// ```dart
/// Scaffold(
///   body: Column(
///     children: [
///       TodayHeader(),
///       // ... rest of dashboard
///     ],
///   ),
/// )
/// ```
///
/// Design Notes:
/// - Per UX spec, this is the first thing users see
/// - Greeting should feel personal and encouraging
/// - Streak badge is prominent for gamification
/// - Today-first principle: Always shows current date
class TodayHeader extends ConsumerWidget {
  /// Creates a [TodayHeader] widget.
  const TodayHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch selected date (typically today)
    final selectedDate = ref.watch(selectedDateProvider);

    // Watch auth state for user name
    final authStateAsync = ref.watch(authStateProvider);

    // Watch streak data
    final streakAsync = ref.watch(streakProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacingMd,
        vertical: AppSizes.spacingLg,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and settings row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Date display
                Text(
                  selectedDate.displayDate,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.onSurface,
                  ),
                ),

                // Settings icon
                IconButton(
                  icon: Icon(
                    Icons.settings_outlined,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    // TODO: Navigate to settings/profile
                    // This will be implemented when routing is set up
                  },
                  tooltip: 'Settings',
                ),
              ],
            ),

            const SizedBox(height: AppSizes.spacingSm),

            // Greeting and streak row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Personalized greeting
                Expanded(
                  child: authStateAsync.when(
                    data: (user) {
                      final userName = user?.email.split('@').first ?? 'there';
                      final greeting = _getGreeting();
                      return Text(
                        '$greeting, ${userName.capitalize}!',
                        style: context.textTheme.bodyLarge?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                    loading: () => Text(
                      _getGreeting(),
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    error: (_, __) => Text(
                      _getGreeting(),
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: AppSizes.spacingMd),

                // Streak badge
                streakAsync.when(
                  data: (streak) => StreakBadge(streak: streak),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Gets time-appropriate greeting based on current hour.
  ///
  /// Returns:
  /// - "Good morning" (5 AM - 11:59 AM)
  /// - "Good afternoon" (12 PM - 4:59 PM)
  /// - "Good evening" (5 PM - 8:59 PM)
  /// - "Good night" (9 PM - 4:59 AM)
  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good evening';
    } else {
      return 'Good night';
    }
  }
}
