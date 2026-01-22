import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fitgenie_app/features/plan_generation/domain/weekly_plan.dart';
import 'package:fitgenie_app/features/plan_generation/domain/day_plan.dart';
import 'package:fitgenie_app/features/plan_generation/data/gemini_service.dart';
import 'package:fitgenie_app/features/plan_generation/data/plan_local_datasource.dart';
import 'package:fitgenie_app/features/plan_generation/data/plan_remote_datasource.dart';
import 'package:fitgenie_app/features/plan_generation/data/plan_repository.dart';
import 'package:fitgenie_app/features/auth/auth_providers.dart';
import 'package:fitgenie_app/features/onboarding/onboarding_providers.dart';
import 'package:fitgenie_app/shared/providers/firebase_providers.dart'
    hide currentUserIdProvider;
import 'package:fitgenie_app/shared/providers/logger_provider.dart';

part 'plan_providers.g.dart';

/// Provider for GeminiService singleton.
///
/// Creates and caches the Gemini AI service for plan generation.
/// The service is initialized once and reused across the app.
@Riverpod(keepAlive: true)
GeminiService geminiService(GeminiServiceRef ref) {
  return GeminiService(logger: ref.watch(loggerProvider));
}

/// Provider for PlanLocalDatasource singleton.
///
/// Creates and caches the local datasource for Hive operations.
@Riverpod(keepAlive: true)
PlanLocalDatasource planLocalDatasource(PlanLocalDatasourceRef ref) {
  return PlanLocalDatasource(logger: ref.watch(loggerProvider));
}

/// Provider for PlanRemoteDatasource singleton.
///
/// Creates and caches the remote datasource for Firestore operations.
/// Depends on the Firestore instance from firebase_providers.
@Riverpod(keepAlive: true)
PlanRemoteDatasource planRemoteDatasource(PlanRemoteDatasourceRef ref) {
  final firestore = ref.watch(firestoreProvider);
  return PlanRemoteDatasource(firestore: firestore);
}

/// Provider for PlanRepository singleton.
///
/// Orchestrates plan generation, storage, and retrieval.
/// Depends on all datasources and services.
///
/// This is the main entry point for plan-related operations.
@Riverpod(keepAlive: true)
PlanRepository planRepository(PlanRepositoryRef ref) {
  return PlanRepository(
    geminiService: ref.watch(geminiServiceProvider),
    localDatasource: ref.watch(planLocalDatasourceProvider),
    remoteDatasource: ref.watch(planRemoteDatasourceProvider),
    logger: ref.watch(loggerProvider),
  );
}

/// Provider for the current user's active plan.
///
/// This is the primary data source for displaying plans in the UI.
/// Implements offline-first strategy via the repository.
///
/// Returns:
/// - WeeklyPlan if user has an active plan
/// - null if no plan exists (show "Generate Plan" prompt)
///
/// Auto-refreshes when:
/// - User ID changes (login/logout)
/// - Provider is invalidated after generation
///
/// Usage:
/// ```dart
/// final planAsync = ref.watch(currentPlanProvider);
/// planAsync.when(
///   data: (plan) => plan != null ? PlanView(plan) : GeneratePlanPrompt(),
///   loading: () => PlanSkeletonLoader(),
///   error: (e, st) => ErrorDisplay(error: e),
/// );
/// ```
@riverpod
Future<WeeklyPlan?> currentPlan(CurrentPlanRef ref) async {
  // Get current user ID
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    // Not authenticated - no plan to show
    return null;
  }

  // Fetch plan from repository (offline-first)
  final repository = ref.watch(planRepositoryProvider);
  return await repository.getCurrentPlan(userId);
}

/// Provider for today's plan.
///
/// Derived from currentPlanProvider, extracts just today's DayPlan.
/// Returns null if no current plan or today is not in the plan week.
///
/// This is the most commonly used provider for dashboard display.
///
/// Usage:
/// ```dart
/// final todayAsync = ref.watch(todaysPlanProvider);
/// todayAsync.when(
///   data: (today) => today != null ? TodayView(today) : NoPlaneView(),
///   loading: () => SkeletonLoader(),
///   error: (e, st) => ErrorDisplay(error: e),
/// );
/// ```
@riverpod
Future<DayPlan?> todaysPlan(TodaysPlanRef ref) async {
  final plan = await ref.watch(currentPlanProvider.future);

  if (plan == null) {
    return null;
  }

  // Get today's DayPlan from the weekly plan
  return plan.today;
}

