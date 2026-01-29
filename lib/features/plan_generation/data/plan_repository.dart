import 'package:logger/logger.dart';
import 'package:fitgenie_app/features/onboarding/domain/user_profile.dart';
import 'package:fitgenie_app/features/plan_generation/domain/day_plan.dart';
import 'package:fitgenie_app/features/plan_generation/domain/exercise.dart';
import 'package:fitgenie_app/features/plan_generation/domain/meal.dart';
import 'package:fitgenie_app/features/plan_generation/domain/weekly_plan.dart';
import 'package:fitgenie_app/features/plan_generation/data/gemini_service.dart';
import 'package:fitgenie_app/features/plan_generation/data/prompt_builder.dart';
import 'package:fitgenie_app/features/plan_generation/data/plan_local_datasource.dart';
import 'package:fitgenie_app/features/plan_generation/data/plan_remote_datasource.dart';
import 'package:fitgenie_app/core/exceptions/ai_exception.dart';

/// Repository for plan generation and management.
///
/// This repository orchestrates the complete plan lifecycle:
/// - Generation: Profile → Prompt → Gemini → Parse → Cache → Sync
/// - Retrieval: Local-first with remote fallback
/// - Updates: Task completion with local-first writes
/// - Sync: Background sync of local changes to Firestore
///
/// Key Responsibilities:
/// - Coordinate AI generation via GeminiService
/// - Implement offline-first data strategy
/// - Manage dual storage (Hive + Firestore)
/// - Handle plan caching and invalidation
/// - Provide clean API for plan operations
///
/// Offline-First Strategy:
/// 1. Reads: Check Hive first → Firestore fallback if missing
/// 2. Writes: Write to Hive immediately → Queue for Firestore sync
/// 3. Completions: Update locally instantly → Sync when online
/// 4. Generation: Cache locally → Sync to remote → Invalidate old cache
///
/// Usage:
/// ```dart
/// final repository = PlanRepository(
///   geminiService: geminiService,
///   localDatasource: localDatasource,
///   remoteDatasource: remoteDatasource,
/// );
///
/// // Generate new plan
/// final plan = await repository.generatePlan(userId, userProfile);
///
/// // Get current plan (offline-first)
/// final current = await repository.getCurrentPlan(userId);
///
/// // Update task completion
/// await repository.markExerciseComplete(userId, planId, dayIndex, exerciseIndex);
///
/// // Sync to remote
/// await repository.syncPlan(userId);
/// ```
///
/// Architecture Notes:
/// - Single source of truth: Firestore (with Hive as cache)
/// - All operations are async
/// - Exceptions are typed (AiException, FirebaseException)
/// - Repository doesn't expose datasources directly
class PlanRepository {
  /// Logger instance for tracking operations and errors.
  final Logger logger;

  /// Creates a PlanRepository with required dependencies.
  ///
  /// Parameters:
  /// - [geminiService]: Service for AI plan generation
  /// - [localDatasource]: Hive-based local storage
  /// - [remoteDatasource]: Firestore-based remote storage
  /// - [logger]: Logger instance for tracking operations
  const PlanRepository({
    required GeminiService geminiService,
    required PlanLocalDatasource localDatasource,
    required PlanRemoteDatasource remoteDatasource,
    required this.logger,
  }) : _geminiService = geminiService,
       _localDatasource = localDatasource,
       _remoteDatasource = remoteDatasource;

  final GeminiService _geminiService;
  final PlanLocalDatasource _localDatasource;
  final PlanRemoteDatasource _remoteDatasource;

