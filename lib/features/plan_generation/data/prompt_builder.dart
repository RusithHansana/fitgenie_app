import 'dart:convert';

import 'package:fitgenie_app/features/onboarding/domain/user_profile.dart';
import 'package:fitgenie_app/features/plan_generation/domain/weekly_plan.dart';
import 'package:fitgenie_app/features/plan_generation/domain/workout.dart';
import 'package:fitgenie_app/core/constants/dietary_options.dart';

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
   - For each meal, include a "dietaryInfo" array listing which restrictions it satisfies
   - Example: If user is vegetarian and nut-free, a tofu meal should have ["Vegetarian", "Nut-free"]

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
- For each meal, populate "dietaryInfo" with applicable restriction labels

=== REQUIRED OUTPUT FORMAT ===
You MUST respond with ONLY valid JSON matching this EXACT schema. No markdown, no explanations.
Output must be minified JSON with no extra whitespace, line breaks, or indentation.

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
          "dietaryInfo": ["Vegetarian", "Gluten-free"],
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

  /// Builds a prompt for generating a lightweight weekly outline.
  ///
  /// The outline is used to ensure safe intensity progression across batches.
  /// It must cover all 7 days with workout type and intensity guidance.
  ///
  /// Parameters:
  /// - [profile]: The user's profile
  /// - [planId]: Pre-generated plan ID to keep consistent across batches
  /// - [weekStartDate]: Monday date for the plan week
  ///
  /// Returns: Prompt string that requests an outline JSON only.
  static String buildOutlinePrompt(
    UserProfile profile,
    String planId,
    DateTime weekStartDate,
  ) {
    final contextString = profile.toPromptContext();
    final weekStartIso = weekStartDate.toIso8601String();

    return '''
You are FitGenie, an expert AI personal trainer and nutritionist.

Your task is to create a SAFE weekly outline only (no full workouts or meals).
This outline will guide separate batch generation requests.

=== USER PROFILE ===
$contextString

=== CRITICAL CONSTRAINTS ===
1. EQUIPMENT: ONLY use ${_formatEquipment(profile)}
2. DIETARY: RESPECT ${_formatDietaryRestrictions(profile)}
3. SAFETY:
   - No unsafe exercises for the user's experience level
   - Include 1-2 rest/low-intensity days
   - Avoid back-to-back high-intensity days
   - If a day is high intensity, the next day must be rest or low intensity

=== OUTPUT FORMAT (JSON ONLY) ===
Respond with ONLY valid JSON matching this schema.
Output must be minified JSON with no extra whitespace, line breaks, or indentation.

{
  "planId": "$planId",
  "weekStartDate": "$weekStartIso",
  "dayOutline": [
    {
      "dayIndex": 0,
      "workoutType": "strength|cardio|flexibility|rest",
      "intensity": "low|moderate|high",
      "focus": "Upper body strength",
      "mealTheme": "High-protein balanced"
    }
  ]
}

IMPORTANT:
- Include ALL 7 days (dayIndex 0-6, Monday-Sunday)
- Ensure intensity progression across the full week
- Keep focus and mealTheme concise

Generate the 7-day outline now:
''';
  }

  /// Builds a prompt for generating a batch of 1-3 days using the outline.
  ///
  /// Parameters:
  /// - [profile]: The user's profile
  /// - [outline]: Outline JSON from buildOutlinePrompt
  /// - [previousDays]: Compact summaries of prior generated days
  /// - [startDayIndex]: First day index for this batch (0-6)
  /// - [endDayIndex]: Last day index for this batch (0-6)
  /// - [weekStartDate]: Monday date for the plan week
  static String buildBatchPrompt(
    UserProfile profile,
    Map<String, dynamic> outline,
    List<Map<String, dynamic>> previousDays,
    int startDayIndex,
    int endDayIndex,
    DateTime weekStartDate,
  ) {
    final contextString = profile.toPromptContext();
    final outlineJson = jsonEncode(outline);
    final previousJson = jsonEncode(previousDays);
    final weekStartIso = weekStartDate.toIso8601String();

    return '''
You are FitGenie, an expert AI personal trainer and nutritionist.

Your task is to generate ONLY the requested day range for a weekly plan.
You MUST follow the outline to ensure safe intensity progression.

=== USER PROFILE ===
$contextString

=== OUTLINE (AUTHORITATIVE) ===
$outlineJson

=== PREVIOUSLY GENERATED DAYS (SUMMARY) ===
$previousJson

=== CRITICAL CONSTRAINTS ===
1. EQUIPMENT: ONLY use ${_formatEquipment(profile)}
2. DIETARY: RESPECT ${_formatDietaryRestrictions(profile)}
3. SAFETY:
   - Follow the outline's workoutType and intensity
   - If previous day is high intensity, next day must be rest or low intensity
   - Avoid unsafe exercises for the user's experience level

=== REQUIRED OUTPUT FORMAT ===
Respond with ONLY valid JSON matching this schema.
Output must be minified JSON with no extra whitespace, line breaks, or indentation.

{
  "planId": "${outline['planId']}",
  "days": [
    {
      "id": "unique-day-id",
      "dayIndex": $startDayIndex,
      "date": "$weekStartIso",
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
          "dietaryInfo": ["Vegetarian", "Gluten-free"],
          "isComplete": false
        }
      ]
    }
  ]
}

IMPORTANT:
- Generate ONLY days $startDayIndex to $endDayIndex (inclusive)
- Use correct dayIndex values for each day
- Use dates based on weekStartDate: $weekStartIso (Monday)
- For rest days, set workout.type to "rest" and exercises to an empty array
- Set isComplete=false for all exercises and meals

Generate this batch now:
''';
  }

  /// Builds a prompt for partial plan modifications.
  ///
  /// Creates a prompt that instructs the AI to return ONLY the modified
  /// days/items, not the full plan. Full plan changes are rejected.
  ///
  /// Parameters:
  /// - [currentPlan]: The existing WeeklyPlan to be modified
  /// - [modificationRequest]: User's natural language modification request
  ///
  /// Returns: Partial modification prompt string
  ///
  /// Example:
  /// ```dart
  /// final prompt = PromptBuilder.buildPartialModificationPrompt(
  ///   weeklyPlan,
  ///   'Make Tuesday lunch vegetarian',
  /// );
  /// ```
  static String buildPartialModificationPrompt(
    WeeklyPlan currentPlan,
    String modificationRequest,
  ) {
    return '''
You are FitGenie, an expert AI personal trainer and nutritionist. A user wants to make a TARGETED modification to their existing fitness plan.

=== CURRENT PLAN SUMMARY ===
Plan ID: ${currentPlan.id}
Week: ${currentPlan.dateRangeDisplay}

${_summarizePlanDetailed(currentPlan)}

=== USER'S MODIFICATION REQUEST ===
"$modificationRequest"

=== CRITICAL RULES ===
1. ONLY modify the specific days/items requested
2. Return ONLY the modified days, NOT the entire plan
3. REJECT requests that would change more than 3 days or the entire plan
4. Preserve equipment constraints: ${_formatEquipmentFromSnapshot(currentPlan.profileSnapshot)}
5. Respect dietary restrictions: ${_formatDietaryFromSnapshot(currentPlan.profileSnapshot)}

=== REJECTION CRITERIA ===
You MUST return modificationType: "rejected" for these requests:
- "Give me a new plan" or "regenerate my plan"
- "Change everything" or "modify the whole week"
- Any request affecting more than 3 days
- Requests that are too vague to identify specific changes

=== REQUIRED OUTPUT FORMAT ===
Respond with ONLY valid JSON matching this schema.
Output must be minified JSON with no extra whitespace, line breaks, or indentation.

{
  "modificationType": "dayReplacement|workoutUpdate|mealUpdate|rejected",
  "modifiedDays": [
    {
      "id": "existing-day-id",
      "dayIndex": 0,
      "date": "2026-01-20T00:00:00.000Z",
      "workout": {
        "id": "workout-id",
        "name": "Updated Workout Name",
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
          "id": "meal-id",
          "name": "Updated Meal Name",
          "type": "breakfast|lunch|dinner|snack",
          "calories": 500,
          "protein": 30,
          "carbs": 50,
          "fat": 15,
          "ingredients": ["1 cup ingredient"],
          "instructions": "Brief preparation steps",
          "dietaryInfo": ["Vegetarian"],
          "isComplete": false
        }
      ]
    }
  ],
  "explanation": "Changed Tuesday's lunch to a vegetarian stir-fry"
}

=== EXERCISE FIELD REQUIREMENTS ===
CRITICAL: Each exercise MUST include these fields with exact names and types:
- "id": String (unique identifier)
- "name": String (exercise name)
- "sets": Integer (number of sets, use 1 for time-based exercises)
- "reps": String (rep count or duration, e.g., "10-12" or "30 seconds")
- "restSeconds": Integer (rest between sets in seconds, use 60 as default)
- "notes": String or null (form cues)
- "equipmentRequired": Array of strings (e.g., ["dumbbells"] or ["bodyweight"])
- "isComplete": false

DO NOT use these wrong field names:
- "equipment" → use "equipmentRequired"
- "instructions" → use "notes"
- "weight" → not needed
- "durationMinutes" → not needed for exercises

=== MODIFICATION TYPES ===
- dayReplacement: Entire day(s) are being replaced (workout + meals)
- workoutUpdate: Only workout portion of day(s) is changing
- mealUpdate: Only specific meal(s) within day(s) are changing
- rejected: Request cannot be fulfilled (too broad or invalid)

=== NOTES ===
- For mealUpdate: only include the changed meals in the meals array
- For workoutUpdate: only include NEWLY ADDED exercises in the exercises array
  * Do NOT include existing exercises in the response
  * Do NOT summarize or condense existing exercises
  * The app will automatically merge new exercises with existing ones
- Preserve existing IDs when updating items (don't generate new IDs for existing items)
- Generate new unique IDs for newly added exercises/meals
- Set isComplete to false for any new/modified exercises or meals

Generate the partial modification response now:
''';
  }

  /// Builds the old full plan modification prompt.
  ///
  /// @deprecated Use [buildPartialModificationPrompt] instead.
  @Deprecated('Use buildPartialModificationPrompt for partial updates')
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

  /// Creates a detailed summary for partial modification context.
  ///
  /// Includes meal names and workout details for better AI context.
  static String _summarizePlanDetailed(WeeklyPlan plan) {
    final buffer = StringBuffer();

    for (final day in plan.days) {
      buffer.writeln('${day.dayName} (dayIndex: ${day.dayIndex}):');

      // Workout info
      if (day.workout != null && day.workout!.type != WorkoutType.rest) {
        buffer.writeln(
          '  Workout: ${day.workout!.name} (${day.workout!.type.name}, ${day.workout!.durationMinutes}min)',
        );
      } else {
        buffer.writeln('  Workout: Rest Day');
      }

      // Meals summary
      for (final meal in day.meals) {
        buffer.writeln(
          '  ${meal.type.name}: ${meal.name} (${meal.calories} cal)',
        );
      }

      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Extracts equipment info from profile snapshot for modification prompts.
  static String _formatEquipmentFromSnapshot(Map<String, dynamic> snapshot) {
    final equipment = snapshot['equipment'] as String?;
    final equipmentDetails = snapshot['equipmentDetails'] as List<dynamic>?;

    if (equipment == null || equipment == 'bodyweight') {
      return 'Bodyweight only (no equipment)';
    }

    if (equipmentDetails != null && equipmentDetails.isNotEmpty) {
      return '$equipment: ${equipmentDetails.join(', ')}';
    }

    return equipment;
  }

  /// Extracts dietary restrictions from profile snapshot for modification prompts.
  static String _formatDietaryFromSnapshot(Map<String, dynamic> snapshot) {
    final restrictions = snapshot['dietaryRestrictions'] as List<dynamic>?;
    final notes = snapshot['dietaryNotes'] as String?;

    if (restrictions == null || restrictions.isEmpty) {
      return 'No restrictions';
    }

    final restrictionsText = restrictions.join(', ');

    if (notes != null && notes.isNotEmpty) {
      return '$restrictionsText (Note: $notes)';
    }

    return restrictionsText;
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
      'dietaryInfo',
    ],
  };
}
