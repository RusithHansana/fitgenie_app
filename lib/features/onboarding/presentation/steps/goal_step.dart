import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitgenie_app/core/constants/app_strings.dart';
import 'package:fitgenie_app/core/constants/app_sizes.dart';
import 'package:fitgenie_app/shared/widgets/app_button.dart';
import 'package:fitgenie_app/features/onboarding/domain/user_profile.dart';
import 'package:fitgenie_app/features/onboarding/onboarding_providers.dart';

/// Step for selecting primary fitness goal.
///
/// This step presents visual goal selection cards with icons and descriptions.
/// The user's goal selection is critical for AI plan customization as it
/// determines the focus of both workout programming and nutrition planning.
///
/// Features:
/// - Four goal options with distinct icons and descriptions
/// - Visual card-based selection for engaging UX
/// - Single selection with immediate visual feedback
/// - Can proceed only after making a selection
/// - Restores previous selection if user returns
///
/// Usage:
/// ```dart
/// GoalStep(
///   onNext: () {
///     // Advance to next step
///   },
/// )
/// ```
class GoalStep extends ConsumerStatefulWidget {
  /// Callback invoked when user completes this step and taps Next.
  final VoidCallback onNext;

  const GoalStep({super.key, required this.onNext});

  @override
  ConsumerState<GoalStep> createState() => _GoalStepState();
}

class _GoalStepState extends ConsumerState<GoalStep> {
  FitnessGoal? _selectedGoal;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  /// Loads previously selected goal if user returns to this step.
  void _loadExistingData() {
    final state = ref.read(onboardingStateProviderProvider);
    final goal = state.getData<FitnessGoal>('goal');
    if (goal != null) {
      setState(() {
        _selectedGoal = goal;
      });
    }
  }

  /// Handles goal selection.
  void _selectGoal(FitnessGoal goal) {
    setState(() {
      _selectedGoal = goal;
    });
  }

  /// Saves selected goal and proceeds to next step.
  void _handleNext() {
    if (_selectedGoal == null) {
      // Show error if no selection made
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your fitness goal'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Save selection
    ref
        .read(onboardingStateProviderProvider.notifier)
        .updateData('goal', _selectedGoal);

    // Proceed to next step
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness Goal'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: 4 / 7, // Step 4 of 7
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.screenMarginMobile),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSizes.spacingMd),

                    // Title
                    Text(
                      AppStrings.onboardingGoalTitle,
                      style: context.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: AppSizes.spacingSm),

                    // Description
                    Text(
                      AppStrings.onboardingGoalDescription,
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: AppSizes.spacingXl),

                    // Goal cards
                    _buildGoalCard(
                      goal: FitnessGoal.muscleGain,
                      theme: context.theme,
                      colorScheme: colorScheme,
                    ),

                    const SizedBox(height: AppSizes.spacingMd),

                    _buildGoalCard(
                      goal: FitnessGoal.weightLoss,
                      theme: context.theme,
                      colorScheme: colorScheme,
                    ),

                    const SizedBox(height: AppSizes.spacingMd),

                    _buildGoalCard(
                      goal: FitnessGoal.generalFitness,
                      theme: context.theme,
                      colorScheme: colorScheme,
                    ),

                    const SizedBox(height: AppSizes.spacingMd),

                    _buildGoalCard(
                      goal: FitnessGoal.endurance,
                      theme: context.theme,
                      colorScheme: colorScheme,
                    ),

                    const SizedBox(height: AppSizes.spacingMd),

                    // Helper text
                    Container(
                      padding: const EdgeInsets.all(AppSizes.spacingMd),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: AppSizes.iconMd,
                            color: colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: AppSizes.spacingSm),
                          Expanded(
                            child: Text(
                              'Your goal helps us customize workout intensity, exercise selection, and meal planning to match your objectives.',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Next Button
            Padding(
              padding: const EdgeInsets.all(AppSizes.screenMarginMobile),
              child: AppButton(
                label: AppStrings.buttonNext,
                onPressed: _handleNext,
                fullWidth: true,
                icon: Icons.arrow_forward,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a selectable goal card.
  Widget _buildGoalCard({
    required FitnessGoal goal,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _selectedGoal == goal;

    return InkWell(
      onTap: () => _selectGoal(goal),
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSizes.spacingMd),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Center(
                child: Text(goal.icon, style: const TextStyle(fontSize: 28)),
              ),
            ),

            const SizedBox(width: AppSizes.spacingMd),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.displayName,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacing2xs),
                  Text(
                    goal.description,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? colorScheme.onPrimaryContainer.withValues(
                              alpha: 0.8,
                            )
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Selection indicator
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: colorScheme.primary,
                size: AppSizes.iconMd,
              )
            else
              Icon(
                Icons.circle_outlined,
                color: colorScheme.outline,
                size: AppSizes.iconMd,
              ),
          ],
        ),
      ),
    );
  }
}
