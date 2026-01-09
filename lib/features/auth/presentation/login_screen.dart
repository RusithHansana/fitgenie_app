import 'package:fitgenie_app/core/constants/app_colors.dart';
import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitgenie_app/features/auth/presentation/widgets/auth_form.dart';
import 'package:fitgenie_app/features/auth/presentation/widgets/social_buttons.dart';
import 'package:fitgenie_app/features/auth/auth_providers.dart';
import 'package:fitgenie_app/shared/widgets/loading_overlay.dart';
import 'package:fitgenie_app/core/exceptions/auth_exception.dart';

/// Login screen for user authentication via email and password.
///
/// This screen provides a login form and navigation to related authentication
/// screens (registration and password reset). Upon successful login, it redirects
/// to the dashboard or onboarding flow based on the user's profile status.
///
/// Features:
/// - Email/password authentication
/// - Real-time auth state monitoring
/// - Loading state handling
/// - Error display with user-friendly messages
/// - Navigation to registration and password reset screens
/// - Automatic redirect after successful login
///
/// Route: `/login`
///
/// Redirects to:
/// - `/onboarding` - if user needs to complete onboarding
/// - `/dashboard` - if user has completed onboarding
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String? _errorMessage;
  bool _isLoading = false;

  /// Handles sign-in form submission.
  Future<void> _handleSignIn(String email, String password) async {
    // Clear previous error
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      // Call sign in via repository
      await ref
          .read(authRepositoryProvider)
          .signInWithEmail(email: email, password: password);

      // Auth state listener will handle navigation automatically
      // via the authStateChange listener below
    } on AuthException catch (e) {
      // Display user-friendly error message
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });

      // Also show snack bar for additional visibility
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Unexpected error
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('An unexpected error occurred.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state to trigger navigation on successful login
    final authState = ref.watch(authStateProvider);
    final hasCompletedOnboarding = ref.watch(hasCompletedOnboardingProvider);

    // Handle redirect after successful login
    authState.when(
      data: (user) {
        if (user != null) {
          // User is authenticated, redirect based on onboarding status
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (hasCompletedOnboarding) {
              context.go('/dashboard');
            } else {
              context.go('/onboarding');
            }
          });
        }
      },
      loading: () {
        // Still loading, don't redirect
      },
      error: (error, stackTrace) {
        // Auth state error, stay on login screen
      },
    );

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.transparent,
          leading: null, // No back button on login screen
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

                // Logo and title section
                Column(
                  children: [
                    // App icon/logo placeholder
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: context.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.fitness_center,
                        size: 40,
                        color: context.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Welcome text
                    Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'Sign in to continue your fitness journey',
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Authentication form
                AuthForm(
                  mode: AuthMode.login,
                  isLoading: _isLoading,
                  error: _errorMessage,
                  onSubmit: _handleSignIn,
                ),

                const SizedBox(height: 24),

                // Social sign-in buttons (MVP: disabled)
                const SocialButtons(onGoogleSignIn: null, onAppleSignIn: null),

                const SizedBox(height: 32),

                // Forgot password link
                Center(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => context.go('/forgot-password'),
                    child: Text(
                      'Forgot password?',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Sign up navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account? ',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => context.go('/register'),
                      child: Text(
                        'Sign up',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
