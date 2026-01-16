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
/// final plan = await repository.generatePlan(userProfile);
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
  /// Creates a PlanRepository with required dependencies.
  ///
  /// Parameters:
  /// - [geminiService]: Service for AI plan generation
  /// - [localDatasource]: Hive-based local storage
  /// - [remoteDatasource]: Firestore-based remote storage
  const PlanRepository({
    required GeminiService geminiService,
    required PlanLocalDatasource localDatasource,
    required PlanRemoteDatasource remoteDatasource,
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
  ///   final plan = await repository.generatePlan(userProfile);
  ///   print('Generated plan: ${plan.dateRangeDisplay}');
  /// } on AiException catch (e) {
  ///   print('Generation failed: ${e.userFriendlyMessage}');
  /// }
  /// ```
  Future<WeeklyPlan> generatePlan(UserProfile profile) async {
    // Step 1: Build AI prompt with user context
    final prompt = PromptBuilder.buildGenerationPrompt(profile);

    // Step 2: Generate plan via Gemini (with automatic retry)
    final planJson = await _geminiService.generatePlan(prompt);

    // Step 3: Create WeeklyPlan from response
    // Add metadata that AI might not include
    final now = DateTime.now();
    final monday = _getStartOfWeek(now);

    // Ensure required fields exist
    planJson['userId'] = profile.toJson()['userId'] ?? 'unknown';
    planJson['createdAt'] = now.toIso8601String();
    planJson['startDate'] = monday.toIso8601String();
    planJson['profileSnapshot'] = profile.toJson();

    // Generate unique ID if not provided by AI
    if (!planJson.containsKey('id') || planJson['id'] == null) {
      planJson['id'] = 'plan_${now.millisecondsSinceEpoch}';
    }

    // Enrich days with proper dates
    if (planJson.containsKey('days') && planJson['days'] is List) {
      final days = planJson['days'] as List;
      for (int i = 0; i < days.length && i < 7; i++) {
        final day = days[i] as Map<String, dynamic>;
        day['dayIndex'] = i;
        day['date'] = monday.add(Duration(days: i)).toIso8601String();
      }
    }

    // Parse to WeeklyPlan model
    final plan = WeeklyPlan.fromJson(planJson);

    // Validate plan structure
    plan.validate();

    // Step 4: Cache locally (offline access)
    await _localDatasource.savePlan(plan.userId, plan);

    // Step 5: Sync to Firestore (best effort, don't throw on failure)
    try {
      await _remoteDatasource.savePlan(plan.userId, plan);
    } catch (e) {
      print('Warning: Failed to sync plan to Firestore: $e');
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
      print('Error fetching plan from Firestore: $e');
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
      print('Error fetching plan by ID: $e');
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
      print('Warning: Failed to sync exercise completion: $e');
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
      print('Warning: Failed to sync meal completion: $e');
    }

    return updatedPlan;
  }

  /// Modifies the current plan based on user request.
  ///
  /// Uses Gemini AI to interpret the modification request and
  /// regenerate the affected portions of the plan.
  ///
  /// Parameters:
  /// - [userId]: ID of the user
  /// - [modificationRequest]: Natural language modification request
  ///
  /// Returns: Modified WeeklyPlan
  ///
  /// Throws:
  /// - [AiException] if modification fails
  /// - [StateError] if no current plan exists
  ///
  /// Example:
  /// ```dart
  /// final modified = await repository.modifyPlan(
  ///   userId,
  ///   'Make all Tuesday meals vegetarian',
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

    // Build modification prompt
    final prompt = PromptBuilder.buildModificationPrompt(
      currentPlan,
      modificationRequest,
    );

    // Get modified plan from AI
    final modifiedJson = await _geminiService.modifyPlan(prompt);

    // Preserve metadata from current plan
    modifiedJson['id'] = currentPlan.id;
    modifiedJson['userId'] = currentPlan.userId;
    modifiedJson['createdAt'] = currentPlan.createdAt.toIso8601String();
    modifiedJson['startDate'] = currentPlan.startDate.toIso8601String();
    modifiedJson['profileSnapshot'] = currentPlan.profileSnapshot;

    // Parse modified plan
    final modifiedPlan = WeeklyPlan.fromJson(modifiedJson);

    // Validate
    modifiedPlan.validate();

    // Update local cache
    await _localDatasource.savePlan(userId, modifiedPlan);

    // Sync to remote
    try {
      await _remoteDatasource.savePlan(userId, modifiedPlan);
    } catch (e) {
      print('Warning: Failed to sync modified plan: $e');
    }

    return modifiedPlan;
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
      print('Sync failed: $e');
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
      print('Warning: Failed to delete plan from Firestore: $e');
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
}
