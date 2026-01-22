import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fitgenie_app/core/extensions/date_extensions.dart';
import 'package:fitgenie_app/features/dashboard/data/completion_repository.dart';
import 'package:fitgenie_app/features/dashboard/data/streak_repository.dart';
import 'package:fitgenie_app/features/dashboard/domain/daily_completion.dart';
import 'package:fitgenie_app/features/dashboard/domain/streak_data.dart';
import 'package:fitgenie_app/features/auth/auth_providers.dart';
import 'package:fitgenie_app/features/plan_generation/plan_providers.dart';
import 'package:fitgenie_app/shared/providers/firebase_providers.dart'
    hide currentUserIdProvider;
import 'package:fitgenie_app/shared/providers/logger_provider.dart';
import 'package:fitgenie_app/shared/services/sync_queue.dart';

part 'dashboard_providers.g.dart';

/// Riverpod providers for dashboard state, completions, and actions.
///
/// This file centralizes all dashboard-related providers including:
/// - Repository providers for data access
/// - State providers for selected date
/// - Data providers for completions and streaks
/// - Action providers for user interactions
///
/// Provider Architecture:
/// - Singleton repositories with keepAlive
/// - Auto-dispose data providers for reactive updates
/// - Action providers invalidate data providers on success
///
/// Usage:
/// ```dart
/// // Watch streak in UI
/// final streakAsync = ref.watch(streakProvider);
/// streakAsync.when(
///   data: (streak) => Text('${streak.currentStreak} days'),
///   loading: () => CircularProgressIndicator(),
///   error: (e, st) => ErrorDisplay(error: e),
/// );
///
/// // Toggle meal completion
/// await ref.read(toggleMealCompleteProvider(mealId).future);
/// ```

/// Provider for CompletionRepository singleton.
///
/// Creates and caches the completion repository for task completion operations.
/// Dependencies: Firestore instance and SyncQueue.
@Riverpod(keepAlive: true)
CompletionRepository completionRepository(CompletionRepositoryRef ref) {
  return CompletionRepository(
    firestore: ref.watch(firestoreProvider),
    syncQueue: SyncQueue(),
  );
}

/// Provider for StreakRepository singleton.
///
/// Creates and caches the streak repository for streak calculation operations.
/// Dependencies: Firestore instance.
@Riverpod(keepAlive: true)
StreakRepository streakRepository(StreakRepositoryRef ref) {
  return StreakRepository(firestore: ref.watch(firestoreProvider));
}

/// StateProvider for the currently selected date in the dashboard.
///
/// Defaults to today's date. Used by DaySelector widget to track which
/// day the user is viewing in the 7-day plan.
///
/// When this changes, all date-dependent providers (dailyCompletionProvider)
/// will automatically refetch data for the new date.
///
/// Usage:
/// ```dart
/// // Read current selected date
/// final selectedDate = ref.watch(selectedDateProvider);
///
/// // Change selected date
/// ref.read(selectedDateProvider.notifier).state = DateTime(2026, 1, 20);
/// ```
@riverpod
class SelectedDate extends _$SelectedDate {
  @override
  DateTime build() {
    // Default to today
    return DateTime.now().startOfDay;
  }

  /// Sets the selected date to a specific value.
  void setDate(DateTime date) {
    state = date.startOfDay;
  }

  /// Sets the selected date to today.
  void setToday() {
    state = DateTime.now().startOfDay;
  }

  /// Moves to the next day.
  void nextDay() {
    state = state.addDays(1);
  }

  /// Moves to the previous day.
  void previousDay() {
    state = state.subtractDays(1);
  }
}

/// Provider for daily completion data for the selected date.
///
/// Fetches DailyCompletion from CompletionRepository for the currently
/// selected date. Auto-refreshes when selectedDateProvider changes.
///
/// Returns:
/// - DailyCompletion with task completion data
/// - Empty DailyCompletion if no data exists for the date
///
/// Auto-refreshes when:
/// - Selected date changes
/// - Provider is invalidated after completion toggles
/// - User ID changes
///
/// Usage:
/// ```dart
/// final completionAsync = ref.watch(dailyCompletionProvider);
/// completionAsync.when(
///   data: (completion) {
///     final percentage = completion.completionPercentage(
///       totalMeals: dayPlan.meals.length,
///       totalExercises: dayPlan.workout?.exercises.length ?? 0,
///     );
///     return Text('$percentage% complete');
///   },
///   loading: () => SkeletonLoader(),
///   error: (e, st) => ErrorDisplay(error: e),
/// );
/// ```
@riverpod
Future<DailyCompletion> dailyCompletion(DailyCompletionRef ref) async {
  // Get current user ID
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    throw StateError('User must be authenticated to get completion data');
  }

  // Get selected date
  final selectedDate = ref.watch(selectedDateProvider);

  // Fetch completion from repository
  final repository = ref.watch(completionRepositoryProvider);
  return await repository.getCompletionForDate(
    userId: userId,
    date: selectedDate,
  );
}

