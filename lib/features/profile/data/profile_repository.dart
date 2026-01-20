import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitgenie_app/core/constants/app_strings.dart';
import 'package:fitgenie_app/core/exceptions/sync_exception.dart';
import 'package:fitgenie_app/features/onboarding/data/onboarding_repository.dart';
import 'package:fitgenie_app/features/onboarding/domain/user_profile.dart';
import 'package:fitgenie_app/features/profile/domain/user_stats.dart';

/// Repository for accessing and updating user profile data.
///
/// This repository provides a unified interface for profile operations,
/// delegating core profile persistence to [OnboardingRepository] while
/// adding profile-specific functionality like statistics retrieval and
/// account deletion.
///
/// Architecture:
/// - Wraps [OnboardingRepository] for profile CRUD operations
/// - Queries Firestore directly for aggregated statistics
/// - Follows offline-first patterns established in the codebase
///
/// Usage:
/// ```dart
/// final repository = ProfileRepository(
///   onboardingRepository: onboardingRepo,
///   firestore: FirebaseFirestore.instance,
/// );
///
/// // Get profile
/// final profile = await repository.getProfile(userId);
///
/// // Update profile
/// await repository.updateProfile(userId, updatedProfile);
///
/// // Get stats
/// final stats = await repository.getStats(userId);
/// ```
class ProfileRepository {
  final OnboardingRepository _onboardingRepository;
  final FirebaseFirestore _firestore;

  /// Firestore collection paths
  static const String _usersCollection = 'users';
  static const String _plansSubcollection = 'plans';
  static const String _completionsSubcollection = 'completions';

  ProfileRepository({
    required OnboardingRepository onboardingRepository,
    required FirebaseFirestore firestore,
  }) : _onboardingRepository = onboardingRepository,
       _firestore = firestore;

  /// Fetches the user profile for the given user ID.
  ///
  /// Delegates to [OnboardingRepository.getProfile] which implements
  /// offline-first reading (Hive cache → Firestore fallback).
  ///
  /// Parameters:
  /// - [userId]: The authenticated user's Firebase UID
  ///
  /// Returns the [UserProfile] if found, null if not yet created.
  ///
  /// Throws [SyncException] if retrieval fails.
  Future<UserProfile?> getProfile(String userId) async {
    return _onboardingRepository.getProfile(userId);
  }

  /// Updates the user profile with new data.
  ///
  /// Delegates to [OnboardingRepository.updateProfile] which implements
  /// dual-write strategy (Hive immediate → Firestore when online).
  ///
  /// Parameters:
  /// - [userId]: The authenticated user's Firebase UID
  /// - [profile]: The updated [UserProfile] data
  ///
  /// Throws [SyncException] if update fails.
  Future<void> updateProfile(String userId, UserProfile profile) async {
    await _onboardingRepository.updateProfile(userId, profile);
  }

  /// Deletes the user profile and all associated data.
  ///
  /// This performs a cascading delete:
  /// 1. Deletes profile from Hive cache
  /// 2. Deletes onboarding data from Firestore
  /// 3. Deletes all plans subcollection
  /// 4. Deletes all completions subcollection
  /// 5. Deletes the user document itself
  ///
  /// Note: This does NOT delete the Firebase Auth account.
  /// Auth account deletion should be handled separately by AuthRepository.
  ///
  /// Parameters:
  /// - [userId]: The authenticated user's Firebase UID
  ///
  /// Throws [SyncException] if deletion fails.
  Future<void> deleteProfile(String userId) async {
    try {
      // Delete from onboarding repository (handles Hive + Firestore onboarding field)
      await _onboardingRepository.deleteProfile(userId);

      // Delete plans subcollection
      await _deleteSubcollection(userId, _plansSubcollection);

      // Delete completions subcollection
      await _deleteSubcollection(userId, _completionsSubcollection);

      // Delete the user document itself
      await _firestore.collection(_usersCollection).doc(userId).delete();
    } catch (e) {
      if (e is SyncException) rethrow;
      throw const SyncException(
        SyncErrorType.syncFailed,
        AppStrings.errorDeleteProfileFailed,
      );
    }
  }

