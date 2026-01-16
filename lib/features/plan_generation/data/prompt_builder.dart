import 'package:fitgenie_app/features/onboarding/domain/user_profile.dart';
import 'package:fitgenie_app/features/plan_generation/domain/weekly_plan.dart';

import '../../../core/utils/formatters.dart';

/// Constructs structured prompts for Gemini AI plan generation and modification.
///
/// This class is critical for ensuring consistent, high-quality AI responses.
/// It defines the exact JSON schema expected in responses and includes all
/// necessary constraints for safe, personalized fitness guidance.
///
/// Key Responsibilities:
/// - Build generation prompts from UserProfile with equipment/dietary constraints
/// - Build modification prompts with existing plan context
/// - Define explicit JSON schema for reliable parsing
/// - Include safety guidelines and content constraints
/// - Provide clear instructions for equipment-specific exercises
/// - Enforce dietary restrictions in meal planning
///
/// Usage:
/// ```dart
/// // Initial plan generation
/// final prompt = PromptBuilder.buildGenerationPrompt(userProfile);
/// final response = await geminiService.generateContent(prompt);
///
/// // Plan modification
/// final modPrompt = PromptBuilder.buildModificationPrompt(
///   currentPlan,
///   'Make Tuesday vegetarian',
/// );
/// final modResponse = await geminiService.generateContent(modPrompt);
/// ```
///
/// Architecture Notes:
/// - Prompts must specify exact field names matching domain models
/// - JSON schema is embedded directly in prompt for clarity
/// - All responses are validated against this schema by JsonParser
/// - Equipment constraints prevent suggesting unavailable exercises
class PromptBuilder {
  PromptBuilder._(); // Private constructor to prevent instantiation

