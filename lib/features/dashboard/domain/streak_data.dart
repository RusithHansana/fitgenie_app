import 'package:fitgenie_app/core/constants/app_strings.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'streak_data.freezed.dart';

/// Represents user streak information for habit tracking and gamification.
///
/// This model tracks the user's consecutive day completion streak, their
/// personal best (longest streak), and relevant dates for streak calculation.
/// Streaks are a core gamification mechanic in FitGenie, encouraging daily
/// engagement and habit formation.
///
/// Key Features:
/// - Immutable data structure via Freezed
/// - No JSON serialization needed (embedded in user document)
/// - Server-authoritative streak calculation
/// - Milestone detection for celebrations
/// - Streak reset logic on missed days
///
/// Streak Rules:
/// 1. A day counts as "complete" when all meals and exercises are done
/// 2. Streak increments by 1 for each consecutive complete day
/// 3. Streak resets to 0 if a day is skipped (not completed)
/// 4. Longest streak tracks the user's personal best
/// 5. Server-side validation prevents client manipulation
///
/// Data Storage:
/// - Stored as fields in the user document: `/users/{userId}`
/// - Fields: currentStreak, longestStreak, lastCompletedDate, streakStartDate
/// - Updated by StreakRepository after each day completion
///
/// Milestone Celebrations:
/// - 7 days: First week celebration
/// - 14 days: Two weeks milestone
/// - 30 days: One month achievement
/// - 50, 100, 365 days: Major milestones
///
/// Example:
/// ```dart
/// // New user with no streak
/// final newStreak = StreakData(
///   currentStreak: 0,
///   longestStreak: 0,
/// );
///
/// // User with active streak
/// final activeStreak = StreakData(
///   currentStreak: 12,
///   longestStreak: 15,
///   lastCompletedDate: DateTime(2026, 1, 16),
///   streakStartDate: DateTime(2026, 1, 5),
/// );
///
/// // Check if milestone
/// if (activeStreak.isMilestone) {
///   print('Celebrate! Reached ${activeStreak.currentStreak} days!');
/// }
///
/// // Update after completing a day
/// final updated = activeStreak.copyWith(
///   currentStreak: 13,
///   lastCompletedDate: DateTime(2026, 1, 17),
/// );
/// ```
///
/// Generated files:
/// - `streak_data.freezed.dart` - Freezed generated code
///
/// Run `flutter pub run build_runner build` to generate after changes.
@freezed
class StreakData with _$StreakData {
  /// Private constructor for adding custom methods.
  const StreakData._();

  /// Creates a StreakData with the specified properties.
  ///
  /// All fields have defaults for new users:
  /// - currentStreak: 0 (no streak yet)
  /// - longestStreak: 0 (no history)
  /// - lastCompletedDate: null (never completed a day)
  /// - streakStartDate: null (no active streak)
  ///
  /// Parameters:
  /// - [currentStreak]: Number of consecutive days completed
  /// - [longestStreak]: Personal best streak ever achieved
  /// - [lastCompletedDate]: Most recent day marked as complete
  /// - [streakStartDate]: When the current streak began
  const factory StreakData({
    /// Current consecutive day completion streak.
    ///
    /// Increments by 1 when a user completes all tasks for the day.
    /// Resets to 0 when a day is skipped without completion.
    ///
    /// Values:
    /// - 0: No active streak or just reset
    /// - 1+: Active streak of N consecutive days
    ///
    /// Server-authoritative: Calculated and validated on backend.
    @Default(0) int currentStreak,

    /// Longest streak ever achieved by the user.
    ///
    /// This is the user's personal best and never decreases.
    /// Used for displaying achievements and motivating users
    /// to beat their previous record.
    ///
    /// Values:
    /// - 0: New user or never had a streak
    /// - 1+: Best consecutive day completion count
    ///
    /// Updated when currentStreak exceeds this value.
    @Default(0) int longestStreak,

    /// Most recent date when the user completed all daily tasks.
    ///
    /// Used to determine if streak should continue or reset.
    /// Null for users who have never completed a full day.
    ///
    /// Streak Logic:
    /// - If today = lastCompletedDate + 1 day: Continue streak
    /// - If today > lastCompletedDate + 1 day: Reset streak to 0
    /// - If today = lastCompletedDate: Already completed today
    DateTime? lastCompletedDate,

    /// Date when the current streak began.
    ///
    /// Marks the first day of the current consecutive completion streak.
    /// Null when currentStreak is 0.
    ///
    /// Used for:
    /// - Calculating streak duration
    /// - Displaying "Streak since [date]"
    /// - Analytics and user engagement metrics
    DateTime? streakStartDate,
  }) = _StreakData;