  /// Fetches user statistics including streaks, completions, and plan counts.
  ///
  /// Aggregates data from multiple sources:
  /// - User document: currentStreak, longestStreak, lastActiveDate
  /// - Plans subcollection: count of generated plans
  /// - Completions subcollection: workout and meal completion counts
  ///
  /// Parameters:
  /// - [userId]: The authenticated user's Firebase UID
  ///
  /// Returns [UserStats] with all aggregated statistics.
  /// Returns default stats (all zeros) if user has no data.
  ///
  /// Throws [SyncException] if retrieval fails.
  Future<UserStats> getStats(String userId) async {
    try {
      // Fetch user document for streak data
      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return UserStats.empty();
      }

      final userData = userDoc.data() ?? {};

      // Extract streak data from user document
      final currentStreak = userData['currentStreak'] as int? ?? 0;
      final longestStreak = userData['longestStreak'] as int? ?? 0;
      final lastActiveDate = _parseTimestamp(userData['lastActiveDate']);
      final createdAt = _parseTimestamp(userData['createdAt']);

      // Count plans generated
      final plansSnapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_plansSubcollection)
          .count()
          .get();
      final plansGenerated = plansSnapshot.count ?? 0;

      // Aggregate completions
      final completionsSnapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_completionsSubcollection)
          .get();

      int totalWorkouts = 0;
      int totalMeals = 0;

      for (final doc in completionsSnapshot.docs) {
        final tasks = doc.data()['tasks'] as Map<String, dynamic>? ?? {};

        // Count workout completions
        if (tasks['workout'] == true) {
          totalWorkouts++;
        }

        // Count meal completions (breakfast, lunch, dinner)
        if (tasks['breakfast'] == true) totalMeals++;
        if (tasks['lunch'] == true) totalMeals++;
        if (tasks['dinner'] == true) totalMeals++;
      }

      return UserStats(
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        totalWorkouts: totalWorkouts,
        totalMeals: totalMeals,
        plansGenerated: plansGenerated,
        lastActiveDate: lastActiveDate,
        memberSince: createdAt ?? DateTime.now(),
      );
    } catch (e) {
      if (e is SyncException) rethrow;
      throw const SyncException(
        SyncErrorType.syncFailed,
        'Failed to load statistics. Please try again.',
      );
    }
  }

  /// Deletes all documents in a subcollection.
  ///
  /// Firestore doesn't support recursive deletes natively, so we must
  /// fetch and delete each document individually.
  ///
  /// Parameters:
  /// - [userId]: The parent user document ID
  /// - [subcollection]: The name of the subcollection to delete
  Future<void> _deleteSubcollection(String userId, String subcollection) async {
    final collectionRef = _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(subcollection);

    // Fetch all documents in batches to avoid memory issues
    const batchSize = 100;
    QuerySnapshot snapshot;

    do {
      snapshot = await collectionRef.limit(batchSize).get();

      if (snapshot.docs.isEmpty) break;

      // Use batch delete for efficiency
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } while (snapshot.docs.length == batchSize);
  }

  /// Parses a Firestore timestamp field to DateTime.
  ///
  /// Handles both Timestamp objects and ISO 8601 strings.
  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  /// Checks if the profile has significant changes that warrant plan regeneration.
  ///
  /// Significant changes include:
  /// - Fitness goal change
  /// - Equipment type or details change
  /// - Dietary restrictions change
  ///
  /// Parameters:
  /// - [oldProfile]: The previous profile state
  /// - [newProfile]: The updated profile state
  ///
  /// Returns true if changes should trigger a plan regeneration prompt.
  bool hasSignificantChanges(UserProfile oldProfile, UserProfile newProfile) {
    // Goal change is always significant
    if (oldProfile.goal != newProfile.goal) {
      return true;
    }

    // Equipment type change is significant
    if (oldProfile.equipment != newProfile.equipment) {
      return true;
    }

    // Equipment details change (added or removed items)
    final oldDetails = Set.of(oldProfile.equipmentDetails);
    final newDetails = Set.of(newProfile.equipmentDetails);
    if (!oldDetails.containsAll(newDetails) ||
        !newDetails.containsAll(oldDetails)) {
      return true;
    }

    // Dietary restrictions change
    final oldDietary = Set.of(oldProfile.dietaryRestrictions);
    final newDietary = Set.of(newProfile.dietaryRestrictions);
    if (!oldDietary.containsAll(newDietary) ||
        !newDietary.containsAll(oldDietary)) {
      return true;
    }

    // Biometric changes (age, weight, height) are not significant
    // as they don't fundamentally change workout/meal options
    return false;
  }
}
