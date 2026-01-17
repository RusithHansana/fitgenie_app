import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_completion.freezed.dart';
part 'daily_completion.g.dart';

/// Represents task completion status for a single day.
///
/// This model tracks which meals and exercises have been completed on a
/// specific date, enabling progress tracking and streak calculation. It stores
/// completion data as lists of IDs that correspond to meal and exercise IDs
/// from the user's active plan.
///
/// Key Features:
/// - Immutable data structure via Freezed
/// - JSON serialization for Firestore storage
/// - Computed completion status and percentage
/// - Date-based identification using ISO 8601 date-only format
/// - Offline-first persistence via Hive and Firestore
///
/// Data Flow:
/// 1. User completes task (meal or exercise) in UI
/// 2. CompletionRepository updates DailyCompletion
/// 3. Changes saved to local Hive cache immediately
/// 4. Queued for Firestore sync when online
/// 5. Streak calculation triggered on full day completion
///
/// Firestore Storage:
/// - Collection path: `/users/{userId}/completions/{date}`
/// - Document ID: ISO 8601 date string (e.g., "2026-01-17")
/// - Fields: date, completedMealIds, completedExerciseIds
///
/// Example:
/// ```dart
/// final completion = DailyCompletion(
///   date: DateTime(2026, 1, 17),
///   completedMealIds: ['meal_breakfast_123', 'meal_lunch_456'],
///   completedExerciseIds: ['ex_pushups_789', 'ex_squats_012'],
/// );
///
/// // Check workout completion
/// if (completion.workoutComplete) {
///   print('Workout done!');
/// }
///
/// // Get completion percentage
/// print('Progress: ${completion.completionPercentage.toStringAsFixed(0)}%');
///
/// // Mark meal complete
/// final updated = completion.copyWith(
///   completedMealIds: [...completion.completedMealIds, 'meal_dinner_789'],
/// );
///
/// // Parse from Firestore
/// final fromJson = DailyCompletion.fromJson(firestoreDoc.data()!);
/// ```
///
/// Generated files:
/// - `daily_completion.freezed.dart` - Freezed generated code
/// - `daily_completion.g.dart` - JSON serialization code
///
/// Run `flutter pub run build_runner build` to generate after changes.
@freezed
class DailyCompletion with _$DailyCompletion {
  /// Private constructor for adding custom methods.
  const DailyCompletion._();

  /// Creates a DailyCompletion with the specified properties.
  ///
  /// All fields are required. Empty lists indicate no completions.
  ///
  /// Parameters:
  /// - [date]: The date this completion data is for (time component ignored)
  /// - [completedMealIds]: List of meal IDs that have been completed
  /// - [completedExerciseIds]: List of exercise IDs that have been completed
  const factory DailyCompletion({
    /// The date this completion data is for.
    ///
    /// Only the date portion is significant (year, month, day).
    /// Time component is ignored for comparisons.
    ///
    /// This date is used as the Firestore document ID in ISO 8601 date-only
    /// format (YYYY-MM-DD) via the [toIso8601DateOnly] extension.
    required DateTime date,

    /// List of completed meal IDs for this day.
    ///
    /// Each ID corresponds to a [Meal.id] from the user's active plan.
    /// IDs are stored as strings matching the plan's meal structure.
    ///
    /// Examples:
    /// - ['meal_breakfast_abc123', 'meal_lunch_def456']
    /// - Empty list if no meals completed
    ///
    /// Used to:
    /// - Mark meals as complete in UI
    /// - Calculate meal completion percentage
    /// - Determine if all meals are complete for streak tracking
    @Default([]) List<String> completedMealIds,

    /// List of completed exercise IDs for this day.
    ///
    /// Each ID corresponds to an [Exercise.id] from the user's active plan.
    /// IDs are stored as strings matching the plan's exercise structure.
    ///
    /// Examples:
    /// - ['ex_pushups_xyz789', 'ex_squats_abc012']
    /// - Empty list if no exercises completed
    ///
    /// Used to:
    /// - Mark exercises as complete in UI
    /// - Calculate workout completion percentage
    /// - Determine if workout is complete for streak tracking
    @Default([]) List<String> completedExerciseIds,
  }) = _DailyCompletion;

