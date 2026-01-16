import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitgenie_app/features/plan_generation/plan_providers.dart';
import 'package:fitgenie_app/features/plan_generation/presentation/widgets/generation_animation.dart';
import 'package:fitgenie_app/shared/widgets/error_display.dart';
import 'package:fitgenie_app/core/constants/app_sizes.dart';
import 'package:fitgenie_app/core/constants/app_strings.dart';
import 'package:fitgenie_app/core/exceptions/ai_exception.dart';

/// Screen that manages the plan generation flow.
///
/// This screen:
/// 1. Triggers plan generation automatically on mount (if no existing plan)
/// 2. Displays engaging animation during generation (15-30 seconds)
/// 3. Handles errors with retry option
/// 4. Redirects to dashboard on successful generation
///
/// Key Features:
/// - Auto-triggers generation on entry
/// - Full-screen loading animation
/// - Error handling with user-friendly messages
/// - Automatic navigation on success
/// - Retry mechanism on failure
///
/// Usage:
/// Navigate to this screen after onboarding completion or when user
/// manually requests a new plan.
///
/// Route: `/plan-generation`
///
/// Navigation Flow:
/// ```
/// Onboarding Complete → PlanGenerationScreen
///   ↓ (generation success)
/// Dashboard (with new plan)
///
/// OR
///
///   ↓ (generation error)
/// Error Display → Retry → Generation
/// ```
///
/// Example routing:
/// ```dart
/// context.go('/plan-generation');
/// ```
class PlanGenerationScreen extends ConsumerStatefulWidget {
  /// Creates a PlanGenerationScreen.
  const PlanGenerationScreen({super.key});

  @override
  ConsumerState<PlanGenerationScreen> createState() =>
      _PlanGenerationScreenState();
}

class _PlanGenerationScreenState extends ConsumerState<PlanGenerationScreen> {
  /// Whether generation has been triggered.
  bool _hasTriggeredGeneration = false;

  @override
  void initState() {
    super.initState();
    // Trigger generation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerGeneration();
    });
  }

  /// Triggers plan generation if not already triggered.
  void _triggerGeneration() {
    if (_hasTriggeredGeneration) return;

    setState(() {
      _hasTriggeredGeneration = true;
    });

    // Trigger generation via provider
    // The provider will handle the actual generation
    ref
        .read(generatePlanProvider.future)
        .then((plan) {
          // Success - navigate to dashboard
          if (mounted) {
            context.go('/dashboard');
          }
        })
        .catchError((error) {
          // Error will be handled by the UI builder
          // User can retry via error display
        });
  }

  /// Handles retry after generation failure.
  void _handleRetry() {
    // Invalidate the provider to reset state
    ref.invalidate(generatePlanProvider);

    // Reset trigger flag and try again
    setState(() {
      _hasTriggeredGeneration = false;
    });

    // Trigger generation again
    _triggerGeneration();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the generation provider state
    final generateState = ref.watch(generatePlanProvider);

    return Scaffold(
      body: SafeArea(
        child: generateState.when(
          // Loading: Show generation animation
          loading: () => const GenerationAnimation(),

          // Success: Show brief success message before navigation
          // (Navigation happens in the .then() callback above)
          data: (plan) => _buildSuccessView(context),

          // Error: Show error with retry option
          error: (error, stackTrace) => _buildErrorView(context, error),
        ),
      ),
    );
  }

  /// Builds the success view shown briefly before navigation.
  Widget _buildSuccessView(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primaryContainer,
            ),
            child: Icon(
              Icons.check_circle,
              size: 60,
              color: colorScheme.primary,
            ),
          ),

          const SizedBox(height: AppSizes.spacingLg),

          // Success message
          Text(
            'Your Plan is Ready!',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSizes.spacingSm),

          Text(
            'Redirecting to your dashboard...',
            style: context.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds the error view with retry option.
  Widget _buildErrorView(BuildContext context, Object error) {
    final colorScheme = context.colorScheme;

    // Extract user-friendly message
    String errorMessage = 'Unable to generate your plan.';
    String errorDetails = 'Please try again.';

    if (error is AiException) {
      errorMessage = error.userFriendlyMessage;
      errorDetails = _getErrorDetails(error.type);
    } else {
      errorDetails = error.toString();
    }

    return Padding(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Error icon
          Icon(Icons.error_outline, size: 80, color: colorScheme.error),

          const SizedBox(height: AppSizes.spacingLg),

          // Error title
          Text(
            'Generation Failed',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSizes.spacingMd),

          // Error message
          Text(
            errorMessage,
            style: context.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSizes.spacingSm),

          // Error details
          Text(
            errorDetails,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSizes.spacingXl),

          // Retry button
          FilledButton.icon(
            onPressed: _handleRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),

          const SizedBox(height: AppSizes.spacingMd),

          // Go back button
          TextButton(
            onPressed: () => context.go('/onboarding'),
            child: const Text('Review My Profile'),
          ),
        ],
      ),
    );
  }

  /// Gets user-friendly error details based on error type.
  String _getErrorDetails(AiErrorType errorType) {
    switch (errorType) {
      case AiErrorType.networkError:
        return AppStrings.errorNoConnection;
      case AiErrorType.rateLimited:
        return AppStrings.errorAiRateLimited;
      case AiErrorType.timeout:
        return AppStrings.errorAiTimeout;
      case AiErrorType.invalidApiKey:
        return AppStrings.errorAiInvalidApiKey;
      case AiErrorType.parseError:
      case AiErrorType.invalidResponse:
        return AppStrings.errorAiParseError;
      case AiErrorType.contentFiltered:
        return AppStrings.errorAiContentFiltered;
      case AiErrorType.unknown:
        return AppStrings.errorUnknown;
    }
  }
}

/// Compact plan generation trigger widget.
///
/// A smaller widget that can be embedded in other screens to trigger
/// plan generation, showing inline loading and error states.
///
/// Usage:
/// ```dart
/// PlanGenerationTrigger(
///   onSuccess: () => context.go('/dashboard'),
/// )
/// ```
class PlanGenerationTrigger extends ConsumerWidget {
  /// Creates a PlanGenerationTrigger.
  ///
  /// Parameters:
  /// - [onSuccess]: Callback when generation succeeds
  /// - [onError]: Optional callback when generation fails
  const PlanGenerationTrigger({
    super.key,
    required this.onSuccess,
    this.onError,
  });

  /// Callback when generation succeeds.
  final VoidCallback onSuccess;

  /// Optional callback when generation fails.
  final void Function(Object error)? onError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final generateState = ref.watch(generatePlanProvider);

    return generateState.when(
      loading: () => const CompactGenerationIndicator(),
      data: (plan) {
        // Call success callback
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onSuccess();
        });
        return const CompactGenerationIndicator();
      },
      error: (error, stackTrace) {
        // Call error callback if provided
        if (onError != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onError!(error);
          });
        }
        return ErrorDisplay(
          error: error,
          onRetry: () => ref.invalidate(generatePlanProvider),
          fullScreen: false,
        );
      },
    );
  }
}
