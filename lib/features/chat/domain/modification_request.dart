/// Represents a structured plan modification request from the user.
///
/// This model captures the user's intent to modify their fitness plan and
/// provides a structured format for processing modifications through the AI.
/// It bridges the gap between natural language requests and concrete plan updates.
///
/// Key Features:
/// - Typed modification categories via [ModificationType] enum
/// - Identifies specific target items in the plan (day, meal, exercise)
/// - Preserves original user request for context
/// - Contains parsed new values from AI response
/// - Lightweight model (no JSON serialization - transient data)
///
/// Data Flow:
/// 1. User sends chat message: "Make Tuesday lunch vegetarian"
/// 2. ChatRepository parses intent → ModificationRequest created
/// 3. Request sent to AI with current plan context
/// 4. AI returns modification → newValue populated
/// 5. Repository applies modification to plan
/// 6. Chat message updated with modificationApplied=true
///
/// Example:
/// ```dart
/// // Swap meal modification
/// final request = ModificationRequest(
///   type: ModificationType.swapMeal,
///   targetId: 'meal_456',
///   targetDate: DateTime(2026, 1, 21), // Tuesday
///   userRequest: 'Make Tuesday lunch vegetarian',
///   newValue: {
///     'name': 'Veggie Buddha Bowl',
///     'ingredients': ['quinoa', 'chickpeas', 'vegetables'],
///     'dietaryInfo': ['Vegetarian', 'Vegan'],
///   },
/// );
///
/// // Adjust workout modification
/// final workoutRequest = ModificationRequest(
///   type: ModificationType.adjustIntensity,
///   targetId: 'workout_123',
///   targetDate: DateTime(2026, 1, 22), // Wednesday
///   userRequest: 'Make Wednesday easier, I\'m sore',
///   newValue: {
///     'exercises': [...], // Updated exercise list
///     'durationMinutes': 30, // Reduced from 45
///   },
/// );
/// ```
///
/// Architecture Notes:
/// - This is a transient model (not persisted)
/// - Created and consumed within single modification flow
/// - Parsing logic handles various user request formats
/// - AI response provides newValue data
class ModificationRequest {
  /// The type of modification being requested.
  final ModificationType type;

  /// The unique identifier of the target item to modify.
  ///
  /// This could be:
  /// - Meal ID: For meal swap/modification
  /// - Workout ID: For workout changes
  /// - Exercise ID: For exercise adjustments
  /// - Day ID: For day-level changes
  ///
  /// Used to locate the specific item in the WeeklyPlan structure.
  final String targetId;

  /// The date of the plan day being modified.
  ///
  /// Used to identify which day in the weekly plan to update.
  /// Must be within the current plan's week range.
  final DateTime targetDate;

  /// The original natural language request from the user.
  ///
  /// Preserved for:
  /// - AI context (sent with modification prompt)
  /// - Error messaging if modification fails
  /// - Logging and debugging
  ///
  /// Examples:
  /// - "Make Tuesday lunch vegetarian"
  /// - "I'm sore today, easier workout"
  /// - "Swap Wednesday dinner for something quick"
  final String userRequest;

  /// The new value data for the modification, parsed from AI response.
  ///
  /// Structure varies by modification type:
  /// - Meal swap: Complete meal object as Map
  /// - Exercise swap: Complete exercise object as Map
  /// - Intensity adjustment: Modified workout with updated reps/sets
  /// - Dietary change: Updated ingredients/meal list
  ///
  /// Null if modification hasn't been processed by AI yet.
  final Map<String, dynamic>? newValue;

  /// Creates a ModificationRequest with the specified properties.
  ///
  /// All fields except [newValue] are required. The [newValue] is populated
  /// after AI processes the request.
  const ModificationRequest({
    required this.type,
    required this.targetId,
    required this.targetDate,
    required this.userRequest,
    this.newValue,
  });