  /// Creates an empty StreakData for a new user.
  ///
  /// Returns a StreakData with all zeros and null dates.
  ///
  /// Example:
  /// ```dart
  /// final newUser = StreakData.empty();
  /// ```
  factory StreakData.empty() {
    return const StreakData(
      currentStreak: 0,
      longestStreak: 0,
      lastCompletedDate: null,
      streakStartDate: null,
    );
  }

  /// Converts a DateTime to a date-only DateTime (midnight of that day).
  static DateTime _toDateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  /// Whether the user has an active streak (currentStreak > 0).
  ///
  /// Returns true if the user has completed at least one day consecutively.
  bool get hasActiveStreak => currentStreak > 0;

  /// Whether the user has ever had a streak.
  ///
  /// Returns true if longestStreak > 0, meaning they've completed
  /// consecutive days at least once in the past.
  bool get hasStreakHistory => longestStreak > 0;

  /// Whether the current streak is a new personal best.
  ///
  /// Returns true if currentStreak equals or exceeds longestStreak.
  /// Used to trigger "New Record!" celebrations.
  bool get isPersonalBest =>
      currentStreak >= longestStreak && currentStreak > 0;

  /// Milestone streak values that trigger celebrations.
  static const List<int> milestoneValues = [7, 14, 30, 50, 100, 365];

  /// Whether the current streak is at a milestone worth celebrating.
  ///
  /// Milestones:
  /// - 7 days: First week
  /// - 14 days: Two weeks
  /// - 30 days: One month
  /// - 50 days: Extended milestone
  /// - 100 days: Major milestone
  /// - 365 days: One year achievement
  ///
  /// Returns true if currentStreak matches a milestone value.
  bool get isMilestone => milestoneValues.contains(currentStreak);

  /// Gets the milestone number if current streak is at a milestone.
  ///
  /// Returns the milestone value (7, 14, 30, etc.) or null if not at a milestone.
  ///
  /// Example:
  /// ```dart
  /// if (streak.milestone != null) {
  ///   print('Congrats on ${streak.milestone} days!');
  /// }
  /// ```
  int? get milestone => isMilestone ? currentStreak : null;

  /// Number of days since the streak started.
  ///
  /// Returns the duration of the current streak in days.
  /// Returns 0 if no active streak.
  ///
  /// Note: This is typically the same as currentStreak, but calculated
  /// from dates for verification purposes.
  int get daysSinceStart {
    if (streakStartDate == null) return 0;

    final now = DateTime.now();
    final start = _toDateOnly(streakStartDate!);
    final today = _toDateOnly(now);

    return today.difference(start).inDays + 1; // +1 to include start day
  }

  /// Whether the streak needs to be checked for reset.
  ///
  /// Returns true if:
  /// - User has an active streak (currentStreak > 0)
  /// - And lastCompletedDate is not today or yesterday
  ///
  /// Used by StreakRepository to determine if streak should reset.
  bool get needsReset {
    if (!hasActiveStreak) return false;
    if (lastCompletedDate == null) return true;

    final now = DateTime.now();
    final today = _toDateOnly(now);
    final lastCompleted = _toDateOnly(lastCompletedDate!);

    // If last completion was today or yesterday, no reset needed
    final daysDifference = today.difference(lastCompleted).inDays;
    return daysDifference > 1;
  }

