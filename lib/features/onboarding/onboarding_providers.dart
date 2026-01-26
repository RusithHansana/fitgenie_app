import 'package:fitgenie_app/core/constants/dietary_options.dart';
import 'package:fitgenie_app/shared/services/hive_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fitgenie_app/features/onboarding/data/onboarding_repository.dart';
import 'package:fitgenie_app/features/onboarding/domain/onboarding_state.dart';
import 'package:fitgenie_app/features/onboarding/domain/user_profile.dart';
import 'package:fitgenie_app/shared/providers/firebase_providers.dart'
    as firebase;
import 'package:fitgenie_app/features/auth/auth_providers.dart' as auth;

part 'onboarding_providers.g.dart';

/// Provider for the OnboardingRepository singleton instance.
///
/// This provider creates and provides access to the OnboardingRepository,
/// which handles all user profile persistence operations.
///
/// Dependencies:
/// - [firestoreProvider] - Firestore instance for remote storage
/// - Hive box for local caching
@riverpod
OnboardingRepository onboardingRepository(OnboardingRepositoryRef ref) {
  final firestore = ref.watch(firebase.firestoreProvider);
  final hiveBox = HiveService.userProfileBox;

  return OnboardingRepository(firestore: firestore, hiveBox: hiveBox);
}

/// StateNotifier managing the onboarding wizard state.
///
/// This notifier handles:
/// - Step navigation (next, previous, jump to step)
/// - Data collection across wizard steps
/// - Validation state tracking
/// - Profile saving on completion
///
/// The state persists during the onboarding session but resets when
/// the user completes onboarding or exits the flow.
class OnboardingStateNotifier extends AutoDisposeNotifier<OnboardingState> {
  @override
  OnboardingState build() {
    // Initialize with empty state
    return OnboardingState.initial();
  }

  /// Updates a single field in the collected data.
  ///
  /// Example:
  /// ```dart
  /// notifier.updateData('age', 25);
  /// ```
  void updateData(String key, dynamic value) {
    state = state.updateData(key, value);
  }

  /// Updates multiple fields in the collected data at once.
  ///
  /// This is more efficient than calling [updateData] multiple times.
  ///
  /// Example:
  /// ```dart
  /// notifier.updateMultipleData({
  ///   'age': 25,
  ///   'weight': 75.0,
  ///   'weightUnit': 'kg',
  /// });
  /// ```
  void updateMultipleData(Map<String, dynamic> data) {
    state = state.updateMultipleData(data);
  }

  /// Removes a field from the collected data.
  ///
  /// Useful when user changes a selection that invalidates dependent fields.
  ///
  /// Example:
  /// ```dart
  /// // If user changes equipment type, clear equipment details
  /// notifier.removeData('equipmentDetails');
  /// ```
  void removeData(String key) {
    state = state.removeData(key);
  }

  /// Advances to the next step in the wizard.
  ///
  /// Does nothing if already at the last step.
  void nextStep() {
    state = state.nextStep();
  }

  /// Goes back to the previous step in the wizard.
  ///
  /// Does nothing if already at the first step.
  void previousStep() {
    state = state.previousStep();
  }

  /// Jumps to a specific step in the wizard.
  ///
  /// This is used by the review step's edit buttons to navigate back
  /// to specific steps for corrections.
  ///
  /// Parameters:
  /// - [step]: The target step index (0-based)
  ///
  /// Throws [RangeError] if step is out of range.
  void goToStep(int step) {
    state = state.goToStep(step);
  }

  /// Resets the wizard to the initial state.
  ///
  /// Clears all collected data and returns to the first step.
  /// Called when user exits onboarding or completes it.
  void reset() {
    state = OnboardingState.initial();
  }

  /// Retrieves a value from the collected data.
  ///
  /// Returns null if the key doesn't exist.
  T? getData<T>(String key) {
    return state.getData<T>(key);
  }

  /// Retrieves a value with a default fallback.
  T getDataOrDefault<T>(String key, T defaultValue) {
    return state.getDataOrDefault<T>(key, defaultValue);
  }
}

/// Provider for the onboarding wizard state.
///
/// This provider manages the state of the multi-step onboarding wizard,
/// including current step position and all collected data.
///
/// Uses `keepAlive: true` to prevent auto-disposal during page transitions,
/// ensuring collected data persists throughout the onboarding flow.
///
/// Usage:
/// ```dart
/// // Watch the state
/// final onboardingState = ref.watch(onboardingStateProvider);
///
/// // Access the notifier for actions
/// ref.read(onboardingStateProvider.notifier).nextStep();
/// ref.read(onboardingStateProvider.notifier).updateData('age', 25);
/// ```
@Riverpod(keepAlive: true)
class OnboardingStateProvider extends _$OnboardingStateProvider {
  @override
  OnboardingState build() {
    return OnboardingState.initial();
  }

  /// Updates a single field in the collected data.
  void updateData(String key, dynamic value) {
    state = state.updateData(key, value);
  }