/// Provider for plan generation action.
///
/// Triggers plan generation for the current user.
/// Invalidates currentPlanProvider after successful generation.
///
/// Parameters:
/// - Uses current user's profile from onboarding providers
/// - Auto-fetches user ID from auth providers
///
/// Returns: Newly generated WeeklyPlan
///
/// Throws:
/// - [AiException] if generation fails
/// - [StateError] if user not authenticated or profile incomplete
///
/// Usage:
/// ```dart
/// // Trigger generation
/// final generateFuture = ref.read(generatePlanProvider.future);
///
/// // Or with error handling
/// try {
///   final plan = await ref.read(generatePlanProvider.future);
///   // Navigate to dashboard
/// } on AiException catch (e) {
///   // Show error
/// }
/// ```
@riverpod
Future<WeeklyPlan> generatePlan(GeneratePlanRef ref) async {
  // Get current user ID
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    throw StateError('User must be authenticated to generate plan');
  }

  // Get user profile from onboarding
  final profile = await ref.watch(userProfileProvider.future);

  if (profile == null) {
    throw StateError('User profile not found. Complete onboarding first.');
  }

  // Generate plan via repository
  final repository = ref.watch(planRepositoryProvider);
  final plan = await repository.generatePlan(profile);

  // Invalidate current plan provider to trigger refresh
  ref.invalidate(currentPlanProvider);

  return plan;
}

/// Provider for checking if a plan is currently being generated.
///
/// Returns true while generatePlanProvider is loading.
/// Useful for showing loading states in UI.
///
/// Usage:
/// ```dart
/// final isGenerating = ref.watch(isGeneratingPlanProvider);
/// if (isGenerating) {
///   return GenerationAnimation();
/// }
/// ```
@riverpod
bool isGeneratingPlan(IsGeneratingPlanRef ref) {
  final generateState = ref.watch(generatePlanProvider);
  return generateState.isLoading;
}

/// Provider for plan generation error.
///
/// Returns the error from generatePlanProvider if generation failed.
/// Returns null if no error or not attempted.
///
/// Usage:
/// ```dart
/// final error = ref.watch(planGenerationErrorProvider);
/// if (error != null) {
///   return ErrorDisplay(error: error);
/// }
/// ```
@riverpod
Object? planGenerationError(PlanGenerationErrorRef ref) {
  final generateState = ref.watch(generatePlanProvider);
  return generateState.error;
}

/// Provider for plan modification action.
///
/// Modifies the current plan based on a natural language request.
/// Invalidates currentPlanProvider after successful modification.
///
/// Parameters:
/// - [modificationRequest]: Natural language modification request
///
/// Returns: Modified WeeklyPlan
///
/// Throws:
/// - [AiException] if modification fails
/// - [StateError] if no current plan exists
///
/// Usage:
/// ```dart
/// final modifiedPlan = await ref.read(
///   modifyPlanProvider('Make Tuesday vegetarian').future,
/// );
/// ```
@riverpod
Future<WeeklyPlan> modifyPlan(
  ModifyPlanRef ref,
  String modificationRequest,
) async {
  // Get current user ID
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    throw StateError('User must be authenticated to modify plan');
  }

  // Modify plan via repository
  final repository = ref.watch(planRepositoryProvider);
  final modifiedPlan = await repository.modifyPlan(userId, modificationRequest);

  // Invalidate current plan provider to trigger refresh
  ref.invalidate(currentPlanProvider);

  return modifiedPlan;
}