  /// Builds a complete prompt for generating a new 7-day fitness plan.
  ///
  /// Creates a comprehensive prompt that includes:
  /// - User profile context (age, weight, height, goal, equipment, diet)
  /// - Explicit JSON schema for the response format
  /// - Equipment constraints (only use available equipment)
  /// - Dietary restrictions (respect all limitations)
  /// - Safety guidelines (appropriate for fitness level)
  /// - Content structure requirements
  ///
  /// Parameters:
  /// - [profile]: The user's profile with all biometric and preference data
  ///
  /// Returns: Complete prompt string ready for Gemini API
  ///
  /// Example:
  /// ```dart
  /// final profile = UserProfile(
  ///   age: 28,
  ///   goal: FitnessGoal.muscleGain,
  ///   equipment: EquipmentType.homeGym,
  ///   equipmentDetails: ['dumbbells', 'pull-up bar'],
  ///   dietaryRestrictions: [DietaryRestriction.vegetarian],
  /// );
  /// final prompt = PromptBuilder.buildGenerationPrompt(profile);
  /// ```
  static String buildGenerationPrompt(UserProfile profile) {
    final contextString = profile.toPromptContext();

    return '''
You are FitGenie, an expert AI personal trainer and nutritionist. Your role is to create personalized, safe, and effective fitness and nutrition plans.

=== USER PROFILE ===
$contextString

=== CRITICAL CONSTRAINTS ===
1. EQUIPMENT: ONLY suggest exercises using this equipment: ${_formatEquipment(profile)}
   - Do NOT suggest any exercises requiring equipment the user doesn't have
   - If bodyweight only, ALL exercises must be bodyweight
   - Each exercise must list its required equipment

2. DIETARY: RESPECT these restrictions: ${_formatDietaryRestrictions(profile)}
   - Every meal must comply with ALL dietary restrictions
   - Double-check ingredients for hidden allergens
   - No substitutions that violate restrictions

3. SAFETY:
   - Exercises appropriate for the user's experience level
   - Proper warm-up and cool-down for each workout
   - Progressive overload principles for ${profile.goal.displayName}
   - No dangerous exercises for beginners

4. PERSONALIZATION:
   - Workouts aligned with goal: ${profile.goal.promptValue}
   - Meal plan supports the fitness goal
   - Appropriate volume and intensity
   - Include rest days for recovery

=== WORKOUT PROGRAMMING GUIDELINES ===
- Strength training: 3-5 sets of 8-12 reps for hypertrophy, 3-6 reps for strength
- Cardio: 20-45 minutes, moderate to high intensity
- Rest between sets: 60-90 seconds for hypertrophy, 2-3 minutes for strength
- Include compound movements when possible
- Progress through the week (lighter on Monday, heavier mid-week, lighter Friday)
- 1-2 rest days per week

=== MEAL PLANNING GUIDELINES ===
- 3 main meals per day (breakfast, lunch, dinner)
- Calorie targets based on goal:
  * Muscle gain: Slight surplus (10-20% above maintenance)
  * Weight loss: Moderate deficit (15-25% below maintenance)
  * General fitness: Maintenance calories
- Protein: 1.6-2.2g per kg bodyweight for muscle gain, 1.2-1.6g for weight loss
- Include variety in food choices
- Simple, practical meals that don't require excessive prep time
- All ingredients must respect dietary restrictions

=== REQUIRED OUTPUT FORMAT ===
You MUST respond with ONLY valid JSON matching this EXACT schema. No markdown, no explanations, just the JSON object:

{
  "id": "unique-plan-id",
  "days": [
    {
      "id": "unique-day-id",
      "dayIndex": 0,
      "date": "2026-01-20T00:00:00.000Z",
      "workout": {
        "id": "unique-workout-id",
        "name": "Workout Name",
        "type": "strength|cardio|flexibility|rest",
        "durationMinutes": 45,
        "exercises": [
          {
            "id": "unique-exercise-id",
            "name": "Exercise Name",
            "sets": 3,
            "reps": "10-12",
            "restSeconds": 90,
            "notes": "Form cues and tips",
            "equipmentRequired": ["dumbbells"],
            "isComplete": false
          }
        ]
      },
      "meals": [
        {
          "id": "unique-meal-id",
          "name": "Meal Name",
          "type": "breakfast|lunch|dinner|snack",
          "calories": 500,
          "protein": 30,
          "carbs": 50,
          "fat": 15,
          "ingredients": ["1 cup ingredient", "2 tbsp ingredient"],
          "instructions": "Brief preparation steps",
          "isComplete": false
        }
      ]
    }
  ]
}

IMPORTANT NOTES:
- Generate ALL 7 days (dayIndex 0-6 for Monday-Sunday)
- Each day needs a date (starting from Monday of current week)
- Use unique IDs for all entities (plan, days, workouts, exercises, meals)
- "reps" can be a range ("10-12") or duration ("30 seconds")
- Set "isComplete" to false for all exercises and meals
- For rest days, set workout type to "rest" and provide empty exercises array
- Ensure workout types vary appropriately across the week
- Include at least 1-2 rest days

Generate a complete, personalized 7-day plan now:
''';
  }

  /// Builds a prompt for modifying an existing plan.
  ///
  /// Creates a prompt that includes the current plan context and the user's
  /// modification request. The AI should preserve the overall structure while
  /// making the requested changes.
  ///
  /// Parameters:
  /// - [currentPlan]: The existing WeeklyPlan to be modified
  /// - [modificationRequest]: User's natural language modification request
  ///
  /// Returns: Complete modification prompt string
  ///
  /// Example:
  /// ```dart
  /// final prompt = PromptBuilder.buildModificationPrompt(
  ///   weeklyPlan,
  ///   'Make all meals vegetarian and swap Tuesday workout for cardio',
  /// );
  /// ```
  static String buildModificationPrompt(
    WeeklyPlan currentPlan,
    String modificationRequest,
  ) {
    return '''
You are FitGenie, an expert AI personal trainer and nutritionist. A user wants to modify their existing fitness plan.

=== CURRENT PLAN ===
Plan ID: ${currentPlan.id}
Week: ${currentPlan.dateRangeDisplay}
Generated: ${currentPlan.createdAt.toIso8601String()}

Current plan structure:
${_summarizePlan(currentPlan)}

=== USER'S MODIFICATION REQUEST ===
"$modificationRequest"

=== YOUR TASK ===
Modify the plan according to the user's request while:
1. Preserving the same plan ID and overall structure
2. Keeping unchanged days exactly as they are
3. Maintaining the user's equipment constraints from the profile snapshot
4. Respecting dietary restrictions from the profile snapshot
5. Ensuring modifications make sense in the context of the full week

=== REQUIRED OUTPUT FORMAT ===
Respond with ONLY valid JSON matching the EXACT schema from the original plan.
Return the COMPLETE modified plan with all 7 days (even if only some changed).

{
  "id": "${currentPlan.id}",
  "days": [
    // All 7 days with modifications applied
  ]
}

Generate the modified plan now:
''';
  }