/// Provider for user's current streak data.
///
/// Fetches StreakData from StreakRepository for the authenticated user.
/// This is the single source of truth for streak information displayed
/// in the UI (header badge, profile screen, etc.).
///
/// Returns:
/// - StreakData with current streak, longest streak, and dates
/// - Empty StreakData if user has no streak history
///
/// Auto-refreshes when:
/// - Provider is invalidated after streak updates
/// - User ID changes
///
/// Usage:
/// ```dart
/// final streakAsync = ref.watch(streakProvider);
/// streakAsync.when(
///   data: (streak) => StreakBadge(streak: streak),
///   loading: () => SkeletonLoader(),
///   error: (e, st) => ErrorDisplay(error: e),
/// );
/// ```
@riverpod
Future<StreakData> streak(StreakRef ref) async {
  // Get current user ID
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    throw StateError('User must be authenticated to get streak data');
  }

  // Fetch streak from repository
  final repository = ref.watch(streakRepositoryProvider);
  return await repository.getStreakData(userId: userId);
}

/// Provider for toggling meal completion status.
///
/// Action provider that toggles a meal's completion status for the selected date.
/// Invalidates dailyCompletionProvider to trigger UI refresh.
///
/// Parameters:
/// - [mealId]: ID of the meal to toggle
///
/// Returns: Updated DailyCompletion
///
/// Throws:
/// - [StateError] if user not authenticated
/// - [Exception] on repository errors
///
/// Usage:
/// ```dart
/// // In meal card's checkbox onTap
/// await ref.read(toggleMealCompleteProvider(meal.id).future);
/// ```
@riverpod
Future<DailyCompletion> toggleMealComplete(
  ToggleMealCompleteRef ref,
  String mealId,
) async {
  // Get current user ID
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    throw StateError('User must be authenticated to toggle meal completion');
  }

  // Get selected date
  final selectedDate = ref.watch(selectedDateProvider);

  // Toggle meal via repository
  final repository = ref.watch(completionRepositoryProvider);
  final updatedCompletion = await repository.toggleMealComplete(
    userId: userId,
    date: selectedDate,
    mealId: mealId,
  );

  // Invalidate completion provider to trigger refresh
  ref.invalidate(dailyCompletionProvider);

  // Check if day is now complete and update streak if needed
  _checkAndUpdateStreak(ref, updatedCompletion);

  return updatedCompletion;
}

/// Provider for toggling exercise completion status.
///
/// Action provider that toggles an exercise's completion status for the selected date.
/// Invalidates dailyCompletionProvider to trigger UI refresh.
///
/// Parameters:
/// - [exerciseId]: ID of the exercise to toggle
///
/// Returns: Updated DailyCompletion
///
/// Throws:
/// - [StateError] if user not authenticated
/// - [Exception] on repository errors
///
/// Usage:
/// ```dart
/// // In exercise tile's checkbox onTap
/// await ref.read(toggleExerciseCompleteProvider(exercise.id).future);
/// ```
@riverpod
Future<DailyCompletion> toggleExerciseComplete(
  ToggleExerciseCompleteRef ref,
  String exerciseId,
) async {
  // Get current user ID
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    throw StateError(
      'User must be authenticated to toggle exercise completion',
    );
  }

  // Get selected date
  final selectedDate = ref.watch(selectedDateProvider);

  // Toggle exercise via repository
  final repository = ref.watch(completionRepositoryProvider);
  final updatedCompletion = await repository.toggleExerciseComplete(
    userId: userId,
    date: selectedDate,
    exerciseId: exerciseId,
  );

  // Invalidate completion provider to trigger refresh
  ref.invalidate(dailyCompletionProvider);

  // Check if day is now complete and update streak if needed
  _checkAndUpdateStreak(ref, updatedCompletion);

  return updatedCompletion;
}