  /// Creates a DailyCompletion from a JSON map.
  ///
  /// Used for deserializing from:
  /// - Firestore documents
  /// - Local Hive storage
  /// - Sync queue operations
  ///
  /// Example:
  /// ```dart
  /// final json = {
  ///   'date': '2026-01-17T00:00:00.000Z',
  ///   'completedMealIds': ['meal_breakfast_123'],
  ///   'completedExerciseIds': ['ex_pushups_456', 'ex_squats_789'],
  /// };
  /// final completion = DailyCompletion.fromJson(json);
  /// ```
  factory DailyCompletion.fromJson(Map<String, dynamic> json) =>
      _$DailyCompletionFromJson(json);

  /// Creates an empty DailyCompletion for a specific date.
  ///
  /// Useful for initializing completion tracking for a new day.
  ///
  /// Example:
  /// ```dart
  /// final today = DateTime.now();
  /// final completion = DailyCompletion.empty(today);
  /// ```
  factory DailyCompletion.empty(DateTime date) {
    return DailyCompletion(
      date: date,
      completedMealIds: [],
      completedExerciseIds: [],
    );
  }

  /// Whether a specific meal is marked as complete.
  ///
  /// Parameters:
  /// - [mealId]: The meal ID to check
  ///
  /// Returns true if the meal ID is in [completedMealIds].
  bool isMealComplete(String mealId) {
    return completedMealIds.contains(mealId);
  }

  /// Whether a specific exercise is marked as complete.
  ///
  /// Parameters:
  /// - [exerciseId]: The exercise ID to check
  ///
  /// Returns true if the exercise ID is in [completedExerciseIds].
  bool isExerciseComplete(String exerciseId) {
    return completedExerciseIds.contains(exerciseId);
  }

  /// Whether all meals for the day are complete.
  ///
  /// This is a computed property that should be evaluated against the
  /// user's actual plan. The repository layer is responsible for comparing
  /// [completedMealIds] against the plan's meal IDs.
  ///
  /// Returns true if:
  /// - Repository confirms all plan meals are in [completedMealIds]
  /// - Or if the day has no meals in the plan
  ///
  /// Note: This getter assumes meals are complete if the list is non-empty.
  /// Actual validation happens in the repository layer.
  bool get allMealsComplete => completedMealIds.isNotEmpty;

  /// Whether the workout for the day is complete.
  ///
  /// This is a computed property that should be evaluated against the
  /// user's actual plan. The repository layer is responsible for comparing
  /// [completedExerciseIds] against the plan's exercise IDs.
  ///
  /// Returns true if:
  /// - Repository confirms all plan exercises are in [completedExerciseIds]
  /// - Or if the day has no workout (rest day)
  ///
  /// Note: This getter assumes workout is complete if the list is non-empty.
  /// Actual validation happens in the repository layer.
  bool get workoutComplete => completedExerciseIds.isNotEmpty;

  /// Total number of completed tasks (meals + exercises).
  ///
  /// Counts the total number of completed items across both categories.
  int get totalCompletedTasks =>
      completedMealIds.length + completedExerciseIds.length;

  /// Calculates completion percentage for the day.
  ///
  /// This method requires the actual plan data to determine the total
  /// number of tasks. It should be called from the repository or provider
  /// layer where the plan is available.
  ///
  /// Parameters:
  /// - [totalMeals]: Total number of meals in the day's plan
  /// - [totalExercises]: Total number of exercises in the day's plan
  ///
  /// Returns: Percentage complete (0.0 to 100.0)
  ///
  /// Example:
  /// ```dart
  /// final dayPlan = await planRepository.getDayPlan(date);
  /// final completion = await completionRepository.getCompletion(date);
  /// final percentage = completion.completionPercentage(
  ///   totalMeals: dayPlan.meals.length,
  ///   totalExercises: dayPlan.workout?.exercises.length ?? 0,
  /// );
  /// ```
  double completionPercentage({
    required int totalMeals,
    required int totalExercises,
  }) {
    final totalTasks = totalMeals + totalExercises;
    if (totalTasks == 0) {
      return 100.0; // No tasks = complete by default (rest day scenario)
    }

    final completedTasks =
        completedMealIds.length + completedExerciseIds.length;
    return (completedTasks / totalTasks) * 100;
  }

