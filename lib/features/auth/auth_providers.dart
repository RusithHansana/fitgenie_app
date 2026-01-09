import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fitgenie_app/features/auth/data/auth_repository.dart';
import 'package:fitgenie_app/features/auth/domain/user_model.dart';
import 'package:fitgenie_app/shared/providers/firebase_providers.dart';

part 'auth_providers.g.dart';

/// Provider for the AuthRepository singleton instance.
///
/// This provider creates and provides access to the AuthRepository,
/// which handles all authentication operations.
///
/// Dependencies:
/// - [firebaseAuthProvider] - Firebase Auth instance
/// - [firestoreProvider] - Firestore instance
@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
}

/// Stream provider for authentication state changes.
///
/// Emits [UserModel] when a user is authenticated, null when not authenticated.
/// This is the single source of truth for auth state throughout the application.
///
/// All protected routes and features should watch this provider to determine
/// if a user is logged in and access their user data.
///
/// Usage:
/// ```dart
/// final authState = ref.watch(authStateProvider);
/// authState.when(
///   data: (user) {
///     if (user != null) {
///       return Text('Welcome ${user.email}');
///     }
///     return Text('Please sign in');
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
/// ```
@riverpod
Stream<UserModel?> authState(AuthStateRef ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
}

/// Provider for the current user's ID.
///
/// Returns the authenticated user's UID as a String, or null if not authenticated.
/// This is a convenience provider derived from [authStateProvider].
///
/// Use this when you only need the user ID (e.g., for Firestore queries)
/// and don't need the full user model.
///
/// Usage:
/// ```dart
/// final userId = ref.watch(currentUserIdProvider);
/// if (userId != null) {
///   // Fetch user-specific data
///   final userPlans = await fetchPlans(userId);
/// }
/// ```
@riverpod
String? currentUserId(CurrentUserIdRef ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.uid;
}

/// Provider for checking if a user is currently authenticated.
///
/// Returns true if a user is signed in, false otherwise.
/// This is a convenience provider derived from [authStateProvider].
///
/// Use this for simple authentication checks, such as in route guards
/// or conditional UI rendering.
///
/// Usage:
/// ```dart
/// final isAuthenticated = ref.watch(isAuthenticatedProvider);
/// if (!isAuthenticated) {
///   return LoginScreen();
/// }
/// return DashboardScreen();
/// ```
@riverpod
bool isAuthenticated(IsAuthenticatedRef ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value != null;
}

/// Provider for the current authenticated user model.
///
/// Returns the complete [UserModel] or null if not authenticated.
/// This provides access to all user properties including email,
/// onboarding status, display name, etc.
///
/// Usage:
/// ```dart
/// final user = ref.watch(currentUserProvider);
/// if (user != null) {
///   print('Email: ${user.email}');
///   print('Onboarding complete: ${user.isOnboardingComplete}');
/// }
/// ```
@riverpod
UserModel? currentUser(CurrentUserRef ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value;
}

/// Provider for checking if the current user has completed onboarding.
///
/// Returns true if the user is authenticated and has completed onboarding,
/// false otherwise (including when not authenticated).
///
/// This is used by the routing logic to determine whether to show
/// the onboarding flow or the main dashboard after login.
///
/// Usage:
/// ```dart
/// final hasCompletedOnboarding = ref.watch(hasCompletedOnboardingProvider);
/// if (!hasCompletedOnboarding) {
///   context.go('/onboarding');
/// } else {
///   context.go('/dashboard');
/// }
/// ```
@riverpod
bool hasCompletedOnboarding(HasCompletedOnboardingRef ref) {
  final user = ref.watch(currentUserProvider);
  return user?.isOnboardingComplete ?? false;
}
