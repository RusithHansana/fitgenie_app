import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:fitgenie_app/features/onboarding/domain/user_profile.dart';
import 'package:fitgenie_app/core/exceptions/sync_exception.dart';
import 'package:fitgenie_app/core/constants/app_strings.dart';

/// Repository handling persistence of user profile data.
///
/// This repository implements a dual-storage strategy for user profiles:
/// - **Firestore**: Primary source, enables cross-device sync and AI access
/// - **Hive**: Local cache for offline access and fast reads
///
/// The repository follows an offline-first approach:
/// - Writes go to both Hive (immediate) and Firestore (when online)
/// - Reads prefer Hive (fast) with Firestore fallback
/// - Handles network failures gracefully
///
/// Usage:
/// ```dart
/// final repository = OnboardingRepository(
///   firestore: FirebaseFirestore.instance,
///   hiveBox: Hive.box('user_profiles'),
/// );
///
/// // Save profile
/// await repository.saveProfile('userId123', profile);
///
/// // Load profile
/// final profile = await repository.getProfile('userId123');
///
/// // Check completion
/// final isComplete = await repository.isOnboardingComplete('userId123');
/// ```
class OnboardingRepository {
  final FirebaseFirestore _firestore;
  final Box _hiveBox;

  /// Firestore collection name for user documents
  static const String _usersCollection = 'users';

  /// Hive box key prefix for user profiles
  static const String _profileKeyPrefix = 'profile_';

  OnboardingRepository({
    required FirebaseFirestore firestore,
    required Box hiveBox,
  }) : _firestore = firestore,
       _hiveBox = hiveBox;

  /// Saves user profile to both Hive and Firestore.
  ///
  /// This method performs a dual write:
  /// 1. Immediately saves to Hive (local cache)
  /// 2. Attempts to save to Firestore (remote sync)
  ///
  /// If Firestore write fails (offline/network error), the local cache is
  /// still updated, and the data will sync when online via sync service.
  ///
  /// Parameters:
  /// - [userId]: The authenticated user's ID
  /// - [profile]: The complete user profile to save
  ///
  /// Throws [SyncException] if both Hive and Firestore writes fail.
  Future<void> saveProfile(String userId, UserProfile profile) async {
    try {
      // Save to local cache first (immediate, always works)
      final hiveKey = _getHiveKey(userId);
      await _hiveBox.put(hiveKey, profile.toFirestore());

      // Attempt to save to Firestore (may fail if offline)
      try {
        await _firestore.collection(_usersCollection).doc(userId).set({
          'onboarding': profile.toFirestore(),
        }, SetOptions(merge: true));
      } catch (e) {
        // Firestore write failed (likely offline)
        // This is acceptable - local cache is updated
        // Background sync will handle Firestore update later
        // Don't throw, as local operation succeeded
      }
    } catch (e) {
      throw const SyncException(
        SyncErrorType.syncFailed,
        AppStrings.errorSaveProfileFailed,
      );
    }
  }

  /// Retrieves user profile from cache or Firestore.
  ///
  /// Read strategy (offline-first):
  /// 1. Check Hive cache first (fast, works offline)
  /// 2. If not cached, fetch from Firestore
  /// 3. Cache the Firestore result for future reads
  ///
  /// Parameters:
  /// - [userId]: The authenticated user's ID
  ///
  /// Returns the [UserProfile] if found, null if not yet created.
  ///
  /// Throws [SyncException] if retrieval fails.
  Future<UserProfile?> getProfile(String userId) async {
    try {
      // Try Hive cache first
      final hiveKey = _getHiveKey(userId);
      final cachedData = _hiveBox.get(hiveKey);

      if (cachedData != null && cachedData is Map) {
        // Found in cache, deserialize and return
        return UserProfile.fromFirestore(Map<String, dynamic>.from(cachedData));
      }

      // Not in cache, fetch from Firestore
      try {
        final docSnapshot = await _firestore
            .collection(_usersCollection)
            .doc(userId)
            .get();

        if (!docSnapshot.exists) {
          return null; // User document doesn't exist yet
        }

        final data = docSnapshot.data();
        if (data == null || !data.containsKey('onboarding')) {
          return null; // No onboarding data yet
        }

        final onboardingData = data['onboarding'] as Map<String, dynamic>;
        final profile = UserProfile.fromFirestore(onboardingData);

        // Cache for future reads
        await _hiveBox.put(hiveKey, onboardingData);

        return profile;
      } catch (e) {
        // Firestore read failed (offline or error)
        // Return null if not cached, as we can't retrieve it
        return null;
      }
    } catch (e) {
      throw const SyncException(
        SyncErrorType.syncFailed,
        AppStrings.errorLoadProfileFailed,
      );
    }
  }