  /// Whether all tasks for the day are complete.
  ///
  /// This method requires the actual plan data to determine completeness.
  ///
  /// Parameters:
  /// - [totalMeals]: Total number of meals in the day's plan
  /// - [totalExercises]: Total number of exercises in the day's plan
  ///
  /// Returns: True if all tasks are complete
  bool isComplete({required int totalMeals, required int totalExercises}) {
    return completionPercentage(
          totalMeals: totalMeals,
          totalExercises: totalExercises,
        ) ==
        100.0;
  }

  /// Toggles a meal's completion status.
  ///
  /// If the meal is already complete, it will be removed from [completedMealIds].
  /// If not complete, it will be added.
  ///
  /// Parameters:
  /// - [mealId]: The meal ID to toggle
  ///
  /// Returns: New DailyCompletion instance with updated meal completions
  DailyCompletion toggleMeal(String mealId) {
    final updatedMealIds = List<String>.from(completedMealIds);

    if (updatedMealIds.contains(mealId)) {
      updatedMealIds.remove(mealId);
    } else {
      updatedMealIds.add(mealId);
    }

    return copyWith(completedMealIds: updatedMealIds);
  }

  /// Toggles an exercise's completion status.
  ///
  /// If the exercise is already complete, it will be removed from [completedExerciseIds].
  /// If not complete, it will be added.
  ///
  /// Parameters:
  /// - [exerciseId]: The exercise ID to toggle
  ///
  /// Returns: New DailyCompletion instance with updated exercise completions
  DailyCompletion toggleExercise(String exerciseId) {
    final updatedExerciseIds = List<String>.from(completedExerciseIds);

    if (updatedExerciseIds.contains(exerciseId)) {
      updatedExerciseIds.remove(exerciseId);
    } else {
      updatedExerciseIds.add(exerciseId);
    }

    return copyWith(completedExerciseIds: updatedExerciseIds);
  }

  /// Marks a meal as complete.
  ///
  /// If already complete, returns the same instance.
  ///
  /// Parameters:
  /// - [mealId]: The meal ID to mark complete
  ///
  /// Returns: New DailyCompletion instance with meal marked complete
  DailyCompletion markMealComplete(String mealId) {
    if (completedMealIds.contains(mealId)) {
      return this;
    }

    final updatedMealIds = [...completedMealIds, mealId];
    return copyWith(completedMealIds: updatedMealIds);
  }

  /// Marks an exercise as complete.
  ///
  /// If already complete, returns the same instance.
  ///
  /// Parameters:
  /// - [exerciseId]: The exercise ID to mark complete
  ///
  /// Returns: New DailyCompletion instance with exercise marked complete
  DailyCompletion markExerciseComplete(String exerciseId) {
    if (completedExerciseIds.contains(exerciseId)) {
      return this;
    }

    final updatedExerciseIds = [...completedExerciseIds, exerciseId];
    return copyWith(completedExerciseIds: updatedExerciseIds);
  }

  /// Marks a meal as incomplete.
  ///
  /// If not currently complete, returns the same instance.
  ///
  /// Parameters:
  /// - [mealId]: The meal ID to mark incomplete
  ///
  /// Returns: New DailyCompletion instance with meal marked incomplete
  DailyCompletion markMealIncomplete(String mealId) {
    if (!completedMealIds.contains(mealId)) {
      return this;
    }

    final updatedMealIds = completedMealIds
        .where((id) => id != mealId)
        .toList();
    return copyWith(completedMealIds: updatedMealIds);
  }

  /// Marks an exercise as incomplete.
  ///
  /// If not currently complete, returns the same instance.
  ///
  /// Parameters:
  /// - [exerciseId]: The exercise ID to mark incomplete
  ///
  /// Returns: New DailyCompletion instance with exercise marked incomplete
  DailyCompletion markExerciseIncomplete(String exerciseId) {
    if (!completedExerciseIds.contains(exerciseId)) {
      return this;
    }

    final updatedExerciseIds = completedExerciseIds
        .where((id) => id != exerciseId)
        .toList();
    return copyWith(completedExerciseIds: updatedExerciseIds);
  }
}
