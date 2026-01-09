import 'package:fitgenie_app/core/constants/app_colors.dart';
import 'package:fitgenie_app/core/constants/app_strings.dart';
import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitgenie_app/features/auth/presentation/widgets/auth_form.dart';
import 'package:fitgenie_app/features/auth/presentation/widgets/social_buttons.dart';
import 'package:fitgenie_app/features/auth/auth_providers.dart';
import 'package:fitgenie_app/shared/widgets/loading_overlay.dart';
import 'package:fitgenie_app/core/exceptions/auth_exception.dart';

/// Registration screen for creating new user accounts.
///
/// This screen provides a registration form with terms of service acknowledgment.
/// Upon successful registration, it creates both a Firebase Auth user and a
/// Firestore user document, then redirects to the onboarding flow.
///
/// Features:
/// - Email/password account creation
/// - Terms of service acknowledgment
/// - Real-time validation
/// - Loading state handling
/// - Error display with user-friendly messages
/// - Navigation to login screen for existing users
/// - Automatic redirect to onboarding after registration
///
/// Route: `/register`
///
/// Redirects to: `/onboarding` after successful account creation
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  String? _errorMessage;
  bool _isLoading = false;
  bool _acceptedTerms = false;

  /// Handles registration form submission.
  Future<void> _handleRegister(String email, String password) async {
    // Validate terms acceptance
    if (!_acceptedTerms) {
      setState(() {
        _errorMessage = AppStrings.errorTermsAcceptanceRequired;
      });
      return;
    }

    // Clear previous error
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      // Create account via repository
      await ref
          .read(authRepositoryProvider)
          .createAccount(email: email, password: password);

      // Auth state listener will handle navigation to onboarding
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
            backgroundColor: context.colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Unexpected error
      setState(() {
        _errorMessage = AppStrings.errorGeneric;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.errorGeneric),
            backgroundColor: context.colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state to trigger navigation on successful registration
    final authState = ref.watch(authStateProvider);

    // Handle redirect after successful registration
    authState.when(
      data: (user) {
        if (user != null) {
          // User created successfully, redirect to onboarding
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/onboarding');
          });
        }
      },
      loading: () {
        // Still loading, don't redirect
      },
      error: (error, stackTrace) {
        // Auth state error, stay on register screen
      },
    );

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _isLoading ? null : () => context.go('/login'),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

                // Header section
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

                    // Title
                    Text(
                      AppStrings.registerTitle,
                      textAlign: TextAlign.center,
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      AppStrings.registerSubtitle,
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
                  mode: AuthMode.register,
                  isLoading: _isLoading,
                  error: _errorMessage,
                  onSubmit: _handleRegister,
                ),

                const SizedBox(height: 24),

                // Terms of Service checkbox
                InkWell(
                  onTap: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _acceptedTerms = !_acceptedTerms;
                          });
                        },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _acceptedTerms,
                          onChanged: _isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _acceptedTerms = value ?? false;
                                  });
                                },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: RichText(
                            text: TextSpan(
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                              children: [
                                const TextSpan(
                                  text: AppStrings.termsAcceptancePrefix,
                                ),
                                TextSpan(
                                  text: AppStrings.termsOfService,
                                  style: TextStyle(
                                    color: context.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const TextSpan(text: AppStrings.termsConnector),
                                TextSpan(
                                  text: AppStrings.privacyPolicy,
                                  style: TextStyle(
                                    color: context.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Social sign-in buttons (MVP: disabled)
                const SocialButtons(onGoogleSignIn: null, onAppleSignIn: null),

                const SizedBox(height: 32),

                // Sign in navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.messageAlreadyHaveAccount,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : () => context.go('/login'),
                      child: Text(
                        AppStrings.buttonSignIn,
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
