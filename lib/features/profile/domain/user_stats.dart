import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_stats.freezed.dart';

/// Aggregated user statistics for profile display.
///
/// This model contains all statistical data displayed on the profile screen,
/// including streak information, completion counts, and membership details.
///
/// Data Sources:
/// - Streak data: `/users/{userId}` document fields
/// - Completion counts: Aggregated from `/users/{userId}/completions/*`
/// - Plan counts: Count of `/users/{userId}/plans/*`
///
/// Usage:
/// ```dart
/// final stats = UserStats(
///   currentStreak: 12,
///   longestStreak: 15,
///   totalWorkouts: 45,
///   totalMeals: 135,
///   plansGenerated: 3,
///   memberSince: DateTime(2025, 6, 1),
/// );
///
/// print('Streak: ${stats.currentStreak} days');
/// print('Member for: ${stats.membershipDuration}');
/// ```
///
/// Generated files:
/// - `user_stats.freezed.dart` - Freezed generated code
///
/// Run `flutter pub run build_runner build` to generate after changes.
@freezed
class UserStats with _$UserStats {
  const UserStats._();

  const factory UserStats({
    /// Current consecutive day completion streak.
    ///
    /// Represents the number of consecutive days the user has
    /// completed all daily tasks (workout + meals).
    @Default(0) int currentStreak,

    /// Longest streak ever achieved by the user.
    ///
    /// Personal best for consecutive day completions.
    /// Never decreases, only updated when currentStreak exceeds it.
    @Default(0) int longestStreak,

    /// Total number of workouts completed.
    ///
    /// Aggregated count of all workout tasks marked complete
    /// across all completion documents.
    @Default(0) int totalWorkouts,

    /// Total number of meals completed.
    ///
    /// Aggregated count of all meal tasks (breakfast, lunch, dinner)
    /// marked complete across all completion documents.
    @Default(0) int totalMeals,

    /// Total number of plans generated for this user.
    ///
    /// Count of documents in the plans subcollection.
    @Default(0) int plansGenerated,

    /// Date of most recent activity (task completion).
    ///
    /// Used to determine streak continuity and display
    /// "last active" information.
    DateTime? lastActiveDate,

    /// Date when the user account was created.
    ///
    /// Used to calculate membership duration for display.
    required DateTime memberSince,
  }) = _UserStats;

  /// Creates an empty stats instance for new users.
  ///
  /// All counts default to zero, memberSince defaults to now.
  factory UserStats.empty() => UserStats(memberSince: DateTime.now());

  /// Calculates the membership duration as a human-readable string.
  ///
  /// Examples:
  /// - "1 day"
  /// - "2 weeks"
  /// - "3 months"
  /// - "1 year"
  String get membershipDuration {
    final now = DateTime.now();
    final difference = now.difference(memberSince);

    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return '1 day';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days';
    } else if (difference.inDays < 14) {
      return '1 week';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks weeks';
    } else if (difference.inDays < 60) {
      return '1 month';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months months';
    } else if (difference.inDays < 730) {
      return '1 year';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years years';
    }
  }

  /// Formatted member since date string.
  ///
  /// Format: "June 2025"
  String get memberSinceFormatted {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[memberSince.month - 1]} ${memberSince.year}';
  }

  /// Whether the user has an active streak (≥ 1 day).
  bool get hasActiveStreak => currentStreak > 0;

  /// Whether the current streak matches the longest streak.
  ///
  /// Used to show "Personal Best" indicator.
  bool get isAtPersonalBest =>
      currentStreak > 0 && currentStreak >= longestStreak;

  /// Total tasks completed (workouts + meals).
  int get totalTasksCompleted => totalWorkouts + totalMeals;

  /// Whether the user has any activity recorded.
  bool get hasActivity => totalTasksCompleted > 0 || plansGenerated > 0;
}