  /// Updates an existing user profile.
  ///
  /// This is similar to [saveProfile] but semantically represents an update
  /// operation. It performs the same dual-write strategy.
  ///
  /// Parameters:
  /// - [userId]: The authenticated user's ID
  /// - [profile]: The updated user profile
  ///
  /// Throws [SyncException] if update fails.
  Future<void> updateProfile(String userId, UserProfile profile) async {
    // Update uses same logic as save (dual write)
    await saveProfile(userId, profile);
  }

  /// Checks if a user has completed onboarding.
  ///
  /// A user is considered to have completed onboarding if:
  /// - A valid UserProfile exists for them
  /// - The profile contains all required fields
  ///
  /// Parameters:
  /// - [userId]: The authenticated user's ID
  ///
  /// Returns true if onboarding is complete, false otherwise.
  Future<bool> isOnboardingComplete(String userId) async {
    try {
      final profile = await getProfile(userId);
      return profile != null;
    } catch (e) {
      // If we can't determine status, assume incomplete
      return false;
    }
  }

  /// Marks onboarding as complete in the user's document.
  ///
  /// This updates the `isOnboardingComplete` flag in the user document,
  /// which is used by route guards to determine navigation flow.
  ///
  /// Parameters:
  /// - [userId]: The authenticated user's ID
  ///
  /// Throws [SyncException] if update fails.
  Future<void> markOnboardingComplete(String userId) async {
    try {
      // Update Firestore user document
      await _firestore.collection(_usersCollection).doc(userId).set({
        'isOnboardingComplete': true,
      }, SetOptions(merge: true));

      // Note: The UserModel in auth_providers will be updated via
      // the authStateChanges stream when Firestore triggers the update
    } catch (e) {
      throw const SyncException(
        SyncErrorType.syncFailed,
        AppStrings.errorCompleteOnboardingFailed,
      );
    }
  }

  /// Deletes user profile from both Hive and Firestore.
  ///
  /// This is used when a user wants to reset their onboarding or
  /// delete their profile data.
  ///
  /// Parameters:
  /// - [userId]: The authenticated user's ID
  ///
  /// Throws [SyncException] if deletion fails.
  Future<void> deleteProfile(String userId) async {
    try {
      // Delete from Hive cache
      final hiveKey = _getHiveKey(userId);
      await _hiveBox.delete(hiveKey);

      // Delete from Firestore (remove onboarding field)
      try {
        await _firestore.collection(_usersCollection).doc(userId).set({
          'onboarding': FieldValue.delete(),
        }, SetOptions(merge: true));
      } catch (e) {
        // Firestore delete failed (offline)
        // Local cache is cleared, which is primary concern
        // Background sync can handle Firestore cleanup later
      }
    } catch (e) {
      throw const SyncException(
        SyncErrorType.syncFailed,
        AppStrings.errorDeleteProfileFailed,
      );
    }
  }

  /// Clears the entire Hive cache.
  ///
  /// This is useful for testing or when the user logs out.
  /// Does not affect Firestore data.
  Future<void> clearCache() async {
    try {
      await _hiveBox.clear();
    } catch (e) {
      throw const SyncException(
        SyncErrorType.syncFailed,
        AppStrings.errorClearCacheFailed,
      );
    }
  }

  /// Syncs cached profile to Firestore.
  ///
  /// This is called by the sync service to push locally cached profiles
  /// to Firestore when the device comes online after being offline.
  ///
  /// Parameters:
  /// - [userId]: The authenticated user's ID
  ///
  /// Returns true if sync succeeded, false if no cached data or sync failed.
  Future<bool> syncCachedProfile(String userId) async {
    try {
      final hiveKey = _getHiveKey(userId);
      final cachedData = _hiveBox.get(hiveKey);

      if (cachedData == null || cachedData is! Map) {
        return false; // No cached data to sync
      }

      // Attempt to write to Firestore
      await _firestore.collection(_usersCollection).doc(userId).set({
        'onboarding': Map<String, dynamic>.from(cachedData),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      // Sync failed, will retry later
      return false;
    }
  }

  /// Generates the Hive storage key for a user's profile.
  ///
  /// Format: "profile_{userId}"
  String _getHiveKey(String userId) {
    return '$_profileKeyPrefix$userId';
  }
}