  /// Generates a new personalized fitness plan.
  ///
  /// Complete generation flow:
  /// 1. Build prompt from user profile
  /// 2. Send to Gemini AI (with retry logic)
  /// 3. Parse and validate JSON response
  /// 4. Create WeeklyPlan with metadata
  /// 5. Cache locally in Hive
  /// 6. Sync to Firestore
  /// 7. Return generated plan
  ///
  /// Parameters:
  /// - [userId]: Authenticated user ID
  /// - [profile]: User's complete profile with biometrics and preferences
  ///
  /// Returns: Newly generated WeeklyPlan
  ///
  /// Throws:
  /// - [AiException] if generation fails (network, parsing, validation)
  /// - [Exception] if storage fails (logged but not thrown)
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final plan = await repository.generatePlan(userId, userProfile);
  ///   print('Generated plan: ${plan.dateRangeDisplay}');
  /// } on AiException catch (e) {
  ///   print('Generation failed: ${e.userFriendlyMessage}');
  /// }
  /// ```
  Future<WeeklyPlan> generatePlan(String userId, UserProfile profile) async {
    if (userId.isEmpty) {
      throw StateError('User must be authenticated to generate plan');
    }
    // Step 1: Prepare base metadata
    final now = DateTime.now();
    final monday = _getStartOfWeek(now);
    final planId = 'plan_${now.millisecondsSinceEpoch}';

    // Step 2: Generate outline for safe weekly structure
    final outlinePrompt = PromptBuilder.buildOutlinePrompt(
      profile,
      planId,
      monday,
    );
    final outlineJson = await _geminiService.generatePlanOutline(outlinePrompt);
    final outline = _normalizeOutline(outlineJson, planId, monday);

    // Step 3: Generate plan in batches (3 + 3 + 1 days)
    final daysByIndex = <int, Map<String, dynamic>>{};
    final previousDaysSummary = <Map<String, dynamic>>[];

    const batches = [_PlanBatch(0, 2), _PlanBatch(3, 5), _PlanBatch(6, 6)];

    for (final batch in batches) {
      final batchPrompt = PromptBuilder.buildBatchPrompt(
        profile,
        outline,
        previousDaysSummary,
        batch.startDayIndex,
        batch.endDayIndex,
        monday,
      );

      final batchJson = await _geminiService.generatePlanBatch(batchPrompt);
      final batchDays = _extractBatchDays(
        batchJson,
        batch.startDayIndex,
        batch.endDayIndex,
      );

      for (final day in batchDays) {
        final dayIndex = _coerceDayIndex(day['dayIndex']);
        if (dayIndex < batch.startDayIndex || dayIndex > batch.endDayIndex) {
          throw AiException(
            AiErrorType.invalidResponse,
            'Batch returned out-of-range dayIndex $dayIndex',
          );
        }

        if (daysByIndex.containsKey(dayIndex)) {
          throw AiException(
            AiErrorType.invalidResponse,
            'Duplicate dayIndex $dayIndex in batch response',
          );
        }

        day['dayIndex'] = dayIndex;
        day['date'] = monday.add(Duration(days: dayIndex)).toIso8601String();
        _validateDayMatchesOutline(day, outline);

        daysByIndex[dayIndex] = day;
        previousDaysSummary.add(_summarizeDayForPrompt(day, outline));
      }
    }

    if (daysByIndex.length != 7) {
      throw AiException(
        AiErrorType.invalidResponse,
        'Plan must contain 7 days after batching, got ${daysByIndex.length}',
      );
    }

    final days = List<Map<String, dynamic>>.generate(
      7,
      (index) => daysByIndex[index]!,
    );

    final planJson = <String, dynamic>{'id': planId, 'days': days};

    // Step 4: Attach metadata
    planJson['userId'] = userId;
    planJson['createdAt'] = now.toIso8601String();
    planJson['startDate'] = monday.toIso8601String();
    planJson['profileSnapshot'] = profile.toJson();

    // Step 5: Parse to WeeklyPlan model
    final plan = WeeklyPlan.fromJson(planJson);

    // Validate plan structure
    plan.validate();

    // Step 6: Cache locally (offline access)
    await _localDatasource.savePlan(plan.userId, plan);

    // Step 7: Sync to Firestore (best effort, don't throw on failure)
    try {
      await _remoteDatasource.savePlan(plan.userId, plan);
    } catch (e) {
      logger.w('Failed to sync plan to Firestore', error: e);
      // Continue - local cache is sufficient for now
    }

    return plan;
  }

