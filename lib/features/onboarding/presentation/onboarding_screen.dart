import 'package:fitgenie_app/shared/providers/logger_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitgenie_app/features/onboarding/onboarding_providers.dart';
import 'package:fitgenie_app/features/onboarding/presentation/steps/welcome_step.dart';
import 'package:fitgenie_app/features/onboarding/presentation/steps/age_weight_step.dart';
import 'package:fitgenie_app/features/onboarding/presentation/steps/height_step.dart';
import 'package:fitgenie_app/features/onboarding/presentation/steps/goal_step.dart';
import 'package:fitgenie_app/features/onboarding/presentation/steps/equipment_step.dart';
import 'package:fitgenie_app/features/onboarding/presentation/steps/dietary_step.dart';
import 'package:fitgenie_app/features/onboarding/presentation/steps/review_step.dart';
import 'package:fitgenie_app/shared/widgets/loading_overlay.dart';

/// Main onboarding wizard screen managing multi-step flow.
///
/// This screen orchestrates the entire onboarding experience, managing:
/// - Step-by-step navigation through a PageView
/// - Progress tracking and visual indicators
/// - Back button handling for navigation
/// - Profile saving on completion
/// - Routing to plan generation after successful save
///
/// The wizard consists of 7 steps:
/// 1. Welcome - Introduction and benefits
/// 2. Age & Weight - Basic biometric data
/// 3. Height - Height with unit selection
/// 4. Fitness Goal - Primary goal selection
/// 5. Equipment - Available equipment type and details
/// 6. Dietary - Dietary restrictions and preferences
/// 7. Review - Summary with edit options and generation CTA
///
/// Usage:
/// This screen is accessed via routing when a new user needs to complete
/// onboarding, or when an existing user wants to update their profile.
///
/// Route: `/onboarding`
/// Redirects to: `/plan-generation` on completion
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // Initialize page controller with current step from state
    final currentStep = ref.read(onboardingStateProviderProvider).currentStep;
    _pageController = PageController(initialPage: currentStep);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Advances to the next step.
  void _nextStep() {
    final state = ref.read(onboardingStateProviderProvider);

    if (!state.isLastStep) {
      ref.read(onboardingStateProviderProvider.notifier).nextStep();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Goes back to the previous step.
  void _previousStep() {
    final state = ref.read(onboardingStateProviderProvider);

    if (!state.isFirstStep) {
      ref.read(onboardingStateProviderProvider.notifier).previousStep();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Jumps to a specific step (used by review screen's edit buttons).
  void _goToStep(int step) {
    ref.read(onboardingStateProviderProvider.notifier).goToStep(step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Handles the generation action from review step.
  Future<void> _handleGenerate() async {
    final logger = ref.read(loggerProvider);
    if (_isSaving) return; // Prevent duplicate saves

    setState(() {
      _isSaving = true;
    });

    try {
      // Save profile via provider
      await ref.read(saveUserProfileProvider.future);

      // Navigate to plan generation screen
      if (mounted) {
        // Reset onboarding state
        ref.read(onboardingStateProviderProvider.notifier).reset();

        // Navigate to plan generation
        context.go('/plan-generation');
      }
    } catch (e) {
      logger.e('Error saving user profile: $e');
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(label: 'Retry', onPressed: _handleGenerate),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Handles the back button press.
  Future<bool> _handleBackButton() async {
    final state = ref.read(onboardingStateProviderProvider);

    if (state.isFirstStep) {
      // Show exit confirmation dialog
      final shouldExit = await _showExitConfirmation();
      return shouldExit ?? false;
    } else {
      // Go to previous step
      _previousStep();
      return false; // Don't exit
    }
  }

  /// Shows a confirmation dialog when user tries to exit onboarding.
  Future<bool?> _showExitConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Onboarding?'),
        content: const Text(
          'Your progress will be saved. You can continue later from where you left off.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continue Setup'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _handleBackButton();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: LoadingOverlay(
        isLoading: _isSaving,
        message: 'Saving your profile...',
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // Disable swipe
          children: [
            // Step 0: Welcome
            WelcomeStep(onNext: _nextStep),

            // Step 1: Age & Weight
            AgeWeightStep(onNext: _nextStep),

            // Step 2: Height
            HeightStep(onNext: _nextStep),

            // Step 3: Fitness Goal
            GoalStep(onNext: _nextStep),

            // Step 4: Equipment
            EquipmentStep(onNext: _nextStep),

            // Step 5: Dietary
            DietaryStep(onNext: _nextStep),

            // Step 6: Review & Generate
            ReviewStep(onEdit: _goToStep, onGenerate: _handleGenerate),
          ],
        ),
      ),
    );
  }
}
