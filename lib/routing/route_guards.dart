import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Type definition for route guard functions.
///
/// A guard receives the current [BuildContext], [GoRouterState], and returns
/// a redirect path as [String] or `null` to allow the navigation.
///
/// Guards are executed in order and the first non-null result wins.
typedef RouteGuard =
    String? Function(BuildContext context, GoRouterState state);

/// Route paths used throughout the application.
///
/// Centralized path constants prevent typos and enable refactoring.
abstract final class RoutePaths {
  // Auth routes
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Onboarding
  static const String onboarding = '/onboarding';

  // Plan generation
  static const String planGeneration = '/plan-generation';

  // Main app routes
  static const String dashboard = '/dashboard';
  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';

  /// Routes that don't require authentication.
  static const Set<String> publicRoutes = {login, register, forgotPassword};

  /// Routes that are only for unauthenticated users (guest routes).
  static const Set<String> guestOnlyRoutes = {login, register, forgotPassword};

  /// Routes that require completed onboarding.
  static const Set<String> protectedRoutes = {
    dashboard,
    chat,
    profile,
    editProfile,
  };
}

/// Navigation guards for authentication and onboarding status.
///
/// These guards are used with go_router's redirect mechanism to control
/// navigation flow based on the user's authentication and onboarding state.
///
/// Guard execution order matters:
/// 1. Auth guard - ensures user is authenticated
/// 2. Onboarding guard - ensures onboarding is complete
/// 3. Guest guard - prevents authenticated users from accessing auth screens
///
/// Usage:
/// ```dart
/// GoRouter(
///   redirect: (context, state) {
///     return RouteGuards.composedGuard(ref, context, state);
///   },
/// );
/// ```
abstract final class RouteGuards {
  /// Creates an authentication guard.
  ///
  /// Redirects unauthenticated users to the login screen.
  /// Returns `null` to allow navigation if authenticated.
  ///
  /// This guard should be applied first before any other guards.
  ///
  /// Parameters:
  /// - [isAuthenticated] - Current authentication status
  /// - [isLoading] - Whether auth state is still loading
  ///
  /// Returns:
  /// - [RoutePaths.login] if not authenticated and not on a public route
  /// - `null` to allow navigation
  static String? authGuard({
    required bool isAuthenticated,
    required bool isLoading,
    required GoRouterState state,
  }) {
    final currentPath = state.matchedLocation;

    // Don't redirect while auth state is loading
    if (isLoading) {
      return null;
    }

    // Allow access to public routes regardless of auth state
    if (RoutePaths.publicRoutes.contains(currentPath)) {
      return null;
    }

    // Redirect to login if not authenticated
    if (!isAuthenticated) {
      return RoutePaths.login;
    }

    return null;
  }

  /// Creates an onboarding guard.
  ///
  /// Redirects authenticated users who haven't completed onboarding
  /// to the onboarding screen.
  ///
  /// This guard should only be applied after the auth guard confirms
  /// the user is authenticated.
  ///
  /// Parameters:
  /// - [isAuthenticated] - Current authentication status
  /// - [hasCompletedOnboarding] - Whether user finished onboarding wizard
  ///
  /// Returns:
  /// - [RoutePaths.onboarding] if authenticated but onboarding incomplete
  /// - `null` to allow navigation
  static String? onboardingGuard({
    required bool isAuthenticated,
    required bool hasCompletedOnboarding,
    required GoRouterState state,
  }) {
    final currentPath = state.matchedLocation;

    // Only apply to authenticated users
    if (!isAuthenticated) {
      return null;
    }

    // Allow access to onboarding and plan generation routes
    if (currentPath == RoutePaths.onboarding ||
        currentPath == RoutePaths.planGeneration) {
      return null;
    }

    // Allow access to public/guest routes (will be handled by guest guard)
    if (RoutePaths.publicRoutes.contains(currentPath)) {
      return null;
    }

    // Redirect to onboarding if not complete and trying to access protected routes
    if (!hasCompletedOnboarding &&
        RoutePaths.protectedRoutes.contains(currentPath)) {
      return RoutePaths.onboarding;
    }

    return null;
  }

