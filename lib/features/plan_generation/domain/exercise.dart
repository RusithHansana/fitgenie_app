import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/formatters.dart';

part 'exercise.freezed.dart';
part 'exercise.g.dart';

/// Represents a single exercise within a workout session.
///
/// This model stores all information needed to perform an exercise including
/// sets, reps, rest periods, form notes, and required equipment. Each exercise
/// tracks its completion status for daily progress tracking.
///
/// The model is designed to be parsed from Gemini AI responses, which generate
/// exercises based on the user's available equipment, fitness level, and goals.
///
/// Key Features:
/// - Immutable data structure via Freezed
/// - JSON serialization for Gemini API parsing and Firestore storage
/// - Flexible rep specification (ranges like "10-12", durations like "30 seconds")
/// - Equipment tracking to ensure exercises match user's available gear
/// - Completion tracking for daily task management
///
/// Example:
/// ```dart
/// final exercise = Exercise(
///   id: 'ex_123',
///   name: 'Dumbbell Bench Press',
///   sets: 3,
///   reps: '10-12',
///   restSeconds: 90,
///   notes: 'Keep elbows at 45 degrees',
///   equipmentRequired: ['dumbbells', 'bench'],
///   isComplete: false,
/// );
///
/// // Mark as complete
/// final completed = exercise.copyWith(isComplete: true);
///
/// // Parse from Gemini JSON response
/// final fromJson = Exercise.fromJson(jsonData);
/// ```
///
/// Generated files:
/// - `exercise.freezed.dart` - Freezed generated code
/// - `exercise.g.dart` - JSON serialization code
///
/// Run `flutter pub run build_runner build` to generate after changes.
@freezed
class Exercise with _$Exercise {
  /// Private constructor for adding custom methods.
  const Exercise._();

  /// Creates an Exercise with the specified properties.
  ///
  /// All fields except [notes] and [isComplete] are required.
  /// The [isComplete] field defaults to false for new exercises.
  ///
  /// Parameters:
  /// - [id]: Unique identifier for the exercise (e.g., "ex_123")
  /// - [name]: Display name of the exercise (e.g., "Push-ups", "Squats")
  /// - [sets]: Number of sets to perform (e.g., 3, 4)
  /// - [reps]: Rep specification - can be a range ("10-12"), fixed number ("15"),
  ///   or duration ("30 seconds", "1 minute")
  /// - [restSeconds]: Rest time between sets in seconds (e.g., 60, 90)
  /// - [notes]: Optional form cues, technique tips, or modifications
  /// - [equipmentRequired]: List of equipment needed (e.g., ['dumbbells', 'bench'])
  /// - [isComplete]: Whether the user has completed this exercise
  const factory Exercise({
    /// Unique identifier for the exercise.
    ///
    /// Generated during plan creation, persists across modifications.
    required String id,

    /// Display name of the exercise.
    ///
    /// Examples: "Push-ups", "Dumbbell Bench Press", "Squats"
    required String name,

    /// Number of sets to perform.
    ///
    /// Typically 3-5 for strength training, 1-3 for cardio intervals.
    required int sets,

    /// Rep specification for each set.
    ///
    /// Formats supported:
    /// - Fixed count: "10", "15", "20"
    /// - Range: "8-10", "10-12", "12-15"
    /// - Duration: "30 seconds", "1 minute", "45 seconds"
    /// - To failure: "To failure", "AMRAP"
    required String reps,

    /// Rest time between sets in seconds.
    ///
    /// Common values:
    /// - 30-45 seconds: Metabolic conditioning, circuits
    /// - 60-90 seconds: Hypertrophy training
    /// - 2-5 minutes: Strength/power training
    required int restSeconds,

    /// Optional exercise notes for form cues and technique tips.
    ///
    /// Examples:
    /// - "Keep core tight and lower back flat"
    /// - "Control the eccentric (lowering) phase"
    /// - "Modification: Perform on knees if needed"
    String? notes,

    /// List of equipment required to perform this exercise.
    ///
    /// Must use lowercase names matching user's [UserProfile.equipmentDetails].
    /// Examples: ['dumbbells'], ['barbell', 'bench'], ['pull-up bar']
    ///
    /// For bodyweight exercises, use empty list or ['bodyweight'].
    @Default([]) List<String> equipmentRequired,

    /// Whether the user has completed this exercise in today's workout.
    ///
    /// Defaults to false. Set to true when user checks off the exercise.
    /// Used to calculate workout completion percentage.
    @Default(false) bool isComplete,
  }) = _Exercise;

  /// Creates an Exercise from a JSON map.
  ///
  /// Used for deserializing from:
  /// - Gemini AI API responses
  /// - Firestore documents
  /// - Local Hive storage
  ///
  /// Example:
  /// ```dart
  /// final json = {
  ///   'id': 'ex_123',
  ///   'name': 'Push-ups',
  ///   'sets': 3,
  ///   'reps': '15',
  ///   'restSeconds': 60,
  ///   'equipmentRequired': ['bodyweight'],
  ///   'isComplete': false,
  /// };
  /// final exercise = Exercise.fromJson(json);
  /// ```
  factory Exercise.fromJson(Map<String, dynamic> json) =>
      _$ExerciseFromJson(json);

  /// Formatted display string for sets and reps.
  ///
  /// Examples:
  /// - "3 × 10-12 reps"
  /// - "4 × 15 reps"
  /// - "3 × 30 seconds"
  String get setsRepsDisplay => Formatters.exerciseSetsReps(sets, reps);

  /// Formatted display string for rest time.
  ///
  /// Converts seconds to human-readable format.
  /// Examples:
  /// - "30 sec rest"
  /// - "1:30 rest"
  /// - "2:00 rest"
  String get restDisplay => Formatters.exerciseRest(restSeconds);

  /// Whether this is a bodyweight exercise (no equipment required).
  bool get isBodyweight =>
      equipmentRequired.isEmpty ||
      (equipmentRequired.length == 1 &&
          equipmentRequired.first.toLowerCase() == 'bodyweight');

  /// Short description combining name and sets/reps.
  ///
  /// Example: "Push-ups: 3 × 15 reps"
  String get shortDescription => '$name: $setsRepsDisplay';
}
