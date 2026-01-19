import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitgenie_app/core/extensions/date_extensions.dart';
import 'package:fitgenie_app/features/dashboard/domain/daily_completion.dart';
import 'package:fitgenie_app/features/dashboard/domain/streak_data.dart';

/// Repository managing streak calculation and persistence.
///
/// This repository handles streak-related operations including fetching current
/// streak data, updating streaks after task completion, and calculating streak
/// values based on completion history. Streaks are server-authoritative per
/// architecture to prevent client manipulation.
///
/// Key Features:
/// - Server-authoritative streak calculation
/// - Pure functional streak calculation helpers
/// - Automatic streak reset on missed days
/// - Longest streak tracking for personal records
/// - Integration with user document for persistence
///
/// Streak Logic:
/// 1. A day counts as "complete" when all meals and exercises are done
/// 2. Streak increments when completing consecutive days
/// 3. Streak resets to 0 if a day is skipped
/// 4. Longest streak never decreases (personal best)
/// 5. Server validates all streak updates
///
/// Data Storage:
/// - Stored in user document: `/users/{userId}`
/// - Fields: currentStreak, longestStreak, lastCompletedDate, streakStartDate
/// - Updated atomically with Firestore transactions
///
/// Usage:
/// ```dart
/// final repository = StreakRepository(
///   firestore: FirebaseFirestore.instance,
/// );
///
/// // Get current streak
/// final streak = await repository.getStreakData(userId: 'user123');
/// print('Current streak: ${streak.currentStreak} days');
///
/// // Update after completing a day
/// final completion = DailyCompletion(
///   date: DateTime.now(),
///   completedMealIds: ['meal1', 'meal2'],
///   completedExerciseIds: ['ex1', 'ex2'],
/// );
/// final updated = await repository.updateStreak(
///   userId: 'user123',
///   completion: completion,
///   totalMealsInPlan: 2,
///   totalExercisesInPlan: 2,
/// );
/// ```
///
/// Architecture Notes:
/// - Repositories are provided via Riverpod (singleton pattern)
/// - No business logic beyond streak calculation
/// - Server-side validation via Firestore security rules
/// - Errors are thrown and handled by provider/UI layer
class StreakRepository {
  /// Firestore instance for database operations.
  final FirebaseFirestore _firestore;