  /// Creates a guest guard.
  ///
  /// Redirects authenticated users away from guest-only routes
  /// (login, register, forgot-password) to the appropriate screen.
  ///
  /// If onboarding is incomplete, redirects to onboarding.
  /// If onboarding is complete, redirects to dashboard.
  ///
  /// Parameters:
  /// - [isAuthenticated] - Current authentication status
  /// - [hasCompletedOnboarding] - Whether user finished onboarding wizard
  ///
  /// Returns:
  /// - [RoutePaths.onboarding] if authenticated but onboarding incomplete
  /// - [RoutePaths.dashboard] if authenticated and onboarding complete
  /// - `null` to allow navigation (for unauthenticated users)
  static String? guestGuard({
    required bool isAuthenticated,
    required bool hasCompletedOnboarding,
    required GoRouterState state,
  }) {
    final currentPath = state.matchedLocation;

    // Only apply to guest-only routes
    if (!RoutePaths.guestOnlyRoutes.contains(currentPath)) {
      return null;
    }

    // Allow unauthenticated users to access guest routes
    if (!isAuthenticated) {
      return null;
    }

    // Authenticated user on guest route - redirect appropriately
    if (hasCompletedOnboarding) {
      return RoutePaths.dashboard;
    } else {
      return RoutePaths.onboarding;
    }
  }

  /// Composes all guards into a single redirect function.
  ///
  /// Guards are executed in order:
  /// 1. Guest guard - redirect authenticated users from auth screens
  /// 2. Auth guard - require authentication for protected routes
  /// 3. Onboarding guard - require completed onboarding for main app
  ///
  /// The first guard that returns a non-null path wins.
  ///
  /// Parameters:
  /// - [isAuthenticated] - Current authentication status
  /// - [isLoading] - Whether auth state is still loading
  /// - [hasCompletedOnboarding] - Whether user finished onboarding wizard
  /// - [state] - Current router state
  ///
  /// Returns:
  /// - Redirect path or `null` to allow navigation
  static String? composedRedirect({
    required bool isAuthenticated,
    required bool isLoading,
    required bool hasCompletedOnboarding,
    required GoRouterState state,
  }) {
    // During auth loading, only allow current route
    if (isLoading) {
      return null;
    }

    // Execute guards in order
    String? redirect;

    // 1. Guest guard - prevent authenticated users on auth screens
    redirect = guestGuard(
      isAuthenticated: isAuthenticated,
      hasCompletedOnboarding: hasCompletedOnboarding,
      state: state,
    );
    if (redirect != null) return redirect;

    // 2. Auth guard - require authentication for protected routes
    redirect = authGuard(
      isAuthenticated: isAuthenticated,
      isLoading: isLoading,
      state: state,
    );
    if (redirect != null) return redirect;

    // 3. Onboarding guard - require completed onboarding
    redirect = onboardingGuard(
      isAuthenticated: isAuthenticated,
      hasCompletedOnboarding: hasCompletedOnboarding,
      state: state,
    );
    if (redirect != null) return redirect;

    // All guards passed - allow navigation
    return null;
  }

  /// Determines the initial route based on authentication state.
  ///
  /// Used to set the initial location when the app starts.
  ///
  /// Returns:
  /// - [RoutePaths.login] if not authenticated
  /// - [RoutePaths.onboarding] if authenticated but onboarding incomplete
  /// - [RoutePaths.dashboard] if fully authenticated and onboarded
  static String getInitialRoute({
    required bool isAuthenticated,
    required bool hasCompletedOnboarding,
  }) {
    if (!isAuthenticated) {
      return RoutePaths.login;
    }

    if (!hasCompletedOnboarding) {
      return RoutePaths.onboarding;
    }

    return RoutePaths.dashboard;
  }
}

/// A listenable that notifies go_router to refresh when auth state changes.
///
/// This class bridges Riverpod's reactive state with go_router's
/// refreshListenable mechanism, ensuring route guards re-evaluate
/// when authentication or onboarding state changes.
///
/// Usage:
/// ```dart
/// final authNotifier = RouterRefreshNotifier();
///
/// // Update when auth state changes
/// ref.listen(authStateProvider, (_, __) {
///   authNotifier.notify();
/// });
///
/// GoRouter(
///   refreshListenable: authNotifier,
///   // ...
/// );
/// ```
class RouterRefreshNotifier extends ChangeNotifier {
  /// Notifies listeners to trigger a router refresh.
  ///
  /// Call this method when auth or onboarding state changes
  /// to force route guards to re-evaluate.
  void notify() {
    notifyListeners();
  }
}
