import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fitgenie_app/features/plan_generation/domain/day_plan.dart';

import '../../../core/utils/formatters.dart';

part 'weekly_plan.freezed.dart';
part 'weekly_plan.g.dart';

/// Represents a complete 7-day fitness and nutrition plan.
///
/// This is the root model for the entire plan generation feature. It contains
/// all 7 days of workouts and meals, generation metadata, and a snapshot of
/// the user's profile at generation time for historical reference.
///
/// Key Features:
/// - Immutable data structure via Freezed
/// - JSON serialization for Gemini API parsing and Firestore storage
/// - Hive TypeAdapter support for offline local caching
/// - Contains exactly 7 days (Monday-Sunday)
/// - Tracks generation timestamp and user snapshot
/// - Provides date-based day lookup helpers
/// - Calculates weekly progress metrics
///
/// Data Flow:
/// 1. User completes onboarding → UserProfile created
/// 2. Profile sent to Gemini AI → WeeklyPlan generated
/// 3. WeeklyPlan cached in Hive (offline access)
/// 4. WeeklyPlan synced to Firestore (cross-device)
/// 5. Dashboard displays today's DayPlan from WeeklyPlan
///
/// Example:
/// ```dart
/// final weeklyPlan = WeeklyPlan(
///   id: 'plan_123',
///   userId: 'user_456',
///   createdAt: DateTime.now(),
///   startDate: DateTime(2026, 1, 20), // Monday
///   days: [
///     DayPlan(dayIndex: 0, date: DateTime(2026, 1, 20), ...),
///     DayPlan(dayIndex: 1, date: DateTime(2026, 1, 21), ...),
///     // ... 7 days total
///   ],
///   profileSnapshot: userProfile.toJson(),
/// );
///
/// // Get today's plan
/// final today = weeklyPlan.getDayForDate(DateTime.now());
///
/// // Check weekly progress
/// print('Weekly completion: ${weeklyPlan.weeklyCompletionPercentage}%');
///
/// // Parse from Gemini JSON response
/// final fromJson = WeeklyPlan.fromJson(jsonData);
/// ```
///
/// Storage:
/// - Firestore: `/users/{userId}/plans/{planId}`
/// - Hive: `weeklyPlanBox` with key `plan_{userId}`
///
/// Generated files:
/// - `weekly_plan.freezed.dart` - Freezed generated code
/// - `weekly_plan.g.dart` - JSON serialization code
///
/// Run `flutter pub run build_runner build` to generate after changes.
@freezed
class WeeklyPlan with _$WeeklyPlan {
  /// Private constructor for adding custom methods.
  const WeeklyPlan._();

  /// Creates a WeeklyPlan with the specified properties.
  ///
  /// All fields are required. The [days] list must contain exactly 7 DayPlan
  /// objects, one for each day of the week (Monday-Sunday).
  ///
  /// Parameters:
  /// - [id]: Unique identifier for the plan
  /// - [userId]: ID of the user this plan belongs to
  /// - [createdAt]: Timestamp when the plan was generated
  /// - [startDate]: Monday date when the plan week begins
  /// - [days]: List of 7 day plans (Monday-Sunday)
  /// - [profileSnapshot]: User profile data at generation time
  const factory WeeklyPlan({
    /// Unique identifier for the weekly plan.
    ///
    /// Generated during plan creation. Used as document ID in Firestore
    /// and as part of the Hive storage key.
    ///
    /// Format: UUID v4 or timestamp-based unique ID.
    required String id,

    /// ID of the user this plan belongs to.
    ///
    /// Used for:
    /// - Firestore path scoping: `/users/{userId}/plans/{planId}`
    /// - Hive storage key: `plan_{userId}`
    /// - Access control and data isolation
    required String userId,

    /// Timestamp when this plan was generated.
    ///
    /// Stored as ISO 8601 string in JSON/Firestore.
    /// Used for:
    /// - Plan history tracking
    /// - Determining active/archived status
    /// - Sorting multiple plans
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
    required DateTime createdAt,

    /// Start date of the plan week (always a Monday).
    ///
    /// The plan spans 7 days from this date (Monday-Sunday).
    /// Used for:
    /// - Calculating which day to show based on current date
    /// - Weekly navigation in UI
    /// - Plan expiration logic
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
    required DateTime startDate,

    /// List of 7 day plans, one for each day of the week.
    ///
    /// MUST contain exactly 7 days in order:
    /// - Index 0: Monday
    /// - Index 1: Tuesday
    /// - Index 2: Wednesday
    /// - Index 3: Thursday
    /// - Index 4: Friday
    /// - Index 5: Saturday
    /// - Index 6: Sunday
    ///
    /// Each DayPlan contains a workout and meals for that day.
    required List<DayPlan> days,

    /// Snapshot of user profile at the time of plan generation.
    ///
    /// Stores the complete UserProfile as JSON for historical reference.
    /// Useful for:
    /// - Understanding why certain exercises/meals were included
    /// - Comparing profile changes between plan generations
    /// - Audit trail for plan customization
    ///
    /// Contains: age, weight, height, goal, equipment, dietary restrictions, etc.
    required Map<String, dynamic> profileSnapshot,
  }) = _WeeklyPlan;