/// Provider for marking an exercise as complete.
///
/// Updates the completion status of a specific exercise.
/// Invalidates currentPlanProvider to trigger UI update.
///
/// Parameters:
/// - [planId]: ID of the plan
/// - [dayIndex]: Index of the day (0-6)
/// - [exerciseIndex]: Index of the exercise
/// - [isComplete]: Completion status
///
/// Returns: Updated WeeklyPlan
///
/// Usage:
/// ```dart
/// await ref.read(
///   markExerciseCompleteProvider(
///     planId: 'plan_123',
///     dayIndex: 0,
///     exerciseIndex: 2,
///     isComplete: true,
///   ).future,
/// );
/// ```
@riverpod
Future<WeeklyPlan?> markExerciseComplete(
  MarkExerciseCompleteRef ref, {
  required String planId,
  required int dayIndex,
  required int exerciseIndex,
  bool isComplete = true,
}) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final repository = ref.watch(planRepositoryProvider);
  final updatedPlan = await repository.markExerciseComplete(
    userId,
    planId,
    dayIndex,
    exerciseIndex,
    isComplete: isComplete,
  );

  // Invalidate to refresh UI
  ref.invalidate(currentPlanProvider);

  return updatedPlan;
}

/// Provider for marking a meal as complete.
///
/// Updates the completion status of a specific meal.
/// Invalidates currentPlanProvider to trigger UI update.
///
/// Parameters:
/// - [planId]: ID of the plan
/// - [dayIndex]: Index of the day (0-6)
/// - [mealIndex]: Index of the meal
/// - [isComplete]: Completion status
///
/// Returns: Updated WeeklyPlan
///
/// Usage:
/// ```dart
/// await ref.read(
///   markMealCompleteProvider(
///     planId: 'plan_123',
///     dayIndex: 0,
///     mealIndex: 0,
///     isComplete: true,
///   ).future,
/// );
/// ```
@riverpod
Future<WeeklyPlan?> markMealComplete(
  MarkMealCompleteRef ref, {
  required String planId,
  required int dayIndex,
  required int mealIndex,
  bool isComplete = true,
}) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final repository = ref.watch(planRepositoryProvider);
  final updatedPlan = await repository.markMealComplete(
    userId,
    planId,
    dayIndex,
    mealIndex,
    isComplete: isComplete,
  );

  // Invalidate to refresh UI
  ref.invalidate(currentPlanProvider);

  return updatedPlan;
}

/// Provider for checking if user has an active plan.
///
/// Lightweight check that doesn't load the full plan.
/// Useful for routing decisions and conditional UI.
///
/// Usage:
/// ```dart
/// final hasPlaneAsync = ref.watch(hasActivePlanProvider);
/// hasPlaneAsync.when(
///   data: (hasPlan) => hasPlan ? DashboardScreen() : GeneratePlanScreen(),
///   loading: () => SplashScreen(),
///   error: (e, st) => ErrorScreen(),
/// );
/// ```
@riverpod
Future<bool> hasActivePlan(HasActivePlanRef ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return false;

  final repository = ref.watch(planRepositoryProvider);
  return await repository.hasActivePlan(userId);
}

/// Provider for syncing local plan to Firestore.
///
/// Forces synchronization of locally cached plan to remote.
/// Useful after offline operations or before critical operations.
///
/// Returns: true if sync successful, false otherwise
///
/// Usage:
/// ```dart
/// final syncSuccess = await ref.read(syncPlanProvider.future);
/// if (syncSuccess) {
///   print('Plan synced successfully');
/// }
/// ```
@riverpod
Future<bool> syncPlan(SyncPlanRef ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return false;

  final repository = ref.watch(planRepositoryProvider);
  return await repository.syncPlan(userId);
}

/// Provider for plan by specific ID.
///
/// Retrieves a plan by its unique ID, not necessarily the active plan.
/// Useful for viewing plan history or archived plans.
///
/// Parameters:
/// - [planId]: ID of the plan to retrieve
///
/// Returns: WeeklyPlan if found, null otherwise
///
/// Usage:
/// ```dart
/// final planAsync = ref.watch(planByIdProvider('plan_123'));
/// ```
@riverpod
Future<WeeklyPlan?> planById(PlanByIdRef ref, String planId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final repository = ref.watch(planRepositoryProvider);
  return await repository.getPlanById(userId, planId);
}