  /// Updates multiple fields at once.
  void updateMultipleData(Map<String, dynamic> data) {
    state = state.updateMultipleData(data);
  }

  /// Removes a field from collected data.
  void removeData(String key) {
    state = state.removeData(key);
  }

  /// Advances to next step.
  void nextStep() {
    state = state.nextStep();
  }

  /// Goes to previous step.
  void previousStep() {
    state = state.previousStep();
  }

  /// Jumps to specific step.
  void goToStep(int step) {
    state = state.goToStep(step);
  }

  /// Resets wizard state.
  void reset() {
    state = OnboardingState.initial();
  }
}

/// Provider for the current user's profile.
///
/// This provider fetches the user profile from the repository, with automatic
/// loading and error states via AsyncValue.
///
/// Returns null if:
/// - User is not authenticated
/// - Profile hasn't been created yet
///
/// Usage:
/// ```dart
/// final profileAsync = ref.watch(userProfileProvider);
/// profileAsync.when(
///   data: (profile) => profile != null ? ProfileView(profile) : EmptyState(),
///   loading: () => LoadingIndicator(),
///   error: (e, st) => ErrorDisplay(e),
/// );
/// ```
@riverpod
Future<UserProfile?> userProfile(UserProfileRef ref) async {
  final userId = ref.watch(firebase.currentUserIdProvider);

  if (userId == null) {
    return null; // Not authenticated
  }

  final repository = ref.watch(onboardingRepositoryProvider);
  return repository.getProfile(userId);
}

/// Provider for checking if the current user has completed onboarding.
///
/// This provider is used by route guards to determine navigation flow:
/// - If false: redirect to /onboarding
/// - If true: allow access to main app
///
/// Derived from the auth state provider's isOnboardingComplete field
/// and validated against the actual profile existence.
///
/// Usage:
/// ```dart
/// final isComplete = ref.watch(isOnboardingCompleteProvider);
/// if (!isComplete) {
///   context.go('/onboarding');
/// }
/// ```
@riverpod
Future<bool> isOnboardingComplete(IsOnboardingCompleteRef ref) async {
  // Check auth state first
  final user = ref.watch(auth.authStateProvider).value;

  if (user == null) {
    return false; // Not authenticated
  }

  // Check if flag is set in user model
  if (user.isOnboardingComplete) {
    return true;
  }

  // Double-check by verifying profile exists
  // This handles cases where the flag might be out of sync
  final userId = user.uid;
  final repository = ref.watch(onboardingRepositoryProvider);

  return repository.isOnboardingComplete(userId);
}

/// Action provider for saving the user profile.
///
/// This provider handles the complete save operation:
/// 1. Creates UserProfile from collected data
/// 2. Saves to repository (Hive + Firestore)
/// 3. Marks onboarding as complete
///
/// Returns the saved UserProfile on success.
///
/// Throws exception if save fails or required data is missing.
///
/// Usage:
/// ```dart
/// try {
///   final profile = await ref.read(saveUserProfileProvider.future);
///   // Navigate to plan generation
/// } catch (e) {
///   // Show error message
/// }
/// ```
@riverpod
Future<UserProfile> saveUserProfile(SaveUserProfileRef ref) async {
  final userId = ref.read(auth.currentUserIdProvider);

  if (userId == null) {
    throw Exception('User not authenticated');
  }

  final onboardingState = ref.read(onboardingStateProviderProvider);

  if (!onboardingState.hasRequiredData) {
    throw Exception('Missing required profile data');
  }

  // Build UserProfile from collected data
  final profile = _buildProfileFromState(onboardingState);

  // Save to repository
  final repository = ref.read(onboardingRepositoryProvider);
  await repository.saveProfile(userId, profile);

  // Mark onboarding as complete
  await repository.markOnboardingComplete(userId);

  // Invalidate relevant providers to refresh data
  ref.invalidate(userProfileProvider);
  ref.invalidate(isOnboardingCompleteProvider);
  ref.invalidate(auth.authStateProvider);

  return profile;
}

/// Builds a UserProfile from the onboarding state's collected data.
///
/// This internal helper converts the `Map<String, dynamic>` collected data
/// into a properly typed UserProfile instance.
///
/// Throws [StateError] if required fields are missing or have invalid types.
UserProfile _buildProfileFromState(OnboardingState state) {
  final data = state.collectedData;

  try {
    return UserProfile(
      age: data['age'] as int,
      weight: (data['weight'] as num).toDouble(),
      weightUnit: data['weightUnit'] as WeightUnit,
      height: (data['height'] as num).toDouble(),
      heightUnit: data['heightUnit'] as HeightUnit,
      goal: data['goal'] as FitnessGoal,
      equipment: data['equipment'] as EquipmentType,
      equipmentDetails:
          (data['equipmentDetails'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      dietaryRestrictions: (data['dietaryRestrictions'] as List<dynamic>)
          .cast<DietaryRestriction>(),
      dietaryNotes: data['dietaryNotes'] as String?,
    );
  } catch (e) {
    throw StateError('Failed to build profile from collected data: $e');
  }
}