  /// Retrieves the current active plan for a user.
  ///
  /// Implements offline-first strategy:
  /// 1. Check local Hive cache first
  /// 2. If not cached or stale, try Firestore
  /// 3. If found remotely, update local cache
  /// 4. Return plan or null if none exists
  ///
  /// Parameters:
  /// - [userId]: ID of the user whose plan to retrieve
  ///
  /// Returns: WeeklyPlan if exists, null otherwise
  ///
  /// Example:
  /// ```dart
  /// final plan = await repository.getCurrentPlan(userId);
  /// if (plan == null) {
  ///   // Show "Generate Plan" prompt
  /// } else {
  ///   // Display plan
  /// }
  /// ```
  Future<WeeklyPlan?> getCurrentPlan(String userId) async {
    // Try local cache first (fast, offline-capable)
    WeeklyPlan? plan = await _localDatasource.getPlan(userId);

    if (plan != null) {
      // Found in cache
      return plan;
    }

    // Cache miss - try remote
    try {
      plan = await _remoteDatasource.getActivePlan(userId);

      if (plan != null) {
        // Update cache with remote data
        await _localDatasource.savePlan(userId, plan);
      }

      return plan;
    } catch (e) {
      logger.e('Error fetching plan from Firestore', error: e);
      // Return null - might be offline
      return null;
    }
  }

  /// Retrieves a specific plan by ID.
  ///
  /// Parameters:
  /// - [userId]: ID of the user who owns the plan
  /// - [planId]: ID of the specific plan to retrieve
  ///
  /// Returns: WeeklyPlan if found, null otherwise
  Future<WeeklyPlan?> getPlanById(String userId, String planId) async {
    try {
      return await _remoteDatasource.getPlanById(userId, planId);
    } catch (e) {
      logger.e('Error fetching plan by ID', error: e);
      return null;
    }
  }

  /// Marks an exercise as complete.
  ///
  /// Updates both local cache and queues remote sync.
  ///
  /// Parameters:
  /// - [userId]: ID of the user
  /// - [planId]: ID of the plan
  /// - [dayIndex]: Index of the day (0-6)
  /// - [exerciseIndex]: Index of the exercise within the workout
  /// - [isComplete]: Completion status (default: true)
  ///
  /// Returns: Updated WeeklyPlan
  ///
  /// Example:
  /// ```dart
  /// await repository.markExerciseComplete(
  ///   userId,
  ///   planId,
  ///   dayIndex: 0, // Monday
  ///   exerciseIndex: 2, // Third exercise
  /// );
  /// ```
  Future<WeeklyPlan?> markExerciseComplete(
    String userId,
    String planId,
    int dayIndex,
    int exerciseIndex, {
    bool isComplete = true,
  }) async {
    // Get current plan
    final plan = await getCurrentPlan(userId);
    if (plan == null) return null;

    // Update the specific exercise
    final day = plan.days[dayIndex];
    if (day.workout == null || exerciseIndex >= day.workout!.exercises.length) {
      return null;
    }

    final updatedExercise = day.workout!.exercises[exerciseIndex].copyWith(
      isComplete: isComplete,
    );

    final updatedExercises = List<Exercise>.from(day.workout!.exercises);
    updatedExercises[exerciseIndex] = updatedExercise;

    final updatedWorkout = day.workout!.copyWith(exercises: updatedExercises);
    final updatedDay = day.copyWith(workout: updatedWorkout);

    final updatedDays = List<DayPlan>.from(plan.days);
    updatedDays[dayIndex] = updatedDay;

    final updatedPlan = plan.copyWith(days: updatedDays);

    // Save locally immediately
    await _localDatasource.savePlan(userId, updatedPlan);

    // Sync to remote (best effort)
    try {
      final fieldPath =
          'days.$dayIndex.workout.exercises.$exerciseIndex.isComplete';
      await _remoteDatasource.updateCompletion(userId, planId, {
        fieldPath: isComplete,
      });
    } catch (e) {
      logger.w('Failed to sync exercise completion', error: e);
    }

    return updatedPlan;
  }

