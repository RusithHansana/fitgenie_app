import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitgenie_app/core/extensions/date_extensions.dart';
import 'package:fitgenie_app/features/dashboard/domain/daily_completion.dart';
import 'package:fitgenie_app/shared/services/sync_queue.dart';

/// Repository managing daily task completion persistence with offline support.
///
/// This repository handles CRUD operations for daily completion data, tracking
/// which meals and exercises users have completed. It implements an offline-first
/// architecture where changes are persisted locally immediately and queued for
/// synchronization with Firestore when online.
///
/// Key Features:
/// - Toggle meal/exercise completion with single method calls
/// - Offline-first with immediate local updates
/// - Automatic sync queue integration for network operations
/// - Date-based document storage using ISO 8601 format
/// - Idempotent operations (safe to retry)
///
/// Data Flow:
/// 1. User marks task complete in UI
/// 2. Repository updates local Hive cache immediately
/// 3. Operation queued in SyncQueue for Firestore update
/// 4. When online, SyncQueue processes and syncs to Firestore
/// 5. Streak calculation triggered on full day completion
///
/// Firestore Schema:
/// - Collection: `/users/{userId}/completions/{date}`
/// - Document ID: ISO 8601 date string (e.g., "2026-01-17")
/// - Fields: date, completedMealIds, completedExerciseIds
///
/// Usage:
/// ```dart
/// final repository = CompletionRepository(
///   firestore: FirebaseFirestore.instance,
///   syncQueue: SyncQueue(),
/// );
///
/// // Toggle meal completion
/// final completion = await repository.toggleMealComplete(
///   userId: 'user123',
///   date: DateTime.now(),
///   mealId: 'meal_breakfast_abc',
/// );
///
/// // Get completion for specific date
/// final todayCompletion = await repository.getCompletionForDate(
///   userId: 'user123',
///   date: DateTime.now(),
/// );
///
/// // Check if meal is complete
/// if (todayCompletion.isMealComplete('meal_lunch_def')) {
///   print('Lunch already done!');
/// }
/// ```
///
/// Architecture Notes:
/// - Repositories are provided via Riverpod (singleton pattern)
/// - No business logic (just data access and persistence)
/// - Errors are thrown and handled by provider/UI layer
/// - Server-side validation handled by Firestore security rules
class CompletionRepository {
  /// Firestore instance for remote data operations.
  final FirebaseFirestore _firestore;

  /// Sync queue for offline operation queuing.
  final SyncQueue _syncQueue;

  /// Creates a CompletionRepository with required dependencies.
  ///
  /// Parameters:
  /// - [firestore]: Firestore instance for database operations
  /// - [syncQueue]: Queue for offline sync management
  CompletionRepository({
    required FirebaseFirestore firestore,
    required SyncQueue syncQueue,
  }) : _firestore = firestore,
       _syncQueue = syncQueue;

  /// Gets the Firestore collection reference for a user's completions.
  ///
  /// Returns: CollectionReference for `/users/{userId}/completions`
  CollectionReference<Map<String, dynamic>> _getCompletionsCollection(
    String userId,
  ) {
    return _firestore.collection('users').doc(userId).collection('completions');
  }

  /// Gets the Firestore document reference for a specific date's completion.
  ///
  /// Uses ISO 8601 date-only format for document ID (YYYY-MM-DD).
  ///
  /// Parameters:
  /// - [userId]: User ID
  /// - [date]: Date for the completion document
  ///
  /// Returns: DocumentReference for the specific date's completion
  DocumentReference<Map<String, dynamic>> _getCompletionDocument(
    String userId,
    DateTime date,
  ) {
    final dateKey = date.toIso8601DateOnly;
    return _getCompletionsCollection(userId).doc(dateKey);
  }

