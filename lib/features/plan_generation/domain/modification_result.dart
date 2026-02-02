import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fitgenie_app/features/plan_generation/domain/day_plan.dart';

part 'modification_result.freezed.dart';
part 'modification_result.g.dart';

/// Represents the result of a partial plan modification request.
///
/// This model is used to parse AI responses for plan modifications where
/// only specific days/items are changed rather than regenerating the full plan.
///
/// Key Features:
/// - Supports partial updates (only modified days included)
/// - Includes modification type for merge logic
/// - Provides AI explanation for user feedback
/// - Handles rejection cases for invalid requests
///
/// Usage in Repository:
/// ```dart
/// final result = ModificationResult.fromJson(geminiResponse);
/// if (result.type == ModificationType.rejected) {
///   throw AiException(AiErrorType.invalidRequest, result.explanation);
/// }
/// final mergedPlan = _mergePlanChanges(currentPlan, result);
/// ```
///
/// Architecture Notes:
/// - Only contains days that were actually modified
/// - Repository merges these into existing WeeklyPlan
/// - Firestore receives partial updates via field paths
@freezed
class ModificationResult with _$ModificationResult {
  const ModificationResult._();

  /// Creates a ModificationResult with the specified properties.
  ///
  /// Parameters:
  /// - [type]: The type of modification performed
  /// - [modifiedDays]: List of days that were changed (1-7 items)
  /// - [explanation]: AI's description of changes made
  const factory ModificationResult({
    /// The type of modification performed.
    ///
    /// Determines how the repository should merge changes:
    /// - dayReplacement: Replace entire day(s)
    /// - workoutUpdate: Update workout within day(s)
    /// - mealUpdate: Update meal(s) within day(s)
    /// - rejected: Request was invalid, no changes made
    required ModificationType type,

    /// List of modified day plans.
    ///
    /// Contains ONLY the days that were changed, not the full week.
    /// For rejected modifications, this will be empty.
    /// Each day includes complete DayPlan with all fields.
    @Default([]) List<DayPlan> modifiedDays,

    /// AI's explanation of the changes made.
    ///
    /// Provides user-friendly description of what was modified.
    /// For rejected requests, explains why the request was denied.
    required String explanation,
  }) = _ModificationResult;

  /// Creates a ModificationResult from a JSON map.
  ///
  /// Used for deserializing Gemini AI responses.
  ///
  /// Expected JSON structure:
  /// ```json
  /// {
  ///   "modificationType": "dayReplacement",
  ///   "modifiedDays": [
  ///     { "dayIndex": 0, "date": "...", "workout": {...}, "meals": [...] }
  ///   ],
  ///   "explanation": "Changed Monday's lunch to vegetarian"
  /// }
  /// ```
  factory ModificationResult.fromJson(Map<String, dynamic> json) =>
      _$ModificationResultFromJson(json);

  /// Whether the modification request was rejected.
  bool get isRejected => type == ModificationType.rejected;

  /// Number of days that were modified.
  int get modifiedDayCount => modifiedDays.length;

  /// List of day indices that were modified (0-6).
  List<int> get modifiedDayIndices =>
      modifiedDays.map((day) => day.dayIndex).toList();
}

/// Types of plan modifications supported.
///
/// Used to determine merge strategy and Firestore update paths.
enum ModificationType {
  /// Entire day(s) replaced with new content.
  ///
  /// All workout and meal data for the day is overwritten.
  @JsonValue('dayReplacement')
  dayReplacement,

  /// Workout updated within specific day(s).
  ///
  /// Only the workout portion changes, meals remain intact.
  @JsonValue('workoutUpdate')
  workoutUpdate,

  /// Meal(s) updated within specific day(s).
  ///
  /// Only specific meals change, workout and other meals remain intact.
  @JsonValue('mealUpdate')
  mealUpdate,

  /// Modification request was rejected.
  ///
  /// The user attempted an unsupported modification (e.g., full plan change).
  /// No changes are made to the plan.
  @JsonValue('rejected')
  rejected,
}

/// Extension methods for ModificationType.
extension ModificationTypeExtension on ModificationType {
  /// Display name for the modification type.
  String get displayName {
    switch (this) {
      case ModificationType.dayReplacement:
        return 'Day Replacement';
      case ModificationType.workoutUpdate:
        return 'Workout Update';
      case ModificationType.mealUpdate:
        return 'Meal Update';
      case ModificationType.rejected:
        return 'Rejected';
    }
  }

  /// Whether this modification type affects the entire day.
  bool get replacesFullDay => this == ModificationType.dayReplacement;
}