  /// Whether the user has already completed today.
  ///
  /// Returns true if lastCompletedDate is today's date.
  bool get completedToday {
    if (lastCompletedDate == null) return false;

    final now = DateTime.now();
    final today = _toDateOnly(now);
    final lastCompleted = _toDateOnly(lastCompletedDate!);

    return lastCompleted == today;
  }

  /// Whether today is the day after the last completion.
  ///
  /// Returns true if the user should continue their streak by completing today.
  /// Used to show messaging like "Keep your streak alive!"
  bool get canContinueToday {
    if (!hasActiveStreak) return false;
    if (lastCompletedDate == null) return false;
    if (completedToday) return false;

    final now = DateTime.now();
    final today = _toDateOnly(now);
    final lastCompleted = _toDateOnly(lastCompletedDate!);

    final daysDifference = today.difference(lastCompleted).inDays;
    return daysDifference == 1;
  }

  /// Display text for the current streak.
  ///
  /// Returns formatted string like:
  /// - "No streak yet" (currentStreak == 0)
  /// - "1 day streak" (currentStreak == 1)
  /// - "5 day streak" (currentStreak > 1)
  String get displayText {
    if (currentStreak == 0) {
      return AppStrings.streakNoStreakYet;
    } else if (currentStreak == 1) {
      return AppStrings.streakOneDayStreak;
    } else {
      return '$currentStreak day streak';
    }
  }

  /// Short display text for compact UI.
  ///
  /// Returns just the number and "days" or "day".
  /// Examples: "5 days", "1 day"
  String get shortDisplayText {
    if (currentStreak == 1) {
      return AppStrings.streakOneDay;
    } else {
      return '$currentStreak days';
    }
  }

  /// Emoji representation of streak status.
  ///
  /// Returns:
  /// - 🔥 for active streaks
  /// - ⭐ for milestone achievements
  /// - 🏆 for personal bests
  /// - 💪 for getting started (no streak yet)
  String get emoji {
    if (isMilestone) return AppStrings.emojiMilestone;
    if (isPersonalBest && currentStreak > 1)
      return AppStrings.emojiPersonalBest;
    if (hasActiveStreak) return AppStrings.emojiStreakActive;
    return AppStrings.emojiNoStreak;
  }

  /// Motivational message based on streak status.
  ///
  /// Returns contextual encouragement:
  /// - New users: "Start your streak today!"
  /// - Active streak: "Keep it going!"
  /// - Milestone: "Amazing achievement!"
  /// - Personal best: "New record!"
  String get motivationalMessage {
    if (isMilestone) {
      return AppStrings.motivationalMilestoneAchieved.replaceAll(
        '{days}',
        currentStreak.toString(),
      );
    }
    if (isPersonalBest && currentStreak > 1) {
      return AppStrings.motivationalPersonalBest;
    }
    if (currentStreak >= 3) {
      return AppStrings.motivationalKeepMomentum;
    }
    if (currentStreak > 0) {
      return AppStrings.motivationalGreatStart;
    }
    return AppStrings.motivationalStartStreak;
  }

  /// Creates updated StreakData after completing a day.
  ///
  /// This is a convenience method for the common update pattern.
  /// The actual streak logic should be implemented in StreakRepository.
  ///
  /// Parameters:
  /// - [completionDate]: The date being completed (typically today)
  ///
  /// Returns: Updated StreakData with incremented streak
  StreakData completeDay(DateTime completionDate) {
    final newStreak = currentStreak + 1;
    final newLongest = newStreak > longestStreak ? newStreak : longestStreak;
    final startDate = streakStartDate ?? completionDate;

    return copyWith(
      currentStreak: newStreak,
      longestStreak: newLongest,
      lastCompletedDate: completionDate,
      streakStartDate: startDate,
    );
  }

  /// Creates StreakData with streak reset to 0.
  ///
  /// Called when a user misses a day and loses their streak.
  /// Preserves longestStreak but resets current streak.
  ///
  /// Returns: Updated StreakData with streak reset
  StreakData resetStreak() {
    return copyWith(currentStreak: 0, streakStartDate: null);
  }
}
