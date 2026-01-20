import 'package:fitgenie_app/features/auth/domain/user_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Route guards
import 'package:fitgenie_app/routing/route_guards.dart';

// Auth providers
import 'package:fitgenie_app/features/auth/auth_providers.dart';

// Auth screens
import 'package:fitgenie_app/features/auth/presentation/login_screen.dart';
import 'package:fitgenie_app/features/auth/presentation/register_screen.dart';
import 'package:fitgenie_app/features/auth/presentation/forgot_password_screen.dart';

// Onboarding screen
import 'package:fitgenie_app/features/onboarding/presentation/onboarding_screen.dart';

// Plan generation screen
import 'package:fitgenie_app/features/plan_generation/presentation/plan_generation_screen.dart';

// Dashboard and main screens
import 'package:fitgenie_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:fitgenie_app/features/chat/presentation/chat_screen.dart';
import 'package:fitgenie_app/features/profile/presentation/profile_screen.dart';
import 'package:fitgenie_app/features/profile/presentation/edit_profile_screen.dart';

part 'app_router.g.dart';

/// Central go_router configuration for FitGenie navigation.
///
/// This provider creates a GoRouter instance with all app routes configured,
/// including authentication guards and redirect logic. It uses Riverpod to
/// watch auth state and automatically refreshes routes when state changes.
///
/// Route Structure:
/// ```
/// /login                   → LoginScreen (guest only)
/// /register                → RegisterScreen (guest only)
/// /forgot-password         → ForgotPasswordScreen (guest only)
/// /onboarding              → OnboardingScreen (auth required, onboarding incomplete)
/// /plan-generation         → PlanGenerationScreen (auth + onboarding required)
/// /dashboard               → DashboardScreen (auth + onboarding required)
/// /chat                    → ChatScreen (auth + onboarding required)
/// /profile                 → ProfileScreen (auth + onboarding required)
/// /profile/edit            → EditProfileScreen (auth + onboarding required)
/// ```
///
/// Guard Logic:
/// - Unauthenticated users → redirected to /login (except public routes)
/// - Authenticated users without onboarding → redirected to /onboarding
/// - Authenticated users with onboarding on auth screens → redirected to /dashboard
///
/// Usage in main.dart:
/// ```dart
/// MaterialApp.router(
///   routerConfig: ref.watch(appRouterProvider),
/// );
/// ```
@riverpod
GoRouter appRouter(AppRouterRef ref) {
  // Watch auth state to trigger route refresh
  final authState = ref.watch(authStateProvider);
  final hasCompletedOnboarding = ref.watch(hasCompletedOnboardingProvider);

  // Determine auth status from AsyncValue
  final isAuthenticated = authState.valueOrNull != null;
  final isAuthLoading = authState.isLoading;

  // Create refresh notifier for reactive routing
  final refreshNotifier = RouterRefreshNotifier();

  // Listen for auth state changes and notify router
  ref.listen<AsyncValue<UserModel?>>(authStateProvider, (previous, next) {
    refreshNotifier.notify();
  });

  return GoRouter(
    // Initial location determined by auth state
    initialLocation: RouteGuards.getInitialRoute(
      isAuthenticated: isAuthenticated,
      hasCompletedOnboarding: hasCompletedOnboarding,
    ),

    // Refresh routes when auth state changes
    refreshListenable: refreshNotifier,

    // Global redirect logic using route guards
    redirect: (BuildContext context, GoRouterState state) {
      return RouteGuards.composedRedirect(
        isAuthenticated: isAuthenticated,
        isLoading: isAuthLoading,
        hasCompletedOnboarding: hasCompletedOnboarding,
        state: state,
      );
    },

    // Error page configuration
    errorBuilder: (context, state) => _ErrorPage(error: state.error),

    // Route definitions
    routes: [
      // =======================================================================
      // AUTH ROUTES (Guest only - redirected if authenticated)
      // =======================================================================
      GoRoute(
        path: RoutePaths.login,
        name: 'login',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const LoginScreen()),
      ),

      GoRoute(
        path: RoutePaths.register,
        name: 'register',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const RegisterScreen()),
      ),

      GoRoute(
        path: RoutePaths.forgotPassword,
        name: 'forgot-password',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
        ),
      ),

      // =======================================================================
      // ONBOARDING ROUTE (Auth required, onboarding incomplete)
      // =======================================================================
      GoRoute(
        path: RoutePaths.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const OnboardingScreen()),
      ),

      // =======================================================================
      // PLAN GENERATION ROUTE (Auth + onboarding required)
      // =======================================================================
      GoRoute(
        path: RoutePaths.planGeneration,
        name: 'plan-generation',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const PlanGenerationScreen(),
        ),
      ),

      // =======================================================================
      // MAIN APP ROUTES (Auth + onboarding required)
      // =======================================================================
      GoRoute(
        path: RoutePaths.dashboard,
        name: 'dashboard',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const DashboardScreen()),
      ),

      GoRoute(
        path: RoutePaths.chat,
        name: 'chat',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const ChatScreen()),
      ),

      GoRoute(
        path: RoutePaths.profile,
        name: 'profile',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const ProfileScreen()),
        routes: [
          // Nested route: /profile/edit
          GoRoute(
            path: 'edit',
            name: 'edit-profile',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const EditProfileScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}

/// Error page displayed when navigation fails or route not found.
///
/// Provides a user-friendly error display with a button to return
/// to the dashboard or login screen based on auth state.
class _ErrorPage extends StatelessWidget {
  const _ErrorPage({this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon
              Icon(
                Icons.error_outline,
                size: 72,
                color: Theme.of(context).colorScheme.error,
              ),

              const SizedBox(height: 24),

              // Error title
              Text(
                'Page Not Found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Error message
              Text(
                error?.toString() ??
                    'The page you are looking for does not exist.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Return home button
              FilledButton.icon(
                onPressed: () {
                  // Try to go to dashboard, will redirect appropriately
                  context.go(RoutePaths.dashboard);
                },
                icon: const Icon(Icons.home),
                label: const Text('Go to Home'),
              ),

              const SizedBox(height: 12),

              // Go back button
              TextButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(RoutePaths.dashboard);
                  }
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Extension methods for type-safe navigation.
///
/// Provides convenient navigation methods that use named routes
/// instead of string paths, reducing the risk of typos.
extension AppRouterExtension on BuildContext {
  /// Navigates to the login screen.
  void goToLogin() => go(RoutePaths.login);

  /// Navigates to the register screen.
  void goToRegister() => go(RoutePaths.register);

  /// Navigates to the forgot password screen.
  void goToForgotPassword() => go(RoutePaths.forgotPassword);

  /// Navigates to the onboarding screen.
  void goToOnboarding() => go(RoutePaths.onboarding);

  /// Navigates to the plan generation screen.
  void goToPlanGeneration() => go(RoutePaths.planGeneration);

  /// Navigates to the dashboard screen.
  void goToDashboard() => go(RoutePaths.dashboard);

  /// Navigates to the chat screen.
  void goToChat() => go(RoutePaths.chat);

  /// Navigates to the profile screen.
  void goToProfile() => go(RoutePaths.profile);

  /// Navigates to the edit profile screen.
  void goToEditProfile() => go(RoutePaths.editProfile);
}