  /// Creates a ModificationRequest from a user's natural language message.
  ///
  /// This factory constructor attempts to parse the user's intent from their
  /// message content. It uses heuristics and keyword matching to determine
  /// the modification type and target.
  ///
  /// Parameters:
  /// - [userMessage]: The user's chat message content
  /// - [currentPlanContext]: The current WeeklyPlan for context
  ///
  /// Returns: ModificationRequest or null if intent cannot be determined
  ///
  /// Examples:
  /// ```dart
  /// final request = ModificationRequest.fromUserMessage(
  ///   'Make Tuesday lunch vegetarian',
  ///   currentPlan,
  /// );
  /// ```
  factory ModificationRequest.fromUserMessage(
    String userMessage,
    DateTime targetDate, {
    String? targetId,
  }) {
    final lowercaseMessage = userMessage.toLowerCase();

    // Determine modification type from keywords using rule-based matching
    final type = _determineModificationType(lowercaseMessage);

    return ModificationRequest(
      type: type,
      targetId: targetId ?? _generateTempId(),
      targetDate: targetDate,
      userRequest: userMessage,
      newValue: null,
    );
  }

  /// Creates a copy of this request with updated fields.
  ///
  /// Typically used to add [newValue] after AI processes the request.
  ///
  /// Example:
  /// ```dart
  /// final processedRequest = request.copyWith(
  ///   newValue: aiParsedData,
  /// );
  /// ```
  ModificationRequest copyWith({
    ModificationType? type,
    String? targetId,
    DateTime? targetDate,
    String? userRequest,
    Map<String, dynamic>? newValue,
  }) {
    return ModificationRequest(
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      targetDate: targetDate ?? this.targetDate,
      userRequest: userRequest ?? this.userRequest,
      newValue: newValue ?? this.newValue,
    );
  }

  /// Whether this modification has been processed by AI.
  bool get isProcessed => newValue != null;

  /// User-friendly description of the modification type.
  String get typeDescription => type.displayName;

  /// Determines the modification type from the user message using rule-based matching.
  ///
  /// This approach is more maintainable than nested if-else statements.
  /// Rules are checked in priority order, with more specific rules first.
  static ModificationType _determineModificationType(String lowercaseMessage) {
    // Define modification rules with primary and secondary keyword requirements
    final rules = [
      // Swap operations (require both primary and secondary keywords)
      const _ModificationTypeRule(
        type: ModificationType.swapMeal,
        primaryKeywords: ['swap', 'change', 'replace', 'different'],
        secondaryKeywords: ['meal', 'breakfast', 'lunch', 'dinner'],
      ),
      const _ModificationTypeRule(
        type: ModificationType.swapExercise,
        primaryKeywords: ['swap', 'change', 'replace', 'different'],
        secondaryKeywords: ['exercise', 'workout'],
      ),
      // Intensity adjustments
      const _ModificationTypeRule(
        type: ModificationType.adjustIntensity,
        primaryKeywords: [
          'easier',
          'harder',
          'intense',
          'light',
          'more reps',
          'less reps',
        ],
      ),
      // Dietary changes
      const _ModificationTypeRule(
        type: ModificationType.dietaryChange,
        primaryKeywords: ['vegetarian', 'vegan', 'gluten', 'dairy', 'dietary'],
      ),
      // Skip day
      const _ModificationTypeRule(
        type: ModificationType.skipDay,
        primaryKeywords: ['skip', 'rest', 'off'],
      ),
    ];

    // Find the first matching rule
    for (final rule in rules) {
      if (rule.matches(lowercaseMessage)) {
        return rule.type;
      }
    }

    // Default to 'other' if no rules match
    return ModificationType.other;
  }

  /// Generates a temporary ID for modifications without specific targets.
  static String _generateTempId() {
    return 'mod_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  String toString() {
    return 'ModificationRequest(type: $type, targetId: $targetId, '
        'targetDate: $targetDate, userRequest: "$userRequest", '
        'isProcessed: $isProcessed)';
  }
}

