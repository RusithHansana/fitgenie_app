import 'package:fitgenie_app/shared/services/hive_service.dart';
import 'package:fitgenie_app/features/plan_generation/domain/weekly_plan.dart';

/// Local data source for plan storage using Hive.
///
/// Manages offline storage of WeeklyPlan objects in Hive for:
/// - 100% offline plan access (architecture requirement)
/// - Fast local reads without network latency
/// - Offline-first data strategy
/// - Cache invalidation on new plan generation
///
/// Key Responsibilities:
/// - Save plans to Hive box as JSON
/// - Retrieve cached plans by user ID
/// - Check cache existence
/// - Delete cached plans
/// - Handle missing data gracefully
///
/// Storage Strategy:
/// - Key format: `plan_{userId}` (one active plan per user)
/// - Value format: JSON Map (flexible, no TypeAdapter needed yet)
/// - Box: HiveService.weeklyPlanBox
/// - Persistence: Automatic via Hive
///
/// Usage:
/// ```dart
/// final datasource = PlanLocalDatasource();
///
/// // Save plan
/// await datasource.savePlan(userId, weeklyPlan);
///
/// // Retrieve plan
/// final plan = await datasource.getPlan(userId);
///
/// // Check cache
/// final hasPlan = await datasource.hasCachedPlan(userId);
///
/// // Delete cache
/// await datasource.deletePlan(userId);
/// ```
///
/// Architecture Notes:
/// - Used by PlanRepository as cache layer
/// - Synchronous operations wrapped in async for consistency
/// - No network dependency
/// - Returns null for missing data (no exceptions)
class PlanLocalDatasource {
  /// Creates a PlanLocalDatasource instance.
  ///
  /// Accesses the Hive box through HiveService static getter.
  const PlanLocalDatasource();

  /// Generates the Hive storage key for a user's plan.
  ///
  /// Format: `plan_{userId}`
  ///
  /// This ensures each user has a unique storage key and prevents
  /// data collision between users.
  String _getPlanKey(String userId) => 'plan_$userId';

  /// Saves a weekly plan to local storage.
  ///
  /// Stores the plan as JSON in the Hive box. Overwrites any existing
  /// plan for the user.
  ///
  /// Parameters:
  /// - [userId]: ID of the user who owns the plan
  /// - [plan]: WeeklyPlan to save
  ///
  /// Returns: Future that completes when save is done
  ///
  /// Example:
  /// ```dart
  /// await datasource.savePlan('user_123', weeklyPlan);
  /// ```
  Future<void> savePlan(String userId, WeeklyPlan plan) async {
    try {
      final box = HiveService.weeklyPlanBox;
      final key = _getPlanKey(userId);

      // Convert plan to JSON for storage
      final planJson = plan.toJson();

      // Save to Hive
      await box.put(key, planJson);
    } catch (e) {
      // Log error but don't throw - local storage failures shouldn't
      // break the app since we have remote fallback
      print('Error saving plan to local storage: $e');
    }
  }

  /// Retrieves a cached weekly plan from local storage.
  ///
  /// Returns the plan if it exists in cache, or null if:
  /// - No plan cached for this user
  /// - Plan data is corrupted
  /// - Deserialization fails
  ///
  /// Parameters:
  /// - [userId]: ID of the user whose plan to retrieve
  ///
  /// Returns: WeeklyPlan if cached, null otherwise
  ///
  /// Example:
  /// ```dart
  /// final plan = await datasource.getPlan('user_123');
  /// if (plan != null) {
  ///   print('Loaded cached plan: ${plan.dateRangeDisplay}');
  /// }
  /// ```
  Future<WeeklyPlan?> getPlan(String userId) async {
    try {
      final box = HiveService.weeklyPlanBox;
      final key = _getPlanKey(userId);

      // Get data from Hive
      final planData = box.get(key);

      if (planData == null) {
        return null;
      }

      // Convert to Map<String, dynamic>
      final planJson = Map<String, dynamic>.from(planData);

      // Deserialize to WeeklyPlan
      return WeeklyPlan.fromJson(planJson);
    } catch (e) {
      // Log error and return null - don't throw
      print('Error reading plan from local storage: $e');
      return null;
    }
  }

