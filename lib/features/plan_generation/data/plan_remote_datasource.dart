import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitgenie_app/core/exceptions/network_exception.dart';
import 'package:fitgenie_app/core/exceptions/sync_exception.dart';
import 'package:fitgenie_app/features/plan_generation/domain/weekly_plan.dart';

/// Remote data source for plan storage using Cloud Firestore.
///
/// Manages cloud storage of WeeklyPlan objects in Firestore for:
/// - Cross-device synchronization
/// - Data persistence and backup
/// - Remote access when offline cache unavailable
/// - Plan history and archiving
///
/// Key Responsibilities:
/// - Save plans to Firestore with server timestamps
/// - Retrieve plans by user ID and plan ID
/// - Update plan completion status
/// - Delete archived plans
/// - Handle Firestore errors gracefully
///
/// Storage Structure:
/// - Path: `/users/{userId}/plans/{planId}`
/// - One active plan per user (isActive: true)
/// - Historical plans archived (isActive: false)
/// - Server-side timestamps for consistency
///
/// Usage:
/// ```dart
/// final datasource = PlanRemoteDatasource(firestore);
///
/// // Save new plan
/// await datasource.savePlan(userId, weeklyPlan);
///
/// // Get active plan
/// final plan = await datasource.getActivePlan(userId);
///
/// // Update completion
/// await datasource.updateCompletion(userId, planId, updates);
///
/// // Archive old plan
/// await datasource.archivePlan(userId, planId);
/// ```
///
/// Architecture Notes:
/// - Used by PlanRepository for remote operations
/// - All operations are async (network dependent)
/// - Throws exceptions for errors (caught by repository)
/// - Security: Firestore rules enforce user-scoped access
class PlanRemoteDatasource {
  /// Creates a PlanRemoteDatasource with a Firestore instance.
  ///
  /// Parameters:
  /// - [firestore]: Cloud Firestore instance from firebase_providers
  const PlanRemoteDatasource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  /// The Firestore instance for database operations.
  final FirebaseFirestore _firestore;

