import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fitgenie_app/features/plan_generation/domain/workout.dart';
import 'package:fitgenie_app/features/plan_generation/domain/meal.dart';

import '../../../core/utils/formatters.dart';

part 'day_plan.freezed.dart';
part 'day_plan.g.dart';

/// Represents a complete day's fitness and nutrition plan.
///
/// This model combines a daily workout session with meals to create a
/// comprehensive plan for a single day. It tracks completion status for
/// both workout and meals, providing a holistic view of daily progress.
///
/// Key Features:
/// - Immutable data structure via Freezed
/// - JSON serialization for Gemini API parsing and Firestore storage
/// - Combines workout and nutrition in one model
/// - Handles rest days (null workout)
/// - Calculates overall daily completion percentage
/// - Maps to specific days of the week via dayIndex
///
/// Example:
/// ```dart
/// final dayPlan = DayPlan(
///   id: 'day_123',
///   dayIndex: 0, // Monday
///   date: DateTime(2026, 1, 20),
///   workout: Workout(...),
///   meals: [
///     Meal(type: MealType.breakfast, ...),
///     Meal(type: MealType.lunch, ...),
///     Meal(type: MealType.dinner, ...),
///   ],
/// );
///
/// // Check if it's a rest day
/// if (dayPlan.isRestDay) {
///   print('Rest and recovery day');
/// }
///
/// // Get completion status
/// print('Daily progress: ${dayPlan.completionPercentage.toStringAsFixed(0)}%');
///
/// // Parse from Gemini JSON response
/// final fromJson = DayPlan.fromJson(jsonData);
/// ```
///
/// Generated files:
/// - `day_plan.freezed.dart` - Freezed generated code
/// - `day_plan.g.dart` - JSON serialization code
///
/// Run `flutter pub run build_runner build` to generate after changes.
@freezed
class DayPlan with _$DayPlan {
  /// Private constructor for adding custom methods.
  const DayPlan._();

  /// Creates a DayPlan with the specified properties.
  ///
  /// All fields are required except [workout] which can be null for rest days.
  /// The [meals] list defaults to empty but typically contains 3-4 meals.
  ///
  /// Parameters:
  /// - [id]: Unique identifier for the day plan
  /// - [dayIndex]: Day of week index (0=Monday, 6=Sunday)
  /// - [date]: Actual date this plan is for
  /// - [workout]: The workout session (null for rest days)
  /// - [meals]: List of meals for the day
  const factory DayPlan({
    /// Unique identifier for the day plan.
    ///
    /// Generated during plan creation, persists across modifications.
    required String id,

    /// Day of week index (0-6).
    ///
    /// Maps to days of the week:
    /// - 0: Monday
    /// - 1: Tuesday
    /// - 2: Wednesday
    /// - 3: Thursday
    /// - 4: Friday
    /// - 5: Saturday
    /// - 6: Sunday
    ///
    /// Used for weekly calendar display and navigation.
    required int dayIndex,

    /// Actual date this plan is scheduled for.
    ///
    /// Allows the same plan structure to be used across different weeks.
    /// Format: ISO 8601 DateTime (e.g., 2026-01-20T00:00:00.000)
    @JsonKey(fromJson: _dateFromJson, toJson: _dateToJson)
    required DateTime date,

    /// The workout session for this day.
    ///
    /// Can be null for rest days or when no workout is scheduled.
    /// For rest days, workout is either null or has type WorkoutType.rest.
    Workout? workout,

    /// List of meals for the day.
    ///
    /// Typically includes:
    /// - 1 breakfast
    /// - 1 lunch
    /// - 1 dinner
    /// - 0-2 snacks (optional)
    ///
    /// Ordered by meal type for display consistency.
    @Default([]) List<Meal> meals,
  }) = _DayPlan;

  /// Creates a DayPlan from a JSON map.
  ///
  /// Used for deserializing from:
  /// - Gemini AI API responses
  /// - Firestore documents
  /// - Local Hive storage
  ///
  /// Example:
  /// ```dart
  /// final json = {
  ///   'id': 'day_123',
  ///   'dayIndex': 0,
  ///   'date': '2026-01-20T00:00:00.000Z',
  ///   'workout': {...},
  ///   'meals': [
  ///     {'type': 'breakfast', ...},
  ///     {'type': 'lunch', ...},
  ///     {'type': 'dinner', ...},
  ///   ],
  /// };
  /// final dayPlan = DayPlan.fromJson(json);
  /// ```
  factory DayPlan.fromJson(Map<String, dynamic> json) =>
      _$DayPlanFromJson(json);

  /// Whether this is a rest day (no workout scheduled).
  ///
  /// Returns true if:
  /// - Workout is null, OR
  /// - Workout type is WorkoutType.rest
  bool get isRestDay => workout == null || workout?.type == WorkoutType.rest;

  /// Day of week name.
  ///
  /// Maps dayIndex to weekday name:
  /// - 0: Monday, 1: Tuesday, 2: Wednesday, 3: Thursday,
  /// - 4: Friday, 5: Saturday, 6: Sunday
  String get dayName {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return dayIndex >= 0 && dayIndex < 7 ? days[dayIndex] : 'Unknown';
  }

  /// Short day of week name (3 letters).
  ///
  /// Examples: "Mon", "Tue", "Wed"
  String get shortDayName => dayName.substring(0, 3);

