import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fitgenie_app/features/profile/data/profile_repository.dart';
import 'package:fitgenie_app/features/profile/domain/user_stats.dart';
import 'package:fitgenie_app/features/onboarding/domain/user_profile.dart';
import 'package:fitgenie_app/features/onboarding/onboarding_providers.dart';
import 'package:fitgenie_app/features/auth/auth_providers.dart' as auth;
import 'package:fitgenie_app/shared/providers/firebase_providers.dart';

part 'profile_providers.g.dart';

/// Provider for the ProfileRepository singleton instance.
///
/// This provider creates and provides access to the ProfileRepository,
/// which handles profile operations including retrieval, updates,
/// statistics, and account deletion.
///
/// Dependencies:
/// - [onboardingRepositoryProvider] - For profile CRUD operations
/// - [firestoreProvider] - For statistics queries
@riverpod
ProfileRepository profileRepository(ProfileRepositoryRef ref) {
  final onboardingRepo = ref.watch(onboardingRepositoryProvider);
  final firestore = ref.watch(firestoreProvider);

  return ProfileRepository(
    onboardingRepository: onboardingRepo,
    firestore: firestore,
  );
}

/// Provider for the current user's profile.
///
/// This provider fetches the user profile from the repository, with automatic
/// loading and error states via AsyncValue. Returns null if user is not
/// authenticated or profile hasn't been created yet.
///
/// The profile data is read from cache-first (Hive) then Firestore, following
/// the offline-first pattern established in the onboarding repository.
///
/// Usage:
/// ```dart
/// final profileAsync = ref.watch(profileProvider);
/// profileAsync.when(
///   data: (profile) {
///     if (profile == null) {
///       return Text('No profile found');
///     }
///     return ProfileView(profile: profile);
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (e, st) => ErrorDisplay(error: e),
/// );
/// ```
@riverpod
Future<UserProfile?> profile(ProfileRef ref) async {
  final userId = ref.watch(auth.currentUserIdProvider);

  if (userId == null) {
    return null; // Not authenticated
  }

  final repository = ref.watch(profileRepositoryProvider);
  return repository.getProfile(userId);
}

/// Provider for the current user's statistics.
///
/// This provider fetches aggregated user statistics including:
/// - Current and longest streak
/// - Total workouts completed
/// - Total meals completed
/// - Plans generated count
/// - Membership duration
///
/// Returns empty stats (all zeros) if user has no activity data.
///
/// Usage:
/// ```dart
/// final statsAsync = ref.watch(userStatsProvider);
/// statsAsync.when(
///   data: (stats) => StatsCard(stats: stats),
///   loading: () => StatsCardSkeleton(),
///   error: (e, st) => ErrorText(e),
/// );
/// ```
@riverpod
Future<UserStats> userStats(UserStatsRef ref) async {
  final userId = ref.watch(auth.currentUserIdProvider);

  if (userId == null) {
    return UserStats.empty();
  }

  final repository = ref.watch(profileRepositoryProvider);
  return repository.getStats(userId);
}

/// Action provider for updating user profile.
///
/// This provider handles profile update operations. After a successful update,
/// it invalidates the profile and stats providers to refresh the UI with
/// updated data.
///
/// The update follows the offline-first pattern: immediate Hive write,
/// then Firestore sync when online.
///
/// Parameters:
/// - [profile]: The updated UserProfile to save
///
/// Returns the saved profile on success.
///
/// Throws [SyncException] if the update fails.
///
/// Usage:
/// ```dart
/// try {
///   await ref.read(updateProfileProvider(updatedProfile).future);
///   context.showSnackBar('Profile updated successfully!');
/// } catch (e) {
///   context.showSnackBar('Failed to update profile');
/// }
/// ```
@riverpod
Future<UserProfile> updateProfile(
  UpdateProfileRef ref,
  UserProfile profile,
) async {
  final userId = ref.watch(auth.currentUserIdProvider);

  if (userId == null) {
    throw Exception('User not authenticated');
  }

  final repository = ref.watch(profileRepositoryProvider);
  await repository.updateProfile(userId, profile);

  // Invalidate profile and stats to refresh UI
  ref.invalidate(profileProvider);
  ref.invalidate(userStatsProvider);
  ref.invalidate(userProfileProvider);

  return profile;
}