  /// Marks a meal as complete.
  ///
  /// Updates both local cache and queues remote sync.
  ///
  /// Parameters:
  /// - [userId]: ID of the user
  /// - [planId]: ID of the plan
  /// - [dayIndex]: Index of the day (0-6)
  /// - [mealIndex]: Index of the meal within the day
  /// - [isComplete]: Completion status (default: true)
  ///
  /// Returns: Updated WeeklyPlan
  Future<WeeklyPlan?> markMealComplete(
    String userId,
    String planId,
    int dayIndex,
    int mealIndex, {
    bool isComplete = true,
  }) async {
    // Get current plan
    final plan = await getCurrentPlan(userId);
    if (plan == null) return null;

    // Update the specific meal
    final day = plan.days[dayIndex];
    if (mealIndex >= day.meals.length) {
      return null;
    }

    final updatedMeal = day.meals[mealIndex].copyWith(isComplete: isComplete);

    final updatedMeals = List<Meal>.from(day.meals);
    updatedMeals[mealIndex] = updatedMeal;

    final updatedDay = day.copyWith(meals: updatedMeals);

    final updatedDays = List<DayPlan>.from(plan.days);
    updatedDays[dayIndex] = updatedDay;

    final updatedPlan = plan.copyWith(days: updatedDays);

    // Save locally immediately
    await _localDatasource.savePlan(userId, updatedPlan);

    // Sync to remote (best effort)
    try {
      final fieldPath = 'days.$dayIndex.meals.$mealIndex.isComplete';
      await _remoteDatasource.updateCompletion(userId, planId, {
        fieldPath: isComplete,
      });
    } catch (e) {
      logger.w('Failed to sync meal completion', error: e);
    }

    return updatedPlan;
  }

  /// Modifies the current plan based on user request using partial updates.
  ///
  /// Uses Gemini AI to interpret the modification request and returns
  /// only the modified days/items, which are merged into the existing plan.
  ///
  /// Parameters:
  /// - [userId]: ID of the user
  /// - [modificationRequest]: Natural language modification request
  ///
  /// Returns: Modified WeeklyPlan with merged changes
  ///
  /// Throws:
  /// - [AiException] if modification fails or is rejected
  /// - [StateError] if no current plan exists
  ///
  /// Example:
  /// ```dart
  /// final modified = await repository.modifyPlan(
  ///   userId,
  ///   'Make Tuesday lunch vegetarian',
  /// );
  /// ```
  Future<WeeklyPlan> modifyPlan(
    String userId,
    String modificationRequest,
  ) async {
    // Get current plan
    final currentPlan = await getCurrentPlan(userId);
    if (currentPlan == null) {
      throw StateError('No current plan to modify');
    }

    // Build partial modification prompt
    final prompt = PromptBuilder.buildPartialModificationPrompt(
      currentPlan,
      modificationRequest,
    );

    // Get partial modification from AI
    final resultJson = await _geminiService.modifyPlanPartial(prompt);

    // Check for rejection
    if (resultJson['modificationType'] == 'rejected') {
      throw AiException(
        AiErrorType.invalidRequest,
        resultJson['explanation'] ?? 'Full plan modifications are not supported',
      );
    }

    // Merge changes into existing plan
    final modifiedPlan = _mergePlanChanges(currentPlan, resultJson);

    // Validate
    modifiedPlan.validate();

    // Update local cache (full plan)
    await _localDatasource.savePlan(userId, modifiedPlan);

    // Sync partial changes to remote
    try {
      await _syncPartialChanges(userId, currentPlan.id, resultJson);
    } catch (e) {
      logger.w('Failed to sync modified plan', error: e);
    }

    return modifiedPlan;
  }

  /// Merges partial changes from AI response into the existing plan.
  ///
  /// Creates a new WeeklyPlan with the modified days replaced.
  WeeklyPlan _mergePlanChanges(
    WeeklyPlan currentPlan,
    Map<String, dynamic> changes,
  ) {
    final modifiedDays = changes['modifiedDays'] as List<dynamic>;
    
    // Create a mutable copy of the days list
    final updatedDays = List<DayPlan>.from(currentPlan.days);
    
    // Replace modified days
    for (final dayJson in modifiedDays) {
      final dayIndex = dayJson['dayIndex'] as int;
      
      // Preserve existing day's id if not provided
      if (!dayJson.containsKey('id') || dayJson['id'] == null) {
        dayJson['id'] = currentPlan.days[dayIndex].id;
      }
      
      // Preserve date if not provided
      if (!dayJson.containsKey('date') || dayJson['date'] == null) {
        dayJson['date'] = currentPlan.days[dayIndex].date.toIso8601String();
      }
      
      // Parse the modified day
      final modifiedDay = DayPlan.fromJson(dayJson as Map<String, dynamic>);
      
      // Replace in list
      updatedDays[dayIndex] = modifiedDay;
    }
    
    // Create new plan with updated days
    return currentPlan.copyWith(days: updatedDays);
  }