  /// Formats equipment list for prompt.
  static String _formatEquipment(UserProfile profile) {
    if (profile.equipment == EquipmentType.bodyweight) {
      return 'Bodyweight only (no equipment)';
    }

    if (profile.equipmentDetails.isEmpty) {
      return profile.equipment.displayName;
    }

    return '${profile.equipment.displayName}: ${Formatters.list(profile.equipmentDetails)}';
  }

  /// Formats dietary restrictions for prompt.
  static String _formatDietaryRestrictions(UserProfile profile) {
    if (profile.dietaryRestrictions.isEmpty) {
      return 'No restrictions';
    }

    final restrictionNames = profile.dietaryRestrictions
        .map((r) => r.displayName)
        .toList();
    final restrictionsText = Formatters.list(restrictionNames);

    if (profile.dietaryNotes != null && profile.dietaryNotes!.isNotEmpty) {
      return '$restrictionsText (Note: ${profile.dietaryNotes})';
    }

    return restrictionsText;
  }

  /// Creates a brief summary of the current plan for modification context.
  static String _summarizePlan(WeeklyPlan plan) {
    final buffer = StringBuffer();

    for (final day in plan.days) {
      buffer.writeln(
        '- ${day.dayName}: ${day.workout?.name ?? "Rest Day"} + ${Formatters.count(day.mealCount, 'meal')}',
      );
    }

    return buffer.toString();
  }

  /// Builds a simplified prompt for chat-based quick modifications.
  ///
  /// Used when user makes simple requests via chat interface that don't
  /// require regenerating the entire plan.
  ///
  /// Parameters:
  /// - [context]: Brief context about what's being modified
  /// - [userRequest]: The modification request
  ///
  /// Returns: Simplified prompt for quick modifications
  ///
  /// Example:
  /// ```dart
  /// final prompt = PromptBuilder.buildQuickModificationPrompt(
  ///   'Tuesday lunch',
  ///   'Make it dairy-free',
  /// );
  /// ```
  static String buildQuickModificationPrompt(
    String context,
    String userRequest,
  ) {
    return '''
You are FitGenie. A user wants to modify: $context

Request: "$userRequest"

Provide a brief, helpful response explaining what changes will be made.
Keep it conversational and friendly. Confirm the modification will be applied.

Respond in 2-3 sentences maximum.
''';
  }

  /// Validates that a generated plan response contains all required fields.
  ///
  /// This is a helper for documenting the expected structure. Actual validation
  /// happens in JsonParser, but this serves as reference.
  ///
  /// Required top-level fields:
  /// - id (String)
  /// - days (List of 7 day objects)
  ///
  /// Required day fields:
  /// - id, dayIndex, date, workout, meals
  ///
  /// Required workout fields:
  /// - id, name, type, durationMinutes, exercises
  ///
  /// Required exercise fields:
  /// - id, name, sets, reps, restSeconds, equipmentRequired
  ///
  /// Required meal fields:
  /// - id, name, type, calories, protein, carbs, fat, ingredients
  static const requiredFields = {
    'plan': ['id', 'days'],
    'day': ['id', 'dayIndex', 'date', 'workout', 'meals'],
    'workout': ['id', 'name', 'type', 'durationMinutes', 'exercises'],
    'exercise': [
      'id',
      'name',
      'sets',
      'reps',
      'restSeconds',
      'equipmentRequired',
    ],
    'meal': [
      'id',
      'name',
      'type',
      'calories',
      'protein',
      'carbs',
      'fat',
      'ingredients',
    ],
  };
}