/// Action provider for user logout.
///
/// This provider handles the complete logout flow:
/// 1. Signs out from Firebase Auth
/// 2. Clears local Hive cache
/// 3. Invalidates all auth and profile providers
///
/// After logout, the auth state stream will emit null, triggering
/// navigation to the login screen via route guards.
///
/// Usage:
/// ```dart
/// // Show confirmation dialog first
/// final confirmed = await showLogoutConfirmation(context);
/// if (confirmed) {
///   await ref.read(logoutProvider.future);
/// }
/// ```
@riverpod
Future<void> logout(LogoutRef ref) async {
  final authRepository = ref.read(auth.authRepositoryProvider);

  // Sign out from Firebase Auth
  await authRepository.signOut();

  // Clear local profile cache
  final hiveBox = Hive.box('user_profiles');
  await hiveBox.clear();

  // Invalidate all auth and profile related providers
  ref.invalidate(auth.authStateProvider);
  ref.invalidate(profileProvider);
  ref.invalidate(userStatsProvider);
  ref.invalidate(userProfileProvider);
}

/// Action provider for account deletion.
///
/// This provider handles the complete account deletion flow:
/// 1. Deletes all user profile data from Firestore
/// 2. Deletes all plans and completions
/// 3. Clears local Hive cache
/// 4. Deletes Firebase Auth account
///
/// WARNING: This action is irreversible. The user will lose all data
/// including workout history, plans, and account access.
///
/// Usage:
/// ```dart
/// // Show strong confirmation dialog first
/// final confirmed = await showDeleteAccountConfirmation(context);
/// if (confirmed) {
///   try {
///     await ref.read(deleteAccountProvider.future);
///     // Navigate to welcome/login screen
///   } catch (e) {
///     // Show error message
///   }
/// }
/// ```
@riverpod
Future<void> deleteAccount(DeleteAccountRef ref) async {
  final userId = ref.watch(auth.currentUserIdProvider);

  if (userId == null) {
    throw Exception('User not authenticated');
  }

  // Delete all profile data from Firestore and cache
  final profileRepository = ref.read(profileRepositoryProvider);
  await profileRepository.deleteProfile(userId);

  // Delete Firebase Auth account
  final authRepository = ref.read(auth.authRepositoryProvider);
  await authRepository.deleteAccount();

  // Clear all local data
  final hiveBox = Hive.box('user_profiles');
  await hiveBox.clear();

  // Invalidate all providers
  ref.invalidate(auth.authStateProvider);
  ref.invalidate(profileProvider);
  ref.invalidate(userStatsProvider);
  ref.invalidate(userProfileProvider);
}

/// Provider for checking if profile has significant changes.
///
/// This provider is used by the edit profile screen to determine if
/// changes warrant prompting the user to regenerate their plan.
///
/// Significant changes include:
/// - Fitness goal change
/// - Equipment type or details change
/// - Dietary restrictions change
///
/// Biometric changes (age, weight, height) are NOT considered significant.
///
/// Usage:
/// ```dart
/// final hasChanges = ref.read(
///   hasSignificantChangesProvider(oldProfile, newProfile)
/// );
///
/// if (hasChanges) {
///   final shouldRegenerate = await showRegenerationPrompt(context);
///   // Handle regeneration...
/// }
/// ```
@riverpod
bool hasSignificantChanges(
  HasSignificantChangesRef ref,
  UserProfile oldProfile,
  UserProfile newProfile,
) {
  final repository = ref.read(profileRepositoryProvider);
  return repository.hasSignificantChanges(oldProfile, newProfile);
}