  /// Syncs partial changes to Firestore using field paths.
  ///
  /// Only updates the specific days that were modified, not the entire plan.
  Future<void> _syncPartialChanges(
    String userId,
    String planId,
    Map<String, dynamic> changes,
  ) async {
    final modifiedDays = changes['modifiedDays'] as List<dynamic>;
    
    // Build day updates map: dayIndex -> day data
    final dayUpdates = <int, Map<String, dynamic>>{};
    
    for (final dayJson in modifiedDays) {
      final dayIndex = dayJson['dayIndex'] as int;
      
      // Convert to Firestore format
      final dayData = DayPlan.fromJson(dayJson as Map<String, dynamic>).toJson();
      
      dayUpdates[dayIndex] = dayData;
    }
    
    // Perform partial update
    await _remoteDatasource.updateDays(userId, planId, dayUpdates);
  }

  /// Forces synchronization of local plan to Firestore.
  ///
  /// Useful for:
  /// - Manual sync after offline operations
  /// - Ensuring data persistence before critical operations
  /// - Testing sync functionality
  ///
  /// Parameters:
  /// - [userId]: ID of the user whose plan to sync
  ///
  /// Returns: true if sync successful, false otherwise
  Future<bool> syncPlan(String userId) async {
    try {
      final plan = await _localDatasource.getPlan(userId);
      if (plan == null) {
        return false;
      }

      await _remoteDatasource.savePlan(userId, plan);
      return true;
    } catch (e) {
      logger.e('Sync failed', error: e);
      return false;
    }
  }

  /// Deletes the current plan for a user.
  ///
  /// Removes from both local cache and Firestore.
  ///
  /// Parameters:
  /// - [userId]: ID of the user
  /// - [planId]: ID of the plan to delete
  Future<void> deletePlan(String userId, String planId) async {
    // Delete from local cache
    await _localDatasource.deletePlan(userId);

    // Delete from remote
    try {
      await _remoteDatasource.deletePlan(userId, planId);
    } catch (e) {
      logger.w('Failed to delete plan from Firestore', error: e);
    }
  }

  /// Checks if user has an active plan.
  ///
  /// Checks local cache first, then remote.
  ///
  /// Parameters:
  /// - [userId]: ID of the user to check
  ///
  /// Returns: true if active plan exists, false otherwise
  Future<bool> hasActivePlan(String userId) async {
    // Check local first
    final hasLocal = await _localDatasource.hasCachedPlan(userId);
    if (hasLocal) return true;

    // Check remote
    try {
      return await _remoteDatasource.hasActivePlan(userId);
    } catch (e) {
      return false;
    }
  }