  /// Total number of tasks for the day (workout + meals).
  ///
  /// Each exercise counts as a separate task, and each meal counts as one task.
  /// Returns meal count only for rest days.
  int get totalTasks {
    int count = meals.length;
    if (workout != null && !isRestDay) {
      count += workout!.exercises.length;
    }
    return count;
  }

  /// Number of completed tasks (exercises + meals).
  ///
  /// Counts completed exercises and completed meals.
  int get completedTasks {
    int count = meals.where((meal) => meal.isComplete).length;
    if (workout != null && !isRestDay) {
      count += workout!.exercises.where((ex) => ex.isComplete).length;
    }
    return count;
  }

  /// Overall completion percentage for the day (0-100).
  ///
  /// Calculates: (completed tasks / total tasks) * 100
  /// Returns 0 if there are no tasks.
  double get completionPercentage {
    if (totalTasks == 0) {
      return 0.0;
    }
    return (completedTasks / totalTasks) * 100;
  }

  /// Whether all tasks for the day are complete.
  ///
  /// Returns true if all exercises and meals are marked as complete.
  /// Returns true for empty days (no tasks).
  bool get isComplete => totalTasks == 0 || completedTasks == totalTasks;

  /// Number of meals in the plan.
  int get mealCount => meals.length;

  /// Number of completed meals.
  int get completedMealCount => meals.where((meal) => meal.isComplete).length;

  /// Formatted progress string.
  ///
  /// Examples:
  /// - "Complete" (all done)
  /// - "5/8 tasks" (partial)
  /// - "0/6 tasks" (not started)
  String get progressDisplay {
    if (isComplete && totalTasks > 0) {
      return 'Complete';
    }
    return '${Formatters.completionRatio(completedTasks, totalTasks)} ${Formatters.count(totalTasks, 'task')}';
  }

  /// Get meals by type for organized display.
  ///
  /// Returns meals filtered by the specified [MealType].
  List<Meal> getMealsByType(MealType type) {
    return meals.where((meal) => meal.type == type).toList();
  }

  /// Breakfast meal (if exists).
  Meal? get breakfast =>
      meals.where((meal) => meal.type == MealType.breakfast).firstOrNull;

  /// Lunch meal (if exists).
  Meal? get lunch =>
      meals.where((meal) => meal.type == MealType.lunch).firstOrNull;

  /// Dinner meal (if exists).
  Meal? get dinner =>
      meals.where((meal) => meal.type == MealType.dinner).firstOrNull;

  /// All snack meals.
  List<Meal> get snacks =>
      meals.where((meal) => meal.type == MealType.snack).toList();

  /// Total daily calories from all meals.
  int get totalCalories => meals.fold(0, (sum, meal) => sum + meal.calories);

  /// Total daily protein from all meals (grams).
  int get totalProtein => meals.fold(0, (sum, meal) => sum + meal.protein);

  /// Total daily carbs from all meals (grams).
  int get totalCarbs => meals.fold(0, (sum, meal) => sum + meal.carbs);

  /// Total daily fat from all meals (grams).
  int get totalFat => meals.fold(0, (sum, meal) => sum + meal.fat);

  /// Formatted daily nutrition summary.
  ///
  /// Example: "2,200 cal • 150g protein • 220g carbs • 70g fat"
  String get nutritionSummary =>
      '${Formatters.calories(totalCalories)} • ${Formatters.macros(totalProtein, 'protein')} • ${Formatters.macros(totalCarbs, 'carbs')} • ${Formatters.macros(totalFat, 'fat')}';

  /// Short nutrition summary for compact display.
  ///
  /// Example: "2,200 cal | P: 150g | C: 220g | F: 70g"
  String get shortNutritionSummary =>
      '${Formatters.calories(totalCalories)} | P: ${totalProtein}g | C: ${totalCarbs}g | F: ${totalFat}g';

  /// Whether this day has any meals.
  bool get hasMeals => meals.isNotEmpty;

  /// Whether this day has a workout.
  bool get hasWorkout => workout != null && !isRestDay;

  /// Brief summary of the day.
  ///
  /// Examples:
  /// - "Monday • Upper Body • 3 meals"
  /// - "Sunday • Rest Day • 3 meals"
  String get summary {
    final workoutPart = hasWorkout
        ? workout!.name
        : (isRestDay ? 'Rest Day' : 'No workout');
    return '$dayName • $workoutPart • ${Formatters.count(mealCount, 'meal')}';
  }

  /// Whether this day plan is for today.
  ///
  /// Compares the plan's date with the current date.
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Whether this day plan is in the past.
  bool get isPast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final planDate = DateTime(date.year, date.month, date.day);
    return planDate.isBefore(today);
  }

  /// Whether this day plan is in the future.
  bool get isFuture {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final planDate = DateTime(date.year, date.month, date.day);
    return planDate.isAfter(today);
  }
}

/// Custom JSON serialization for DateTime.
///
/// Converts ISO 8601 string to DateTime object.
DateTime _dateFromJson(String json) => DateTime.parse(json);

/// Custom JSON deserialization for DateTime.
///
/// Converts DateTime object to ISO 8601 string.
String _dateToJson(DateTime date) => date.toIso8601String();

/// Extension for nullable list access.
extension _ListExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