  /// Checks if a cached plan exists for the user.
  ///
  /// Lightweight check that doesn't deserialize the plan data.
  ///
  /// Parameters:
  /// - [userId]: ID of the user to check
  ///
  /// Returns: true if cached plan exists, false otherwise
  ///
  /// Example:
  /// ```dart
  /// if (await datasource.hasCachedPlan('user_123')) {
  ///   print('Plan available offline');
  /// }
  /// ```
  Future<bool> hasCachedPlan(String userId) async {
    try {
      final box = HiveService.weeklyPlanBox;
      final key = _getPlanKey(userId);
      return box.containsKey(key);
    } catch (e) {
      print('Error checking plan cache: $e');
      return false;
    }
  }

  /// Deletes the cached plan for a user.
  ///
  /// Used when:
  /// - User generates a new plan (old one archived)
  /// - User logs out
  /// - Cache needs to be cleared
  ///
  /// Parameters:
  /// - [userId]: ID of the user whose plan to delete
  ///
  /// Returns: Future that completes when deletion is done
  ///
  /// Example:
  /// ```dart
  /// await datasource.deletePlan('user_123');
  /// ```
  Future<void> deletePlan(String userId) async {
    try {
      final box = HiveService.weeklyPlanBox;
      final key = _getPlanKey(userId);
      await box.delete(key);
    } catch (e) {
      print('Error deleting plan from local storage: $e');
    }
  }

  /// Clears all cached plans from local storage.
  ///
  /// Used for:
  /// - App data reset
  /// - Testing
  /// - Storage cleanup
  ///
  /// WARNING: This deletes ALL users' cached plans, not just one user.
  ///
  /// Returns: Future that completes when clear is done
  ///
  /// Example:
  /// ```dart
  /// await datasource.clearAllPlans();
  /// ```
  Future<void> clearAllPlans() async {
    try {
      final box = HiveService.weeklyPlanBox;

      // Get all keys that start with 'plan_'
      final planKeys = box.keys.where(
        (key) => key.toString().startsWith('plan_'),
      );

      // Delete each plan key
      for (final key in planKeys) {
        await box.delete(key);
      }
    } catch (e) {
      print('Error clearing all plans from local storage: $e');
    }
  }

  /// Gets the cached plan's age in days.
  ///
  /// Returns the number of days since the plan was generated,
  /// or null if no plan is cached or plan lacks createdAt timestamp.
  ///
  /// Useful for determining if cached plan is stale.
  ///
  /// Parameters:
  /// - [userId]: ID of the user whose plan to check
  ///
  /// Returns: Age in days, or null if not available
  ///
  /// Example:
  /// ```dart
  /// final age = await datasource.getCachedPlanAge('user_123');
  /// if (age != null && age > 7) {
  ///   print('Cached plan is stale, consider regenerating');
  /// }
  /// ```
  Future<int?> getCachedPlanAge(String userId) async {
    try {
      final plan = await getPlan(userId);
      if (plan == null) {
        return null;
      }

      final now = DateTime.now();
      final age = now.difference(plan.createdAt).inDays;
      return age;
    } catch (e) {
      print('Error getting cached plan age: $e');
      return null;
    }
  }

  /// Gets metadata about the cached plan without loading full plan.
  ///
  /// Returns basic info like ID, creation date, and start date
  /// without deserializing the entire plan structure.
  ///
  /// Parameters:
  /// - [userId]: ID of the user whose plan metadata to get
  ///
  /// Returns: Map with metadata fields, or null if no plan cached
  ///
  /// Example:
  /// ```dart
  /// final metadata = await datasource.getPlanMetadata('user_123');
  /// if (metadata != null) {
  ///   print('Plan ID: ${metadata['id']}');
  ///   print('Created: ${metadata['createdAt']}');
  /// }
  /// ```
  Future<Map<String, dynamic>?> getPlanMetadata(String userId) async {
    try {
      final box = HiveService.weeklyPlanBox;
      final key = _getPlanKey(userId);

      final planData = box.get(key);
      if (planData == null) {
        return null;
      }

      final planJson = Map<String, dynamic>.from(planData);

      // Extract just metadata fields
      return {
        'id': planJson['id'],
        'userId': planJson['userId'],
        'createdAt': planJson['createdAt'],
        'startDate': planJson['startDate'],
      };
    } catch (e) {
      print('Error getting plan metadata: $e');
      return null;
    }
  }
}