  /// Gets the Monday date for the week containing the given date.
  DateTime _getStartOfWeek(DateTime date) {
    // DateTime.weekday: 1 = Monday, 7 = Sunday
    final daysFromMonday = date.weekday - 1;
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: daysFromMonday));
  }

  // ======================================================================
  // BATCH GENERATION HELPERS
  // ======================================================================

  Map<String, dynamic> _normalizeOutline(
    Map<String, dynamic> outline,
    String planId,
    DateTime weekStart,
  ) {
    outline['planId'] = outline['planId'] ?? planId;
    outline['weekStartDate'] =
        outline['weekStartDate'] ?? weekStart.toIso8601String();

    final dayOutline = outline['dayOutline'];
    if (dayOutline is! List || dayOutline.length != 7) {
      throw const AiException(
        AiErrorType.invalidResponse,
        'Outline must include dayOutline with 7 days',
      );
    }

    return outline;
  }

  List<Map<String, dynamic>> _extractBatchDays(
    Map<String, dynamic> batchJson,
    int startDayIndex,
    int endDayIndex,
  ) {
    if (!batchJson.containsKey('days') || batchJson['days'] is! List) {
      throw const AiException(
        AiErrorType.invalidResponse,
        'Batch response missing days array',
      );
    }

    final days = batchJson['days'] as List;
    if (days.isEmpty || days.length > 3) {
      throw AiException(
        AiErrorType.invalidResponse,
        'Batch must return 1-3 days, got ${days.length}',
      );
    }

    final parsedDays = <Map<String, dynamic>>[];
    for (final day in days) {
      if (day is! Map<String, dynamic>) {
        throw const AiException(
          AiErrorType.invalidResponse,
          'Each day must be a JSON object',
        );
      }
      parsedDays.add(day);
    }

    // Ensure the batch includes the expected indices range
    for (final day in parsedDays) {
      final index = _coerceDayIndex(day['dayIndex']);
      if (index < startDayIndex || index > endDayIndex) {
        throw AiException(
          AiErrorType.invalidResponse,
          'Batch returned unexpected dayIndex $index',
        );
      }
    }

    return parsedDays;
  }

  int _coerceDayIndex(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }

    throw AiException(
      AiErrorType.invalidResponse,
      'Invalid dayIndex value: $value',
    );
  }

  Map<String, dynamic> _summarizeDayForPrompt(
    Map<String, dynamic> day,
    Map<String, dynamic> outline,
  ) {
    final dayIndex = _coerceDayIndex(day['dayIndex']);
    final workout = day['workout'] as Map<String, dynamic>?;
    final workoutType = workout?['type'] ?? 'rest';
    final workoutName = workout?['name'] ?? 'Rest';
    final intensity = _outlineIntensityForDay(outline, dayIndex);

    return {
      'dayIndex': dayIndex,
      'workoutType': workoutType,
      'workoutName': workoutName,
      'intensity': intensity,
    };
  }

  String _outlineIntensityForDay(Map<String, dynamic> outline, int dayIndex) {
    final dayOutline = outline['dayOutline'];
    if (dayOutline is! List) return 'unknown';

    for (final entry in dayOutline) {
      if (entry is Map<String, dynamic> &&
          _coerceDayIndex(entry['dayIndex']) == dayIndex) {
        return entry['intensity']?.toString() ?? 'unknown';
      }
    }

    return 'unknown';
  }

  void _validateDayMatchesOutline(
    Map<String, dynamic> day,
    Map<String, dynamic> outline,
  ) {
    final dayIndex = _coerceDayIndex(day['dayIndex']);
    final dayOutline = outline['dayOutline'];
    if (dayOutline is! List) {
      throw const AiException(
        AiErrorType.invalidResponse,
        'Outline missing dayOutline list',
      );
    }

    Map<String, dynamic>? outlineEntry;
    for (final entry in dayOutline) {
      if (entry is Map<String, dynamic> &&
          _coerceDayIndex(entry['dayIndex']) == dayIndex) {
        outlineEntry = entry;
        break;
      }
    }

    if (outlineEntry == null) {
      throw AiException(
        AiErrorType.invalidResponse,
        'Outline missing entry for dayIndex $dayIndex',
      );
    }

    final expectedType = outlineEntry['workoutType']?.toString();
    final workout = day['workout'] as Map<String, dynamic>?;
    final actualType = workout?['type']?.toString();

    if (expectedType == null || expectedType.isEmpty) {
      throw AiException(
        AiErrorType.invalidResponse,
        'Outline dayIndex $dayIndex missing workoutType',
      );
    }

    if (expectedType == 'rest') {
      if (actualType != 'rest') {
        throw AiException(
          AiErrorType.invalidResponse,
          'Day $dayIndex must be rest per outline',
        );
      }

      final exercises = workout?['exercises'];
      if (exercises is List && exercises.isNotEmpty) {
        throw AiException(
          AiErrorType.invalidResponse,
          'Rest day $dayIndex should not include exercises',
        );
      }
    } else if (actualType != expectedType) {
      throw AiException(
        AiErrorType.invalidResponse,
        'Day $dayIndex workoutType mismatch: expected $expectedType, got $actualType',
      );
    }
  }
}

class _PlanBatch {
  final int startDayIndex;
  final int endDayIndex;

  const _PlanBatch(this.startDayIndex, this.endDayIndex);
}