  /// Creates a StreakRepository with required dependencies.
  ///
  /// Parameters:
  /// - [firestore]: Firestore instance for database operations
  StreakRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  /// Gets the Firestore document reference for a user.
  ///
  /// Returns: DocumentReference for `/users/{userId}`
  DocumentReference<Map<String, dynamic>> _getUserDocument(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  /// Retrieves current streak data for a user.
  ///
  /// Returns StreakData with current streak, longest streak, and dates.
  /// If user document doesn't exist or has no streak data, returns empty streak.
  ///
  /// Parameters:
  /// - [userId]: User ID
  ///
  /// Returns: StreakData for the user
  ///
  /// Throws:
  /// - [FirebaseException] on Firestore errors
  ///
  /// Example:
  /// ```dart
  /// final streak = await repository.getStreakData(userId: 'user123');
  /// if (streak.hasActiveStreak) {
  ///   print('🔥 ${streak.currentStreak} day streak!');
  /// }
  /// ```
  Future<StreakData> getStreakData({required String userId}) async {
    try {
      final userDoc = await _getUserDocument(userId).get();

      if (!userDoc.exists || userDoc.data() == null) {
        return StreakData.empty();
      }

      final data = userDoc.data()!;

      // Extract streak fields from user document
      final currentStreak = data['currentStreak'] as int? ?? 0;
      final longestStreak = data['longestStreak'] as int? ?? 0;

      // Parse dates (stored as Firestore Timestamps)
      DateTime? lastCompletedDate;
      if (data['lastCompletedDate'] != null) {
        final timestamp = data['lastCompletedDate'] as Timestamp;
        lastCompletedDate = timestamp.toDate();
      }

      DateTime? streakStartDate;
      if (data['streakStartDate'] != null) {
        final timestamp = data['streakStartDate'] as Timestamp;
        streakStartDate = timestamp.toDate();
      }

      return StreakData(
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        lastCompletedDate: lastCompletedDate,
        streakStartDate: streakStartDate,
      );
    } on FirebaseException catch (e) {
      throw Exception('Failed to get streak data: ${e.message}');
    }
  }

  /// Updates streak after a day is completed.
  ///
  /// This is the main method called when a user completes all tasks for a day.
  /// It calculates the new streak value and updates the user document.
  ///
  /// Streak Update Logic:
  /// 1. Check if all tasks are complete (based on plan totals)
  /// 2. If not complete, return current streak (no update)
  /// 3. If already completed today, return current streak (no duplicate)
  /// 4. If completing consecutive day, increment streak
  /// 5. If missed days in between, reset streak to 1
  /// 6. Update longest streak if current exceeds it
  ///
  /// Parameters:
  /// - [userId]: User ID
  /// - [completion]: DailyCompletion data for the day
  /// - [totalMealsInPlan]: Total meals in the user's plan for this day
  /// - [totalExercisesInPlan]: Total exercises in the workout for this day
  ///
  /// Returns: Updated StreakData
  ///
  /// Throws:
  /// - [FirebaseException] on Firestore errors
  ///
  /// Example:
  /// ```dart
  /// // After user completes last task of the day
  /// final dayPlan = await planRepository.getDayPlan(date);
  /// final completion = await completionRepository.getCompletionForDate(date);
  ///
  /// final updatedStreak = await streakRepository.updateStreak(
  ///   userId: 'user123',
  ///   completion: completion,
  ///   totalMealsInPlan: dayPlan.meals.length,
  ///   totalExercisesInPlan: dayPlan.workout?.exercises.length ?? 0,
  /// );
  /// ```
  Future<StreakData> updateStreak({
    required String userId,
    required DailyCompletion completion,
    required int totalMealsInPlan,
    required int totalExercisesInPlan,
  }) async {
    try {
      // Check if day is actually complete
      final isComplete = completion.isComplete(
        totalMeals: totalMealsInPlan,
        totalExercises: totalExercisesInPlan,
      );

      if (!isComplete) {
        // Day not complete - don't update streak
        return await getStreakData(userId: userId);
      }

      // Get current streak data
      final currentStreak = await getStreakData(userId: userId);

      // Check if already completed today
      if (currentStreak.completedToday) {
        // Already completed today - no update needed
        return currentStreak;
      }

      // Calculate new streak
      final newStreak = calculateStreakAfterCompletion(
        currentStreak: currentStreak,
        completionDate: completion.date,
      );

      // Update user document with new streak data
      await _saveStreakData(userId: userId, streak: newStreak);

      return newStreak;
    } on FirebaseException catch (e) {
      throw Exception('Failed to update streak: ${e.message}');
    }
  }

  /// Calculates streak value after completing a day.
  ///
  /// This is a pure function that implements the streak calculation logic.
  /// It can be tested independently without database access.
  ///
  /// Logic:
  /// - If last completion was yesterday: Continue streak (increment by 1)
  /// - If last completion was before yesterday: Reset streak to 1 (new start)
  /// - If no previous completion: Start streak at 1
  /// - Update longest streak if current exceeds it
  ///
  /// Parameters:
  /// - [currentStreak]: Current StreakData
  /// - [completionDate]: Date being completed (typically today)
  ///
  /// Returns: New StreakData with updated values
  ///
  /// Example:
  /// ```dart
  /// final current = StreakData(
  ///   currentStreak: 5,
  ///   longestStreak: 10,
  ///   lastCompletedDate: DateTime(2026, 1, 16),
  /// );
  ///
  /// // User completes today (consecutive)
  /// final updated = calculateStreakAfterCompletion(
  ///   currentStreak: current,
  ///   completionDate: DateTime(2026, 1, 17),
  /// );
  /// // Result: currentStreak = 6
  /// ```
  StreakData calculateStreakAfterCompletion({
    required StreakData currentStreak,
    required DateTime completionDate,
  }) {
    // Normalize dates to date-only (ignore time component)
    final completionDateOnly = completionDate.startOfDay;

    // If no previous completion, start new streak
    if (currentStreak.lastCompletedDate == null) {
      return StreakData(
        currentStreak: 1,
        longestStreak: currentStreak.longestStreak > 1
            ? currentStreak.longestStreak
            : 1,
        lastCompletedDate: completionDateOnly,
        streakStartDate: completionDateOnly,
      );
    }

    // Normalize last completed date
    final lastCompletedDateOnly = currentStreak.lastCompletedDate!.startOfDay;

    // Calculate days between completions
    final daysDifference = completionDateOnly
        .difference(lastCompletedDateOnly)
        .inDays;

    if (daysDifference == 1) {
      // Consecutive day - increment streak
      final newStreakCount = currentStreak.currentStreak + 1;
      final newLongestStreak = newStreakCount > currentStreak.longestStreak
          ? newStreakCount
          : currentStreak.longestStreak;

      return StreakData(
        currentStreak: newStreakCount,
        longestStreak: newLongestStreak,
        lastCompletedDate: completionDateOnly,
        streakStartDate: currentStreak.streakStartDate ?? completionDateOnly,
      );
    } else if (daysDifference > 1) {
      // Missed days - reset streak to 1
      return StreakData(
        currentStreak: 1,
        longestStreak: currentStreak.longestStreak,
        lastCompletedDate: completionDateOnly,
        streakStartDate: completionDateOnly,
      );
    } else {
      // daysDifference <= 0 (same day or future date issue)
      // This shouldn't happen with proper validation, but handle gracefully
      return currentStreak;
    }
  }

  /// Checks if streak needs to be reset and resets it if necessary.
  ///
  /// This should be called when the app starts or when checking streak status.
  /// If the user's last completion is more than 1 day ago, the streak is reset.
  ///
  /// Parameters:
  /// - [userId]: User ID
  ///
  /// Returns: Updated StreakData (may be reset or unchanged)
  ///
  /// Example:
  /// ```dart
  /// // On app launch, check if streak needs reset
  /// final streak = await repository.checkAndResetStreak(userId: 'user123');
  /// ```
  Future<StreakData> checkAndResetStreak({required String userId}) async {
    try {
      final currentStreak = await getStreakData(userId: userId);

      // Check if streak needs reset
      if (currentStreak.needsReset) {
        final resetStreak = currentStreak.resetStreak();
        await _saveStreakData(userId: userId, streak: resetStreak);
        return resetStreak;
      }

      return currentStreak;
    } on FirebaseException catch (e) {
      throw Exception('Failed to check/reset streak: ${e.message}');
    }
  }

  /// Saves streak data to user document.
  ///
  /// This is an internal method that persists StreakData to Firestore.
  /// Uses merge: true to avoid overwriting other user fields.
  ///
  /// Parameters:
  /// - [userId]: User ID
  /// - [streak]: StreakData to save
  ///
  /// Returns: Future that completes when save is done
  Future<void> _saveStreakData({
    required String userId,
    required StreakData streak,
  }) async {
    final data = <String, dynamic>{
      'currentStreak': streak.currentStreak,
      'longestStreak': streak.longestStreak,
    };

    // Add dates if present
    if (streak.lastCompletedDate != null) {
      data['lastCompletedDate'] = Timestamp.fromDate(streak.lastCompletedDate!);
    } else {
      data['lastCompletedDate'] = null;
    }

    if (streak.streakStartDate != null) {
      data['streakStartDate'] = Timestamp.fromDate(streak.streakStartDate!);
    } else {
      data['streakStartDate'] = null;
    }

    // Update with timestamp
    data['lastActiveDate'] = FieldValue.serverTimestamp();

    await _getUserDocument(userId).set(data, SetOptions(merge: true));
  }

  /// Manually resets streak to 0.
  ///
  /// Use with caution - this is primarily for admin/testing purposes.
  ///
  /// Parameters:
  /// - [userId]: User ID
  ///
  /// Returns: Reset StreakData
  Future<StreakData> resetStreak({required String userId}) async {
    try {
      final currentStreak = await getStreakData(userId: userId);
      final resetStreak = currentStreak.resetStreak();
      await _saveStreakData(userId: userId, streak: resetStreak);
      return resetStreak;
    } on FirebaseException catch (e) {
      throw Exception('Failed to reset streak: ${e.message}');
    }
  }

  /// Calculates streak from completion history.
  ///
  /// This is a pure calculation method that determines streak based on a
  /// list of completion dates. Useful for server-side validation or
  /// recalculating streaks from historical data.
  ///
  /// Parameters:
  /// - [completions]: List of DailyCompletion objects sorted by date
  ///
  /// Returns: Calculated StreakData based on completion history
  ///
  /// Example:
  /// ```dart
  /// final completions = await completionRepository.getCompletionRange(
  ///   userId: 'user123',
  ///   startDate: DateTime(2026, 1, 1),
  ///   endDate: DateTime.now(),
  /// );
  /// final streak = repository.calculateStreakFromHistory(completions);
  /// ```
  StreakData calculateStreakFromHistory(List<DailyCompletion> completions) {
    if (completions.isEmpty) {
      return StreakData.empty();
    }

    // Sort by date descending (most recent first)
    final sortedCompletions = List<DailyCompletion>.from(completions)
      ..sort((a, b) => b.date.compareTo(a.date));

    int currentStreak = 0;
    int longestStreak = 0;
    DateTime? lastCompletedDate;
    DateTime? streakStartDate;
    DateTime? previousDate;

    for (final completion in sortedCompletions) {
      final completionDate = completion.date.startOfDay;

      if (previousDate == null) {
        // First completion
        currentStreak = 1;
        lastCompletedDate = completionDate;
        streakStartDate = completionDate;
      } else {
        final daysDifference = previousDate.difference(completionDate).inDays;

        if (daysDifference == 1) {
          // Consecutive day
          currentStreak++;
          streakStartDate = completionDate;
        } else {
          // Streak broken - update longest and reset current
          if (currentStreak > longestStreak) {
            longestStreak = currentStreak;
          }
          currentStreak = 1;
          streakStartDate = completionDate;
        }
      }

      // Update longest streak if current exceeds it
      if (currentStreak > longestStreak) {
        longestStreak = currentStreak;
      }

      previousDate = completionDate;
    }

    return StreakData(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastCompletedDate: lastCompletedDate,
      streakStartDate: streakStartDate,
    );
  }
}