  /// Creates a WeeklyPlan from a JSON map.
  ///
  /// Used for deserializing from:
  /// - Gemini AI API responses
  /// - Firestore documents
  /// - Local Hive storage
  ///
  /// Example:
  /// ```dart
  /// final json = {
  ///   'id': 'plan_123',
  ///   'userId': 'user_456',
  ///   'createdAt': '2026-01-20T10:00:00.000Z',
  ///   'startDate': '2026-01-20T00:00:00.000Z',
  ///   'days': [
  ///     {'dayIndex': 0, 'date': '2026-01-20T00:00:00.000Z', ...},
  ///     // ... 7 days
  ///   ],
  ///   'profileSnapshot': {'age': 28, 'goal': 'muscle_gain', ...},
  /// };
  /// final plan = WeeklyPlan.fromJson(json);
  /// ```
  factory WeeklyPlan.fromJson(Map<String, dynamic> json) =>
      _$WeeklyPlanFromJson(json);

  /// Converts the plan to a Firestore-compatible map.
  ///
  /// Used for saving to Firestore. Handles nested object serialization.
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'startDate': startDate.toIso8601String(),
      'days': days.map((day) => day.toJson()).toList(),
      'profileSnapshot': profileSnapshot,
    };
  }

  /// Creates a WeeklyPlan from a Firestore document.
  ///
  /// Handles Firestore Timestamp conversion to DateTime.
  factory WeeklyPlan.fromFirestore(Map<String, dynamic> data) {
    return WeeklyPlan.fromJson(data);
  }

  /// Gets the DayPlan for a specific date.
  ///
  /// Returns the DayPlan that matches the given date, or null if the date
  /// is outside the plan's week range.
  ///
  /// Example:
  /// ```dart
  /// final today = weeklyPlan.getDayForDate(DateTime.now());
  /// if (today != null) {
  ///   print('Today is ${today.dayName}');
  /// }
  /// ```
  DayPlan? getDayForDate(DateTime date) {
    // Normalize dates to midnight for comparison
    final targetDate = DateTime(date.year, date.month, date.day);

    for (final day in days) {
      final dayDate = DateTime(day.date.year, day.date.month, day.date.day);
      if (dayDate.isAtSameMomentAs(targetDate)) {
        return day;
      }
    }

    return null;
  }

  /// Gets the DayPlan for today.
  ///
  /// Convenience method that calls [getDayForDate] with the current date.
  DayPlan? get today => getDayForDate(DateTime.now());

  /// Gets the DayPlan by day index (0-6).
  ///
  /// Returns the DayPlan at the specified index, or null if index is invalid.
  /// - 0: Monday, 1: Tuesday, 2: Wednesday, 3: Thursday,
  /// - 4: Friday, 5: Saturday, 6: Sunday
  DayPlan? getDayByIndex(int index) {
    if (index < 0 || index >= days.length) {
      return null;
    }
    return days[index];
  }

  /// Monday's plan.
  DayPlan get monday => days[0];

  /// Tuesday's plan.
  DayPlan get tuesday => days[1];

  /// Wednesday's plan.
  DayPlan get wednesday => days[2];

  /// Thursday's plan.
  DayPlan get thursday => days[3];

  /// Friday's plan.
  DayPlan get friday => days[4];

  /// Saturday's plan.
  DayPlan get saturday => days[5];

  /// Sunday's plan.
  DayPlan get sunday => days[6];

  /// Whether the plan contains the current date.
  ///
  /// Returns true if today falls within the plan's week range.
  bool get isCurrentWeek {
    final now = DateTime.now();
    return getDayForDate(now) != null;
  }

  /// Whether the plan is for a past week.
  bool get isPastWeek {
    final now = DateTime.now();
    final endDate = startDate.add(const Duration(days: 6));
    return endDate.isBefore(now);
  }

  /// Whether the plan is for a future week.
  bool get isFutureWeek {
    final now = DateTime.now();
    return startDate.isAfter(now);
  }

  /// End date of the plan week (Sunday).
  DateTime get endDate => startDate.add(const Duration(days: 6));

  /// Total number of tasks across all 7 days.
  int get totalTasks => days.fold(0, (sum, day) => sum + day.totalTasks);

  /// Total number of completed tasks across all 7 days.
  int get completedTasks =>
      days.fold(0, (sum, day) => sum + day.completedTasks);

  /// Weekly completion percentage (0-100).
  ///
  /// Calculates: (completed tasks / total tasks) * 100
  double get weeklyCompletionPercentage {
    if (totalTasks == 0) {
      return 0.0;
    }
    return (completedTasks / totalTasks) * 100;
  }

  /// Whether all tasks for the week are complete.
  bool get isWeekComplete => totalTasks > 0 && completedTasks == totalTasks;

  /// Number of completed days (all tasks done).
  int get completedDayCount => days.where((day) => day.isComplete).length;

  /// List of rest days in the week.
  List<DayPlan> get restDays => days.where((day) => day.isRestDay).toList();

  /// Number of rest days in the week.
  int get restDayCount => restDays.length;

  /// List of workout days in the week.
  List<DayPlan> get workoutDays => days.where((day) => day.hasWorkout).toList();

  /// Number of workout days in the week.
  int get workoutDayCount => workoutDays.length;

  /// Total weekly calories from all meals across all days.
  int get totalWeeklyCalories =>
      days.fold(0, (sum, day) => sum + day.totalCalories);

  /// Average daily calories.
  int get averageDailyCalories =>
      days.isEmpty ? 0 : (totalWeeklyCalories / days.length).round();

  /// Total weekly protein from all meals across all days (grams).
  int get totalWeeklyProtein =>
      days.fold(0, (sum, day) => sum + day.totalProtein);

  /// Average daily protein (grams).
  int get averageDailyProtein =>
      days.isEmpty ? 0 : (totalWeeklyProtein / days.length).round();

  /// Formatted date range string.
  ///
  /// Example: "Jan 20 - Jan 26, 2026"
  String get dateRangeDisplay {
    final startMonth = _monthName(startDate.month);
    final endMonth = _monthName(endDate.month);

    if (startDate.month == endDate.month) {
      // Same month: "Jan 20-26, 2026"
      return '$startMonth ${startDate.day}-${endDate.day}, ${startDate.year}';
    } else {
      // Different months: "Jan 27 - Feb 2, 2026"
      return '$startMonth ${startDate.day} - $endMonth ${endDate.day}, ${startDate.year}';
    }
  }

  /// Formatted weekly progress string.
  ///
  /// Example: "5/7 days completed"
  String get weeklyProgressDisplay {
    if (isWeekComplete) {
      return 'Week complete!';
    }
    return '${Formatters.completionRatio(completedDayCount, 7)} ${Formatters.count(7, 'day')} completed';
  }

  /// Brief summary of the weekly plan.
  ///
  /// Example: "Week of Jan 20 • 5 workout days • 2 rest days"
  String get summary {
    final startMonth = _monthName(startDate.month);
    return 'Week of $startMonth ${startDate.day} • ${Formatters.count(workoutDayCount, 'workout day')} • ${Formatters.count(restDayCount, 'rest day')}';
  }

  /// Age of the plan in days.
  ///
  /// Number of days since the plan was generated.
  int get ageInDays {
    final now = DateTime.now();
    return now.difference(createdAt).inDays;
  }

  /// Whether the plan is fresh (generated recently).
  ///
  /// Returns true if plan was generated within the last 7 days.
  bool get isFresh => ageInDays <= 7;

  /// Validates that the plan has exactly 7 days.
  ///
  /// Throws [StateError] if validation fails.
  void validate() {
    if (days.length != 7) {
      throw StateError(
        'WeeklyPlan must have exactly 7 days, got ${days.length}',
      );
    }

    // Validate day indices are 0-6
    for (int i = 0; i < days.length; i++) {
      if (days[i].dayIndex != i) {
        throw StateError(
          'Day at index $i has incorrect dayIndex ${days[i].dayIndex}',
        );
      }
    }
  }
}

/// Custom JSON serialization for DateTime.
DateTime _dateTimeFromJson(String json) => DateTime.parse(json);

/// Custom JSON deserialization for DateTime.
String _dateTimeToJson(DateTime date) => date.toIso8601String();

/// Helper function to get month name.
String _monthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return month >= 1 && month <= 12 ? months[month - 1] : 'Unknown';
}