/// Enumeration of plan modification types.
///
/// Categorizes the different kinds of modifications users can request
/// through the chat interface.
enum ModificationType {
  /// Swap a meal with a different meal.
  ///
  /// Example: "Replace Tuesday lunch with something vegetarian"
  swapMeal,

  /// Swap an exercise with a different exercise.
  ///
  /// Example: "Replace bench press with push-ups"
  swapExercise,

  /// Adjust workout intensity (reps, sets, weight, duration).
  ///
  /// Example: "Make today's workout easier" or "Increase reps to 15"
  adjustIntensity,

  /// Change dietary preferences for meals.
  ///
  /// Example: "Make all meals this week vegan"
  dietaryChange,

  /// Skip a specific day (make it a rest day).
  ///
  /// Example: "Skip Wednesday workout" or "Make Friday a rest day"
  skipDay,

  /// Change the day of a workout.
  ///
  /// Example: "Move Tuesday workout to Thursday"
  changeDay,

  /// Other/unclassified modification.
  ///
  /// Catch-all for requests that don't fit other categories.
  /// AI will attempt to understand intent and apply appropriate changes.
  other,
}

/// Extension on ModificationType to provide display strings.
extension ModificationTypeExtension on ModificationType {
  /// User-friendly display name for the modification type.
  String get displayName {
    switch (this) {
      case ModificationType.swapMeal:
        return 'Meal Swap';
      case ModificationType.swapExercise:
        return 'Exercise Swap';
      case ModificationType.adjustIntensity:
        return 'Intensity Adjustment';
      case ModificationType.dietaryChange:
        return 'Dietary Change';
      case ModificationType.skipDay:
        return 'Skip Day';
      case ModificationType.changeDay:
        return 'Reschedule';
      case ModificationType.other:
        return 'Plan Modification';
    }
  }

  /// Brief description of what this modification does.
  String get description {
    switch (this) {
      case ModificationType.swapMeal:
        return 'Replace a meal with a different option';
      case ModificationType.swapExercise:
        return 'Replace an exercise with an alternative';
      case ModificationType.adjustIntensity:
        return 'Change workout difficulty or volume';
      case ModificationType.dietaryChange:
        return 'Update dietary preferences for meals';
      case ModificationType.skipDay:
        return 'Convert a workout day to rest day';
      case ModificationType.changeDay:
        return 'Move workout to a different day';
      case ModificationType.other:
        return 'Custom plan modification';
    }
  }

  /// Icon name suggestion for UI display.
  String get iconName {
    switch (this) {
      case ModificationType.swapMeal:
        return 'swap_horiz';
      case ModificationType.swapExercise:
        return 'swap_horiz';
      case ModificationType.adjustIntensity:
        return 'tune';
      case ModificationType.dietaryChange:
        return 'restaurant';
      case ModificationType.skipDay:
        return 'event_busy';
      case ModificationType.changeDay:
        return 'calendar_today';
      case ModificationType.other:
        return 'edit';
    }
  }
}

/// Helper class for rule-based modification type detection.
///
/// Encapsulates the logic for matching user messages against keyword patterns.
/// Supports both primary-only keywords and combinations of primary + secondary keywords.
class _ModificationTypeRule {
  final ModificationType type;
  final List<String> primaryKeywords;
  final List<String>? secondaryKeywords;

  const _ModificationTypeRule({
    required this.type,
    required this.primaryKeywords,
    this.secondaryKeywords,
  });

  /// Checks if this rule matches the given message.
  ///
  /// Returns true if:
  /// - Message contains at least one primary keyword, AND
  /// - If secondaryKeywords is provided, message contains at least one secondary keyword
  bool matches(String lowercaseMessage) {
    final hasPrimary = primaryKeywords.any((k) => lowercaseMessage.contains(k));

    if (!hasPrimary) return false;

    // If no secondary keywords required, match on primary alone
    if (secondaryKeywords == null || secondaryKeywords!.isEmpty) {
      return true;
    }

    // Check for secondary keyword match
    return secondaryKeywords!.any((k) => lowercaseMessage.contains(k));
  }
}