  /// Gets the collection reference for a user's plans.
  ///
  /// Path: `/users/{userId}/plans`
  CollectionReference _getPlansCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('plans');
  }

  /// Gets the document reference for a specific plan.
  ///
  /// Path: `/users/{userId}/plans/{planId}`
  DocumentReference _getPlanDocument(String userId, String planId) {
    return _getPlansCollection(userId).doc(planId);
  }

  /// Saves a weekly plan to Firestore.
  ///
  /// This operation:
  /// 1. Archives any existing active plan for the user
  /// 2. Saves the new plan with isActive: true
  /// 3. Adds server timestamp for createdAt if not present
  ///
  /// Parameters:
  /// - [userId]: ID of the user who owns the plan
  /// - [plan]: WeeklyPlan to save
  ///
  /// Throws:
  /// - [NetworkException] for connectivity/Firestore errors
  /// - [SyncException] for permission or data sync errors
  ///
  /// Example:
  /// ```dart
  /// await datasource.savePlan('user_123', weeklyPlan);
  /// ```
  Future<void> savePlan(String userId, WeeklyPlan plan) async {
    final batch = _firestore.batch();

    try {
      // First, archive any existing active plans
      final existingPlans = await _getPlansCollection(
        userId,
      ).where('isActive', isEqualTo: true).get();

      for (final doc in existingPlans.docs) {
        batch.update(doc.reference, {'isActive': false});
      }

      // Prepare plan data
      final planData = plan.toFirestore();
      planData['isActive'] = true;
      planData['updatedAt'] = FieldValue.serverTimestamp();

      // If createdAt is missing or future dated, use server timestamp
      if (!planData.containsKey('createdAt')) {
        planData['createdAt'] = FieldValue.serverTimestamp();
      }

      // Save new plan
      final planRef = _getPlanDocument(userId, plan.id);
      batch.set(planRef, planData);

      // Commit batch
      await batch.commit();
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        throw NetworkException(
          NetworkErrorType.noConnection,
          'Firestore unavailable: ${e.message}',
        );
      } else if (e.code == 'permission-denied') {
        throw SyncException(
          SyncErrorType.permissionDenied,
          'Permission denied saving plan: ${e.message}',
        );
      }
      throw NetworkException(
        NetworkErrorType.serverError,
        'Firestore error saving plan: ${e.message}',
      );
    } on SocketException catch (e) {
      throw NetworkException(
        NetworkErrorType.noConnection,
        'No internet connection: ${e.message}',
      );
    } on TimeoutException {
      throw const NetworkException(
        NetworkErrorType.timeout,
        'Request timed out while saving plan',
      );
    } catch (e) {
      throw SyncException(
        SyncErrorType.syncFailed,
        'Failed to save plan to Firestore: $e',
      );
    }
  }

  /// Retrieves the active weekly plan for a user.
  ///
  /// Returns the most recently created active plan, or null if no active
  /// plan exists.
  ///
  /// Parameters:
  /// - [userId]: ID of the user whose plan to retrieve
  ///
  /// Returns: WeeklyPlan if active plan exists, null otherwise
  ///
  /// Throws:
  /// - [NetworkException] for connectivity/Firestore errors
  /// - [SyncException] for permission or data sync errors
  ///
  /// Example:
  /// ```dart
  /// final plan = await datasource.getActivePlan('user_123');
  /// if (plan != null) {
  ///   print('Active plan: ${plan.dateRangeDisplay}');
  /// }
  /// ```
  Future<WeeklyPlan?> getActivePlan(String userId) async {
    try {
      final querySnapshot = await _getPlansCollection(userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final planData = querySnapshot.docs.first.data() as Map<String, dynamic>;
      return WeeklyPlan.fromFirestore(planData);
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        throw NetworkException(
          NetworkErrorType.noConnection,
          'Firestore unavailable: ${e.message}',
        );
      } else if (e.code == 'permission-denied') {
        throw SyncException(
          SyncErrorType.permissionDenied,
          'Permission denied reading plan: ${e.message}',
        );
      }
      throw NetworkException(
        NetworkErrorType.serverError,
        'Firestore error reading active plan: ${e.message}',
      );
    } on SocketException catch (e) {
      throw NetworkException(
        NetworkErrorType.noConnection,
        'No internet connection: ${e.message}',
      );
    } on TimeoutException {
      throw const NetworkException(
        NetworkErrorType.timeout,
        'Request timed out while reading plan',
      );
    } catch (e) {
      throw SyncException(
        SyncErrorType.syncFailed,
        'Failed to get active plan from Firestore: $e',
      );
    }
  }

  /// Retrieves a specific plan by ID.
  ///
  /// Parameters:
  /// - [userId]: ID of the user who owns the plan
  /// - [planId]: ID of the plan to retrieve
  ///
  /// Returns: WeeklyPlan if found, null otherwise
  ///
  /// Throws:
  /// - [NetworkException] for connectivity/Firestore errors
  /// - [SyncException] for permission or data sync errors
  ///
  /// Example:
  /// ```dart
  /// final plan = await datasource.getPlanById('user_123', 'plan_456');
  /// ```
  Future<WeeklyPlan?> getPlanById(String userId, String planId) async {
    try {
      final docSnapshot = await _getPlanDocument(userId, planId).get();

      if (!docSnapshot.exists) {
        return null;
      }

      final planData = docSnapshot.data() as Map<String, dynamic>;
      return WeeklyPlan.fromFirestore(planData);
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        throw NetworkException(
          NetworkErrorType.noConnection,
          'Firestore unavailable: ${e.message}',
        );
      } else if (e.code == 'permission-denied') {
        throw SyncException(
          SyncErrorType.permissionDenied,
          'Permission denied reading plan: ${e.message}',
        );
      }
      throw NetworkException(
        NetworkErrorType.serverError,
        'Firestore error reading plan: ${e.message}',
      );
    } on SocketException catch (e) {
      throw NetworkException(
        NetworkErrorType.noConnection,
        'No internet connection: ${e.message}',
      );
    } on TimeoutException {
      throw const NetworkException(
        NetworkErrorType.timeout,
        'Request timed out while reading plan',
      );
    } catch (e) {
      throw SyncException(
        SyncErrorType.syncFailed,
        'Failed to get plan from Firestore: $e',
      );
    }
  }

  /// Updates task completion status for exercises or meals.
  ///
  /// Performs a partial update using Firestore field paths to update
  /// specific nested fields without rewriting the entire document.
  ///
  /// Parameters:
  /// - [userId]: ID of the user who owns the plan
  /// - [planId]: ID of the plan to update
  /// - [updates]: Map of field paths to new values
  ///
  /// Example updates map:
  /// ```dart
  /// {
  ///   'days.0.workout.exercises.0.isComplete': true,
  ///   'days.0.meals.0.isComplete': true,
  /// }
  /// ```
  ///
  /// Throws:
  /// - [NetworkException] for connectivity/Firestore errors
  /// - [SyncException] for permission or data sync errors
  ///
  /// Example:
  /// ```dart
  /// await datasource.updateCompletion('user_123', 'plan_456', {
  ///   'days.0.workout.exercises.0.isComplete': true,
  /// });
  /// ```
  Future<void> updateCompletion(
    String userId,
    String planId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final planRef = _getPlanDocument(userId, planId);

      // Add updatedAt timestamp
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await planRef.update(updates);
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        throw NetworkException(
          NetworkErrorType.noConnection,
          'Firestore unavailable: ${e.message}',
        );
      } else if (e.code == 'permission-denied') {
        throw SyncException(
          SyncErrorType.permissionDenied,
          'Permission denied updating plan: ${e.message}',
        );
      } else if (e.code == 'not-found') {
        throw NetworkException(
          NetworkErrorType.notFound,
          'Plan not found: ${e.message}',
        );
      }
      throw NetworkException(
        NetworkErrorType.serverError,
        'Firestore error updating completion: ${e.message}',
      );
    } on SocketException catch (e) {
      throw NetworkException(
        NetworkErrorType.noConnection,
        'No internet connection: ${e.message}',
      );
    } on TimeoutException {
      throw const NetworkException(
        NetworkErrorType.timeout,
        'Request timed out while updating plan',
      );
    } catch (e) {
      throw SyncException(
        SyncErrorType.syncFailed,
        'Failed to update plan completion in Firestore: $e',
      );
    }
  }

  /// Archives a plan by setting isActive to false.
  ///
  /// Archived plans remain in Firestore for history but are not
  /// returned by getActivePlan().
  ///
  /// Parameters:
  /// - [userId]: ID of the user who owns the plan
  /// - [planId]: ID of the plan to archive
  ///
  /// Throws:
  /// - [NetworkException] for connectivity/Firestore errors
  /// - [SyncException] for permission or data sync errors
  ///
  /// Example:
  /// ```dart
  /// await datasource.archivePlan('user_123', 'plan_456');
  /// ```
  Future<void> archivePlan(String userId, String planId) async {
    try {
      await _getPlanDocument(
        userId,
        planId,
      ).update({'isActive': false, 'archivedAt': FieldValue.serverTimestamp()});
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        throw NetworkException(
          NetworkErrorType.noConnection,
          'Firestore unavailable: ${e.message}',
        );
      } else if (e.code == 'permission-denied') {
        throw SyncException(
          SyncErrorType.permissionDenied,
          'Permission denied archiving plan: ${e.message}',
        );
      } else if (e.code == 'not-found') {
        throw NetworkException(
          NetworkErrorType.notFound,
          'Plan not found: ${e.message}',
        );
      }
      throw NetworkException(
        NetworkErrorType.serverError,
        'Firestore error archiving plan: ${e.message}',
      );
    } on SocketException catch (e) {
      throw NetworkException(
        NetworkErrorType.noConnection,
        'No internet connection: ${e.message}',
      );
    } on TimeoutException {
      throw const NetworkException(
        NetworkErrorType.timeout,
        'Request timed out while archiving plan',
      );
    } catch (e) {
      throw SyncException(
        SyncErrorType.syncFailed,
        'Failed to archive plan in Firestore: $e',
      );
    }
  }

  /// Deletes a plan from Firestore.
  ///
  /// WARNING: This permanently deletes the plan. Consider archiving instead.
  ///
  /// Parameters:
  /// - [userId]: ID of the user who owns the plan
  /// - [planId]: ID of the plan to delete
  ///
  /// Throws:
  /// - [NetworkException] for connectivity/Firestore errors
  /// - [SyncException] for permission or data sync errors
  ///
  /// Example:
  /// ```dart
  /// await datasource.deletePlan('user_123', 'plan_456');
  /// ```
  Future<void> deletePlan(String userId, String planId) async {
    try {
      await _getPlanDocument(userId, planId).delete();
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        throw NetworkException(
          NetworkErrorType.noConnection,
          'Firestore unavailable: ${e.message}',
        );
      } else if (e.code == 'permission-denied') {
        throw SyncException(
          SyncErrorType.permissionDenied,
          'Permission denied deleting plan: ${e.message}',
        );
      }
      throw NetworkException(
        NetworkErrorType.serverError,
        'Firestore error deleting plan: ${e.message}',
      );
    } on SocketException catch (e) {
      throw NetworkException(
        NetworkErrorType.noConnection,
        'No internet connection: ${e.message}',
      );
    } on TimeoutException {
      throw const NetworkException(
        NetworkErrorType.timeout,
        'Request timed out while deleting plan',
      );
    } catch (e) {
      throw SyncException(
        SyncErrorType.syncFailed,
        'Failed to delete plan from Firestore: $e',
      );
    }
  }

  /// Gets all plans for a user (active and archived).
  ///
  /// Returns plans ordered by creation date (newest first).
  /// Useful for plan history view.
  ///
  /// Parameters:
  /// - [userId]: ID of the user whose plans to retrieve
  /// - [limit]: Maximum number of plans to return (default: 10)
  ///
  /// Returns: List of WeeklyPlan objects
  ///
  /// Throws:
  /// - [NetworkException] for connectivity/Firestore errors
  /// - [SyncException] for permission or data sync errors
  ///
  /// Example:
  /// ```dart
  /// final plans = await datasource.getAllPlans('user_123', limit: 5);
  /// print('Found ${plans.length} plans');
  /// ```
  Future<List<WeeklyPlan>> getAllPlans(String userId, {int limit = 10}) async {
    try {
      final querySnapshot = await _getPlansCollection(
        userId,
      ).orderBy('createdAt', descending: true).limit(limit).get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return WeeklyPlan.fromFirestore(data);
      }).toList();
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        throw NetworkException(
          NetworkErrorType.noConnection,
          'Firestore unavailable: ${e.message}',
        );
      } else if (e.code == 'permission-denied') {
        throw SyncException(
          SyncErrorType.permissionDenied,
          'Permission denied reading plans: ${e.message}',
        );
      }
      throw NetworkException(
        NetworkErrorType.serverError,
        'Firestore error reading plans: ${e.message}',
      );
    } on SocketException catch (e) {
      throw NetworkException(
        NetworkErrorType.noConnection,
        'No internet connection: ${e.message}',
      );
    } on TimeoutException {
      throw const NetworkException(
        NetworkErrorType.timeout,
        'Request timed out while reading plans',
      );
    } catch (e) {
      throw SyncException(
        SyncErrorType.syncFailed,
        'Failed to get all plans from Firestore: $e',
      );
    }
  }

  /// Checks if a user has an active plan in Firestore.
  ///
  /// Lightweight check that doesn't fetch the full plan data.
  ///
  /// Parameters:
  /// - [userId]: ID of the user to check
  ///
  /// Returns: true if active plan exists, false otherwise
  ///
  /// Throws:
  /// - [NetworkException] for connectivity/Firestore errors
  /// - [SyncException] for permission or data sync errors
  ///
  /// Example:
  /// ```dart
  /// if (await datasource.hasActivePlan('user_123')) {
  ///   print('User has an active plan');
  /// }
  /// ```
  Future<bool> hasActivePlan(String userId) async {
    try {
      final querySnapshot = await _getPlansCollection(
        userId,
      ).where('isActive', isEqualTo: true).limit(1).get();

      return querySnapshot.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        throw NetworkException(
          NetworkErrorType.noConnection,
          'Firestore unavailable: ${e.message}',
        );
      } else if (e.code == 'permission-denied') {
        throw SyncException(
          SyncErrorType.permissionDenied,
          'Permission denied checking plan: ${e.message}',
        );
      }
      throw NetworkException(
        NetworkErrorType.serverError,
        'Firestore error checking plan: ${e.message}',
      );
    } on SocketException catch (e) {
      throw NetworkException(
        NetworkErrorType.noConnection,
        'No internet connection: ${e.message}',
      );
    } on TimeoutException {
      throw const NetworkException(
        NetworkErrorType.timeout,
        'Request timed out while checking plan',
      );
    } catch (e) {
      throw SyncException(
        SyncErrorType.syncFailed,
        'Failed to check for active plan in Firestore: $e',
      );
    }
  }

  /// Streams the active plan for real-time updates.
  ///
  /// Returns a stream that emits whenever the active plan changes
  /// in Firestore. Useful for live dashboard updates.
  ///
  /// Parameters:
  /// - [userId]: ID of the user whose plan to stream
  ///
  /// Returns: Stream of WeeklyPlan (may emit null if no active plan)
  ///
  /// Example:
  /// ```dart
  /// datasource.streamActivePlan('user_123').listen((plan) {
  ///   if (plan != null) {
  ///     print('Plan updated: ${plan.weeklyCompletionPercentage}%');
  ///   }
  /// });
  /// ```
  Stream<WeeklyPlan?> streamActivePlan(String userId) {
    return _getPlansCollection(userId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return null;
          }
          final data = snapshot.docs.first.data() as Map<String, dynamic>;
          return WeeklyPlan.fromFirestore(data);
        });
  }
}