/// Provider for the completion status of the selected date.
///
/// Derived from dailyCompletionProvider and currentPlanProvider.
/// Calculates whether all tasks are complete for display purposes.
///
/// Returns: Map with completion metrics
///
/// Usage:
/// ```dart
/// final status = ref.watch(completionStatusProvider);
/// status.when(
///   data: (data) => Text('${data['percentage']}% complete'),
///   loading: () => SkeletonLoader(),
///   error: (e, st) => ErrorDisplay(error: e),
/// );
/// ```
@riverpod
Future<Map<String, dynamic>> completionStatus(CompletionStatusRef ref) async {
  // Get completion data
  final completion = await ref.watch(dailyCompletionProvider.future);

  // Get plan data to determine totals
  final plan = await ref.watch(currentPlanProvider.future);
  if (plan == null) {
    return {'percentage': 0.0, 'completed': 0, 'total': 0, 'isComplete': false};
  }

  // Get the day plan for the selected date
  final selectedDate = ref.watch(selectedDateProvider);
  final dayPlan = plan.getDayForDate(selectedDate);

  if (dayPlan == null) {
    return {'percentage': 0.0, 'completed': 0, 'total': 0, 'isComplete': false};
  }

  // Calculate totals
  final totalMeals = dayPlan.meals.length;
  final totalExercises = dayPlan.workout?.exercises.length ?? 0;
  final totalTasks = totalMeals + totalExercises;
  final completedTasks = completion.totalCompletedTasks;
  final percentage = completion.completionPercentage(
    totalMeals: totalMeals,
    totalExercises: totalExercises,
  );
  final isComplete = completion.isComplete(
    totalMeals: totalMeals,
    totalExercises: totalExercises,
  );

  return {
    'percentage': percentage,
    'completed': completedTasks,
    'total': totalTasks,
    'isComplete': isComplete,
    'totalMeals': totalMeals,
    'totalExercises': totalExercises,
  };
}

/// Helper function to check if day is complete and update streak.
///
/// Called after meal/exercise completion toggles. If the day becomes
/// fully complete, triggers streak update via StreakRepository.
///
/// This is an internal helper and should not be called directly from UI.
Future<void> _checkAndUpdateStreak(Ref ref, DailyCompletion completion) async {
  try {
    // Get plan to check totals
    final plan = await ref.read(currentPlanProvider.future);
    if (plan == null) return;

    // Get selected date
    final selectedDate = ref.read(selectedDateProvider);
    final dayPlan = plan.getDayForDate(selectedDate);
    if (dayPlan == null) return;

    // Check if day is complete
    final totalMeals = dayPlan.meals.length;
    final totalExercises = dayPlan.workout?.exercises.length ?? 0;
    final isComplete = completion.isComplete(
      totalMeals: totalMeals,
      totalExercises: totalExercises,
    );

    if (isComplete) {
      // Day is complete - update streak
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

      final streakRepo = ref.read(streakRepositoryProvider);
      await streakRepo.updateStreak(
        userId: userId,
        completion: completion,
        totalMealsInPlan: totalMeals,
        totalExercisesInPlan: totalExercises,
      );

      // Invalidate streak provider to refresh UI
      ref.invalidate(streakProvider);
    }
  } catch (e) {
    // Log error but don't throw - streak update shouldn't block completion
    final logger = ref.read(loggerProvider);
    logger.e('Error updating streak', error: e);
  }
}

/// Provider to check and reset streak on app launch.
///
/// This should be called when the app starts to ensure streak data
/// is accurate (resets if user missed days).
///
/// Returns: Current StreakData (possibly reset)
///
/// Usage:
/// ```dart
/// // In app initialization or dashboard screen initState
/// await ref.read(checkStreakProvider.future);
/// ```
@riverpod
Future<StreakData> checkStreak(CheckStreakRef ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    throw StateError('User must be authenticated to check streak');
  }

  final repository = ref.watch(streakRepositoryProvider);
  final streak = await repository.checkAndResetStreak(userId: userId);

  // Invalidate streak provider to reflect any changes
  ref.invalidate(streakProvider);

  return streak;
}