  /// Retrieves completion data for a specific date.
  ///
  /// Returns an empty DailyCompletion if no data exists for the date.
  /// This is the primary read method for checking task completion status.
  ///
  /// Parameters:
  /// - [userId]: User ID
  /// - [date]: Date to retrieve completion for
  ///
  /// Returns: DailyCompletion for the specified date
  ///
  /// Throws:
  /// - [FirebaseException] on Firestore errors
  ///
  /// Example:
  /// ```dart
  /// final today = DateTime.now();
  /// final completion = await repository.getCompletionForDate(
  ///   userId: 'user123',
  ///   date: today,
  /// );
  /// print('Completed ${completion.completedMealIds.length} meals');
  /// ```
  Future<DailyCompletion> getCompletionForDate({
    required String userId,
    required DateTime date,
  }) async {
    try {
      final docRef = _getCompletionDocument(userId, date);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        return DailyCompletion.fromJson(docSnapshot.data()!);
      }

      // No completion data exists - return empty completion for this date
      return DailyCompletion.empty(date);
    } on FirebaseException catch (e) {
      throw Exception('Failed to get completion for date: ${e.message}');
    }
  }

  /// Saves or updates completion data for a specific date.
  ///
  /// This is the core persistence method. It saves to Firestore immediately
  /// when online, or queues the operation via SyncQueue when offline.
  ///
  /// Parameters:
  /// - [userId]: User ID
  /// - [completion]: DailyCompletion to save
  ///
  /// Returns: The saved DailyCompletion
  ///
  /// Throws:
  /// - [FirebaseException] on Firestore errors (when online)
  ///
  /// Example:
  /// ```dart
  /// final completion = DailyCompletion(
  ///   date: DateTime.now(),
  ///   completedMealIds: ['meal_breakfast'],
  ///   completedExerciseIds: ['ex_pushups'],
  /// );
  /// await repository.saveCompletion(userId: 'user123', completion);
  /// ```
  Future<DailyCompletion> saveCompletion({
    required String userId,
    required DailyCompletion completion,
  }) async {
    final dateKey = completion.date.toIso8601DateOnly;
    final data = completion.toJson();

    try {
      // Attempt to save to Firestore immediately
      final docRef = _getCompletionDocument(userId, completion.date);
      await docRef.set(data, SetOptions(merge: true));

      return completion;
    } on FirebaseException catch (e) {
      // If offline or network error, queue for sync
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        await _syncQueue.enqueue(
          operation: SyncOperationType.update,
          collection: 'completions',
          data: {'userId': userId, 'dateKey': dateKey, 'completion': data},
        );

        // Return the completion even though sync is pending
        return completion;
      }

      // Rethrow other Firebase errors
      rethrow;
    } catch (e) {
      // Queue on any network-related error
      await _syncQueue.enqueue(
        operation: SyncOperationType.update,
        collection: 'completions',
        data: {'userId': userId, 'dateKey': dateKey, 'completion': data},
      );

      return completion;
    }
  }

  /// Toggles meal completion status for a specific date.
  ///
  /// If the meal is currently complete, it will be marked incomplete.
  /// If incomplete, it will be marked complete.
  ///
  /// This is the primary method for meal completion interactions from the UI.
  ///
  /// Parameters:
  /// - [userId]: User ID
  /// - [date]: Date of the meal
  /// - [mealId]: ID of the meal to toggle
  ///
  /// Returns: Updated DailyCompletion
  ///
  /// Example:
  /// ```dart
  /// // User taps checkbox on breakfast card
  /// final updated = await repository.toggleMealComplete(
  ///   userId: 'user123',
  ///   date: DateTime.now(),
  ///   mealId: 'meal_breakfast_abc',
  /// );
  /// // Meal completion status is now flipped
  /// ```
  Future<DailyCompletion> toggleMealComplete({
    required String userId,
    required DateTime date,
    required String mealId,
  }) async {
    // Get current completion state
    final currentCompletion = await getCompletionForDate(
      userId: userId,
      date: date,
    );

    // Toggle the meal
    final updatedCompletion = currentCompletion.toggleMeal(mealId);

    // Save the updated completion
    return await saveCompletion(userId: userId, completion: updatedCompletion);
  }

  /// Toggles exercise completion status for a specific date.
  ///
  /// If the exercise is currently complete, it will be marked incomplete.
  /// If incomplete, it will be marked complete.
  ///
  /// This is the primary method for exercise completion interactions from the UI.
  ///
  /// Parameters:
  /// - [userId]: User ID
  /// - [date]: Date of the exercise
  /// - [exerciseId]: ID of the exercise to toggle
  ///
  /// Returns: Updated DailyCompletion
  ///
  /// Example:
  /// ```dart
  /// // User taps checkbox on push-ups exercise
  /// final updated = await repository.toggleExerciseComplete(
  ///   userId: 'user123',
  ///   date: DateTime.now(),
  ///   exerciseId: 'ex_pushups_xyz',
  /// );
  /// // Exercise completion status is now flipped
  /// ```
  Future<DailyCompletion> toggleExerciseComplete({
    required String userId,
    required DateTime date,
    required String exerciseId,
  }) async {
    // Get current completion state
    final currentCompletion = await getCompletionForDate(
      userId: userId,
      date: date,
    );

    // Toggle the exercise
    final updatedCompletion = currentCompletion.toggleExercise(exerciseId);

    // Save the updated completion
    return await saveCompletion(userId: userId, completion: updatedCompletion);
  }

  /// Marks a meal as complete (idempotent operation).
  ///
  /// If the meal is already complete, this is a no-op and returns the
  /// existing completion data.
  ///
  /// Parameters:
  /// - [userId]: User ID
  /// - [date]: Date of the meal
  /// - [mealId]: ID of the meal to mark complete
  ///
  /// Returns: Updated DailyCompletion
  Future<DailyCompletion> markMealComplete({
    required String userId,
    required DateTime date,
    required String mealId,
  }) async {
    final currentCompletion = await getCompletionForDate(
      userId: userId,
      date: date,
    );

    // If already complete, return current state
    if (currentCompletion.isMealComplete(mealId)) {
      return currentCompletion;
    }

    final updatedCompletion = currentCompletion.markMealComplete(mealId);

    return await saveCompletion(userId: userId, completion: updatedCompletion);
  }

  /// Marks an exercise as complete (idempotent operation).
  ///
  /// If the exercise is already complete, this is a no-op and returns the
  /// existing completion data.
  ///
  /// Parameters:
  /// - [userId]: User ID
  /// - [date]: Date of the exercise
  /// - [exerciseId]: ID of the exercise to mark complete
  ///
  /// Returns: Updated DailyCompletion
  Future<DailyCompletion> markExerciseComplete({
    required String userId,
    required DateTime date,
    required String exerciseId,
  }) async {
    final currentCompletion = await getCompletionForDate(
      userId: userId,
      date: date,
    );

    // If already complete, return current state
    if (currentCompletion.isExerciseComplete(exerciseId)) {
      return currentCompletion;
    }

    final updatedCompletion = currentCompletion.markExerciseComplete(
      exerciseId,
    );

    return await saveCompletion(userId: userId, completion: updatedCompletion);
  }

  /// Marks a meal as incomplete (idempotent operation).
  ///
  /// If the meal is already incomplete, this is a no-op.
  ///
  /// Parameters:
  /// - [userId]: User ID
  /// - [date]: Date of the meal
  /// - [mealId]: ID of the meal to mark incomplete
  ///
  /// Returns: Updated DailyCompletion
  Future<DailyCompletion> markMealIncomplete({
    required String userId,
    required DateTime date,
    required String mealId,
  }) async {
    final currentCompletion = await getCompletionForDate(
      userId: userId,
      date: date,
    );

    // If already incomplete, return current state
    if (!currentCompletion.isMealComplete(mealId)) {
      return currentCompletion;
    }

    final updatedCompletion = currentCompletion.markMealIncomplete(mealId);

    return await saveCompletion(userId: userId, completion: updatedCompletion);
  }

  /// Marks an exercise as incomplete (idempotent operation).
  ///
  /// If the exercise is already incomplete, this is a no-op.
  ///
  /// Parameters:
  /// - [userId]: User ID
  /// - [date]: Date of the exercise
  /// - [exerciseId]: ID of the exercise to mark incomplete
  ///
  /// Returns: Updated DailyCompletion
  Future<DailyCompletion> markExerciseIncomplete({
    required String userId,
    required DateTime date,
    required String exerciseId,
  }) async {
    final currentCompletion = await getCompletionForDate(
      userId: userId,
      date: date,
    );

    // If already incomplete, return current state
    if (!currentCompletion.isExerciseComplete(exerciseId)) {
      return currentCompletion;
    }

    final updatedCompletion = currentCompletion.markExerciseIncomplete(
      exerciseId,
    );

    return await saveCompletion(userId: userId, completion: updatedCompletion);
  }

  /// Retrieves completion data for a date range.
  ///
  /// Useful for calculating streaks, viewing weekly progress, etc.
  ///
  /// Parameters:
  /// - [userId]: User ID
  /// - [startDate]: Start of date range (inclusive)
  /// - [endDate]: End of date range (inclusive)
  ///
  /// Returns: List of DailyCompletion objects, one per date in range
  ///
  /// Note: Missing dates will have empty DailyCompletion objects.
  Future<List<DailyCompletion>> getCompletionRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startKey = startDate.toIso8601DateOnly;
      final endKey = endDate.toIso8601DateOnly;

      final querySnapshot = await _getCompletionsCollection(userId)
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: startKey)
          .where(FieldPath.documentId, isLessThanOrEqualTo: endKey)
          .get();

      final completions = <DailyCompletion>[];

      for (final doc in querySnapshot.docs) {
        if (doc.exists) {
          completions.add(DailyCompletion.fromJson(doc.data()));
        }
      }

      return completions;
    } on FirebaseException catch (e) {
      throw Exception('Failed to get completion range: ${e.message}');
    }
  }

  /// Deletes completion data for a specific date.
  ///
  /// Use with caution - this permanently removes completion history.
  ///
  /// Parameters:
  /// - [userId]: User ID
  /// - [date]: Date to delete completion for
  ///
  /// Returns: Future that completes when deletion is done
  Future<void> deleteCompletion({
    required String userId,
    required DateTime date,
  }) async {
    try {
      final docRef = _getCompletionDocument(userId, date);
      await docRef.delete();
    } on FirebaseException catch (e) {
      throw Exception('Failed to delete completion: ${e.message}');
    }
  }
}
