import 'package:fitgenie_app/core/constants/app_sizes.dart';
import 'package:fitgenie_app/core/constants/app_strings.dart';
import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:fitgenie_app/features/dashboard/dashboard_providers.dart';
import 'package:fitgenie_app/features/dashboard/presentation/widgets/completion_summary.dart';
import 'package:fitgenie_app/features/dashboard/presentation/widgets/day_selector.dart';
import 'package:fitgenie_app/features/dashboard/presentation/widgets/meal_card.dart';
import 'package:fitgenie_app/features/dashboard/presentation/widgets/today_header.dart';
import 'package:fitgenie_app/features/dashboard/presentation/widgets/workout_card.dart';
import 'package:fitgenie_app/features/plan_generation/plan_providers.dart';
import 'package:fitgenie_app/shared/widgets/error_display.dart';
import 'package:fitgenie_app/shared/widgets/offline_banner.dart';
import 'package:fitgenie_app/shared/widgets/skeleton_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Main dashboard screen showing today's plan with all sections.
///
/// This is the primary user interaction screen in FitGenie, displaying:
/// - TodayHeader with date, greeting, and streak badge
/// - DaySelector for navigating the 7-day plan
/// - OfflineBanner (conditional, when offline)
/// - Today's workout section with WorkoutCard
/// - Today's meals section with MealCard list
/// - CompletionSummary showing progress
/// - FAB for chat access
///
/// Key Features:
/// - Pull-to-refresh for manual sync
/// - Skeleton loading states
/// - Offline mode support
/// - Smooth scrolling experience
/// - Responsive layout
/// - Auto-refresh on data changes
///
/// Architecture:
/// - ConsumerWidget for reactive Riverpod integration
/// - All state from dashboard_providers and plan_providers
/// - Composition of feature-specific widgets
/// - Error handling with user-friendly displays
///
/// Layout Structure:
/// ```
/// ┌─────────────────────────────────────┐
/// │ TodayHeader (date, greeting, streak)│
/// ├─────────────────────────────────────┤
/// │ DaySelector (7-day navigation)      │
/// ├─────────────────────────────────────┤
/// │ OfflineBanner (if offline)          │
/// ├─────────────────────────────────────┤
/// │ ScrollableContent:                  │
/// │   - WorkoutCard                     │
/// │   - MealCard (breakfast)            │
/// │   - MealCard (lunch)                │
/// │   - MealCard (dinner)               │
/// │   - MealCard (snacks if any)        │
/// │   - CompletionSummary               │
/// └─────────────────────────────────────┘
/// [FAB: Chat]
/// ```
///
/// Usage:
/// ```dart
/// // In app router
/// GoRoute(
///   path: '/dashboard',
///   builder: (context, state) => const DashboardScreen(),
/// )
/// ```
///
/// Design Notes:
/// - Per UX spec, this is the "today first" default view
/// - Users should see their plan within 3 seconds
/// - Skeleton loaders maintain layout during loading
/// - Pull-to-refresh follows native platform patterns
/// - All interactions are instant with optimistic updates
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();

    // Check and reset streak on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(checkStreakProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch current plan
    final planAsync = ref.watch(currentPlanProvider);

    // Watch selected date
    final selectedDate = ref.watch(selectedDateProvider);

    // Watch daily completion
    final completionAsync = ref.watch(dailyCompletionProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Column(
          children: [
            // Header with date and streak
            const TodayHeader(),

            // Day selector for 7-day navigation
            const DaySelector(),

            // Offline banner (shown when offline)
            const OfflineBanner(),

            // Main content area
            Expanded(
              child: planAsync.when(
                data: (plan) {
                  if (plan == null) {
                    return _buildNoPlanState(context);
                  }

                  // Get the day plan for selected date
                  final dayPlan = plan.getDayForDate(selectedDate);

                  if (dayPlan == null) {
                    return _buildInvalidDateState(context);
                  }

                  // Build the content with plan data
                  return completionAsync.when(
                    data: (completion) => _buildContent(
                      context,
                      dayPlan: dayPlan,
                      completion: completion,
                    ),
                    loading: () => _buildLoadingSkeleton(context),
                    error: (error, stack) => ErrorDisplay(
                      error: error,
                      onRetry: () => ref.invalidate(dailyCompletionProvider),
                    ),
                  );
                },
                loading: () => _buildLoadingSkeleton(context),
                error: (error, stack) => ErrorDisplay(
                  error: error,
                  onRetry: () => ref.invalidate(currentPlanProvider),
                ),
              ),
            ),
          ],
        ),
      ),

      // Floating action button for chat
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToChat,
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Chat'),
        tooltip: 'Modify plan with AI',
      ),
    );
  }

  /// Builds the main content with day plan and completion data.
  Widget _buildContent(
    BuildContext context, {
    required dynamic dayPlan,
    required dynamic completion,
  }) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSizes.spacingXxl * 2),
      children: [
        const SizedBox(height: AppSizes.spacingMd),

        // Section: Workout
        if (dayPlan.hasWorkout) ...[
          _buildSectionHeader(context, 'Today\'s Workout'),
          WorkoutCard(
            workout: dayPlan.workout!,
            completedExerciseIds: completion.completedExerciseIds,
            onExerciseToggle: _toggleExerciseComplete,
          ),
          const SizedBox(height: AppSizes.spacingLg),
        ],

        // Section: Meals
        _buildSectionHeader(context, 'Today\'s Meals'),

        // Breakfast
        if (dayPlan.breakfast != null)
          MealCard(
            meal: dayPlan.breakfast!,
            isComplete: completion.isMealComplete(dayPlan.breakfast!.id),
            onToggle: () => _toggleMealComplete(dayPlan.breakfast!.id),
          ),

        // Lunch
        if (dayPlan.lunch != null)
          MealCard(
            meal: dayPlan.lunch!,
            isComplete: completion.isMealComplete(dayPlan.lunch!.id),
            onToggle: () => _toggleMealComplete(dayPlan.lunch!.id),
          ),

        // Dinner
        if (dayPlan.dinner != null)
          MealCard(
            meal: dayPlan.dinner!,
            isComplete: completion.isMealComplete(dayPlan.dinner!.id),
            onToggle: () => _toggleMealComplete(dayPlan.dinner!.id),
          ),

        // Snacks
        if (dayPlan.snacks.isNotEmpty) ...[
          const SizedBox(height: AppSizes.spacingSm),
          ...dayPlan.snacks.map(
            (snack) => MealCard(
              meal: snack,
              isComplete: completion.isMealComplete(snack.id),
              onToggle: () => _toggleMealComplete(snack.id),
            ),
          ),
        ],

        const SizedBox(height: AppSizes.spacingLg),

        // Completion summary
        const CompletionSummary(),
      ],
    );
  }

  /// Builds section header text.
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacingMd,
        vertical: AppSizes.spacingSm,
      ),
      child: Text(
        title,
        style: context.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: context.colorScheme.onSurface,
        ),
      ),
    );
  }

  /// Builds loading skeleton state.
  Widget _buildLoadingSkeleton(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.spacingMd),
      children: [
        // Workout skeleton
        const SkeletonLoader(height: 200),
        const SizedBox(height: AppSizes.spacingMd),

        // Meal skeletons
        const SkeletonLoader(height: 150),
        const SizedBox(height: AppSizes.spacingMd),
        const SkeletonLoader(height: 150),
        const SizedBox(height: AppSizes.spacingMd),
        const SkeletonLoader(height: 150),
      ],
    );
  }

  /// Builds no plan state (user hasn't generated a plan yet).
  Widget _buildNoPlanState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty state icon
            Icon(
              Icons.fitness_center_outlined,
              size: 80,
              color: context.colorScheme.primary.withValues(alpha: 0.5),
            ),

            const SizedBox(height: AppSizes.spacingLg),

            // Title
            Text(
              AppStrings.noPlanTitle,
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSizes.spacingMd),

            // Description
            Text(
              AppStrings.noPlanDescription,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSizes.spacingXl),

            // Generate plan button
            FilledButton.icon(
              onPressed: _navigateToOnboarding,
              icon: const Icon(Icons.auto_awesome),
              label: const Text(AppStrings.buttonGeneratePlan),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds invalid date state (selected date not in plan).
  Widget _buildInvalidDateState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 80,
              color: context.colorScheme.primary.withValues(alpha: 0.5),
            ),

            const SizedBox(height: AppSizes.spacingLg),

            Text(
              'Date Not in Plan',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSizes.spacingMd),

            Text(
              'This date is outside your current plan. Select a day within your plan week.',
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSizes.spacingXl),

            FilledButton(
              onPressed: () {
                // Reset to today
                ref.read(selectedDateProvider.notifier).setToday();
              },
              child: const Text('Go to Today'),
            ),
          ],
        ),
      ),
    );
  }

  /// Handles pull-to-refresh action.
  Future<void> _handleRefresh() async {
    // Invalidate providers to trigger refresh
    ref.invalidate(currentPlanProvider);
    ref.invalidate(dailyCompletionProvider);
    ref.invalidate(streakProvider);

    // Wait for providers to complete
    await Future.wait([
      ref.read(currentPlanProvider.future),
      ref.read(dailyCompletionProvider.future),
      ref.read(streakProvider.future),
    ]);
  }

  /// Toggles meal completion status.
  Future<void> _toggleMealComplete(String mealId) async {
    try {
      await ref.read(toggleMealCompleteProvider(mealId).future);
    } catch (e) {
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update meal: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _toggleMealComplete(mealId),
            ),
          ),
        );
      }
    }
  }

  /// Toggles exercise completion status.
  Future<void> _toggleExerciseComplete(String exerciseId) async {
    try {
      await ref.read(toggleExerciseCompleteProvider(exerciseId).future);
    } catch (e) {
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update exercise: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _toggleExerciseComplete(exerciseId),
            ),
          ),
        );
      }
    }
  }

  /// Navigates to chat screen.
  void _navigateToChat() {
    // TODO: Implement navigation to chat screen
    // This will be implemented when routing is fully set up
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Chat feature coming soon!')));
  }

  /// Navigates to onboarding/plan generation.
  void _navigateToOnboarding() {
    // TODO: Implement navigation to onboarding
    // This will be implemented when routing is fully set up
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plan generation coming soon!')),
    );
  }
}
