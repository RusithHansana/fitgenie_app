import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_state.freezed.dart';
part 'onboarding_state.g.dart';

/// Immutable state class tracking onboarding wizard progress and collected data.
///
/// This class manages the state of the multi-step onboarding flow, including
/// the current step position, total number of steps, and all data collected
/// from the user across the wizard steps.
///
/// The wizard consists of 7 steps (indices 0-6):
/// - 0: Welcome
/// - 1: Age & Weight
/// - 2: Height
/// - 3: Fitness Goal
/// - 4: Equipment
/// - 5: Dietary Restrictions
/// - 6: Review & Generate
///
/// Usage:
/// ```dart
/// // Initial state
/// final state = OnboardingState.initial();
///
/// // Update collected data
/// final updated = state.updateData('age', 25);
///
/// // Navigate to next step
/// final nextState = state.nextStep();
///
/// // Check if ready to complete
/// if (state.isComplete) {
///   // Generate plan
/// }
/// ```
///
/// Generated files:
/// - `onboarding_state.freezed.dart` - Freezed generated code
///
/// Run `flutter pub run build_runner build` to generate after changes.
@freezed
class OnboardingState with _$OnboardingState {
  const OnboardingState._();

  /// Creates an OnboardingState with the specified properties.
  ///
  /// Parameters:
  /// - [currentStep]: The current step index (0-based)
  /// - [totalSteps]: Total number of steps in the wizard
  /// - [collectedData]: Map of all collected form data
  const factory OnboardingState({
    /// Current step index (0-based)
    @Default(0) int currentStep,

    /// Total number of steps in the onboarding wizard
    @Default(7) int totalSteps,

    /// Map storing all collected data from wizard steps
    ///
    /// Keys correspond to field names:
    /// - 'age': int
    /// - 'weight': double
    /// - 'weightUnit': String ('kg' or 'lbs')
    /// - 'height': double
    /// - 'heightUnit': String ('cm' or 'ft-in')
    /// - 'goal': String (FitnessGoal enum value)
    /// - 'equipment': String (EquipmentType enum value)
    /// - 'equipmentDetails': `List<String>`
    /// - 'dietaryRestrictions': `List<String>`
    /// - 'dietaryNotes': String?
    @Default({}) Map<String, dynamic> collectedData,
  }) = _OnboardingState;

  /// Creates the initial state when starting the onboarding wizard.
  ///
  /// Starts at step 0 with empty collected data.
  factory OnboardingState.initial() =>
      const OnboardingState(currentStep: 0, totalSteps: 7, collectedData: {});

  /// Whether the user is on the first step.
  bool get isFirstStep => currentStep == 0;

  /// Whether the user is on the last step.
  bool get isLastStep => currentStep == totalSteps - 1;

  /// Whether the onboarding wizard is complete.
  ///
  /// The wizard is considered complete when:
  /// - User has reached the final step (review step)
  /// - All required data has been collected
  bool get isComplete => isLastStep && hasRequiredData;

  /// Whether all required data has been collected.
  ///
  /// Checks for presence of all mandatory fields:
  /// - age
  /// - weight & weightUnit
  /// - height & heightUnit
  /// - goal
  /// - equipment
  /// - dietaryRestrictions (can be empty list)
  bool get hasRequiredData {
    return collectedData.containsKey('age') &&
        collectedData.containsKey('weight') &&
        collectedData.containsKey('weightUnit') &&
        collectedData.containsKey('height') &&
        collectedData.containsKey('heightUnit') &&
        collectedData.containsKey('goal') &&
        collectedData.containsKey('equipment') &&
        collectedData.containsKey('dietaryRestrictions');
  }

  /// Progress percentage (0.0 to 1.0) based on current step.
  double get progress => (currentStep + 1) / totalSteps;

  /// Updates the collected data with a new key-value pair.
  ///
  /// This creates a new state with the updated data map.
  ///
  /// Example:
  /// ```dart
  /// final newState = state.updateData('age', 25);
  /// ```
  OnboardingState updateData(String key, dynamic value) {
    final updatedData = Map<String, dynamic>.from(collectedData);
    updatedData[key] = value;
    return copyWith(collectedData: updatedData);
  }

  /// Updates multiple fields in the collected data at once.
  ///
  /// This is more efficient than calling [updateData] multiple times.
  ///
  /// Example:
  /// ```dart
  /// final newState = state.updateMultipleData({
  ///   'age': 25,
  ///   'weight': 75.0,
  ///   'weightUnit': 'kg',
  /// });
  /// ```
  OnboardingState updateMultipleData(Map<String, dynamic> data) {
    final updatedData = Map<String, dynamic>.from(collectedData);
    updatedData.addAll(data);
    return copyWith(collectedData: updatedData);
  }

  /// Removes a field from the collected data.
  ///
  /// Useful when user changes a selection that invalidates dependent fields.
  ///
  /// Example:
  /// ```dart
  /// // If user changes equipment type, clear equipment details
  /// final newState = state.removeData('equipmentDetails');
  /// ```
  OnboardingState removeData(String key) {
    final updatedData = Map<String, dynamic>.from(collectedData);
    updatedData.remove(key);
    return copyWith(collectedData: updatedData);
  }

  /// Advances to the next step in the wizard.
  ///
  /// Returns the same state if already at the last step.
  OnboardingState nextStep() {
    if (isLastStep) return this;
    return copyWith(currentStep: currentStep + 1, collectedData: collectedData);
  }

  /// Goes back to the previous step in the wizard.
  ///
  /// Returns the same state if already at the first step.
  OnboardingState previousStep() {
    if (isFirstStep) return this;
    return copyWith(currentStep: currentStep - 1, collectedData: collectedData);
  }

  /// Jumps to a specific step in the wizard.
  ///
  /// The step index must be within valid range [0, totalSteps-1].
  ///
  /// Throws [RangeError] if step is out of range.
  OnboardingState goToStep(int step) {
    if (step < 0 || step >= totalSteps) {
      throw RangeError(
        'Step index $step is out of range [0, ${totalSteps - 1}]',
      );
    }
    return copyWith(currentStep: step, collectedData: collectedData);
  }

  /// Retrieves a value from the collected data.
  ///
  /// Returns null if the key doesn't exist.
  ///
  /// Example:
  /// ```dart
  /// final age = state.getData<int>('age');
  /// ```
  T? getData<T>(String key) {
    final value = collectedData[key];
    return value is T ? value : null;
  }

  /// Retrieves a value from the collected data with a default fallback.
  ///
  /// Returns [defaultValue] if the key doesn't exist or the value is null.
  ///
  /// Example:
  /// ```dart
  /// final notes = state.getDataOrDefault<String>('dietaryNotes', '');
  /// ```
  T getDataOrDefault<T>(String key, T defaultValue) {
    final value = collectedData[key];
    return value is T ? value : defaultValue;
  }

  /// Resets the wizard to the initial state.
  ///
  /// Clears all collected data and returns to the first step.
  OnboardingState reset() => OnboardingState.initial();
}
