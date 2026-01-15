import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitgenie_app/core/constants/app_strings.dart';
import 'package:fitgenie_app/core/constants/app_sizes.dart';
import 'package:fitgenie_app/core/utils/formatters.dart';
import 'package:fitgenie_app/shared/widgets/app_button.dart';
import 'package:fitgenie_app/features/onboarding/domain/user_profile.dart';
import 'package:fitgenie_app/features/onboarding/onboarding_providers.dart';
import 'package:fitgenie_app/core/constants/dietary_options.dart';

/// Final step showing summary of collected data before plan generation.
///
/// This review step allows users to see all their entered information in
/// one place and make corrections before committing to plan generation.
/// It builds anticipation for the AI-generated plan and provides a final
/// opportunity to ensure accuracy.
///
/// Features:
/// - Summary cards for all collected data
/// - Edit buttons that navigate back to specific steps
/// - "Generate My Plan" prominent CTA
/// - Privacy/disclaimer notice
/// - Visual grouping by data category
///
/// Usage:
/// ```dart
/// ReviewStep(
///   onEdit: (int step) {
///     // Navigate back to specified step for editing
///   },
///   onGenerate: () {
///     // Proceed to plan generation
///   },
/// )
/// ```
class ReviewStep extends ConsumerWidget {
  /// Callback invoked when user taps an edit button.
  /// Parameter is the step index to navigate to.
  final void Function(int step) onEdit;

  /// Callback invoked when user taps "Generate My Plan".
  final VoidCallback onGenerate;

  const ReviewStep({super.key, required this.onEdit, required this.onGenerate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = context.colorScheme;
    final state = ref.watch(onboardingStateProviderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review & Confirm'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: 1.0, // Step 7 of 7 - complete
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
                      AppStrings.onboardingReviewTitle,
                      style: context.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: AppSizes.spacingSm),

                    // Description
                    Text(
                      AppStrings.onboardingReviewDescription,
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: AppSizes.spacingXl),

                    // Basic Info Section
                    _buildSectionCard(
                      context: context,
                      theme: context.theme,
                      colorScheme: colorScheme,
                      icon: Icons.person,
                      title: 'Basic Information',
                      onEdit: () => onEdit(1), // Go to age/weight step
                      children: [
                        _buildInfoRow(
                          icon: Icons.cake,
                          label: 'Age',
                          value: '${state.getData<int>('age')} years',
                          theme: context.theme,
                          colorScheme: colorScheme,
                        ),
                        _buildInfoRow(
                          icon: Icons.monitor_weight,
                          label: 'Weight',
                          value: _formatWeight(state),
                          theme: context.theme,
                          colorScheme: colorScheme,
                        ),
                        _buildInfoRow(
                          icon: Icons.height,
                          label: 'Height',
                          value: _formatHeight(state),
                          theme: context.theme,
                          colorScheme: colorScheme,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSizes.spacingMd),

                    // Fitness Goal Section
                    _buildSectionCard(
                      context: context,
                      theme: context.theme,
                      colorScheme: colorScheme,
                      icon: Icons.flag,
                      title: 'Fitness Goal',
                      onEdit: () => onEdit(3), // Go to goal step
                      children: [
                        _buildGoalDisplay(state, context.theme, colorScheme),
                      ],
                    ),

                    const SizedBox(height: AppSizes.spacingMd),

                    // Equipment Section
                    _buildSectionCard(
                      context: context,
                      theme: context.theme,
                      colorScheme: colorScheme,
                      icon: Icons.fitness_center,
                      title: 'Available Equipment',
                      onEdit: () => onEdit(4), // Go to equipment step
                      children: [
                        _buildEquipmentDisplay(
                          state,
                          context.theme,
                          colorScheme,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSizes.spacingMd),

                    // Dietary Section
                    _buildSectionCard(
                      context: context,
                      theme: context.theme,
                      colorScheme: colorScheme,
                      icon: Icons.restaurant,
                      title: 'Dietary Preferences',
                      onEdit: () => onEdit(5), // Go to dietary step
                      children: [
                        _buildDietaryDisplay(state, context.theme, colorScheme),
                      ],
                    ),

                    const SizedBox(height: AppSizes.spacingLg),

                    // Disclaimer
                    Container(
                      padding: const EdgeInsets.all(AppSizes.spacingMd),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: AppSizes.iconMd,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSizes.spacingSm),
                          Expanded(
                            child: Text(
                              'FitGenie provides general fitness and nutrition guidance. '
                              'Consult a healthcare professional before starting any new fitness program.',
                              style: context.theme.textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.4,
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

            // Generate Button
            Padding(
              padding: const EdgeInsets.all(AppSizes.screenMarginMobile),
              child: AppButton(
                label: AppStrings.buttonGeneratePlan,
                onPressed: onGenerate,
                fullWidth: true,
                icon: Icons.auto_awesome,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a section card with edit button.
  Widget _buildSectionCard({
    required BuildContext context,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    required VoidCallback onEdit,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingMd),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with edit button
          Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: AppSizes.iconMd),
              const SizedBox(width: AppSizes.spacingSm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: AppSizes.iconSm),
                label: const Text(AppStrings.buttonEditProfile),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacingSm,
                    vertical: AppSizes.spacingXs,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.spacingMd),

          // Content
          ...children,
        ],
      ),
    );
  }

  /// Builds an info row with icon, label, and value.
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacingSm),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppSizes.iconSm,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSizes.spacingSm),
          Text(
            '$label: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// Formats weight for display.
  String _formatWeight(state) {
    final weight = state.getData<double>('weight');
    final unit = state.getData<WeightUnit>('weightUnit');
    if (weight == null || unit == null) return 'Not set';
    return Formatters.weight(weight, unit.displayName);
  }

  /// Formats height for display.
  String _formatHeight(state) {
    final height = state.getData<double>('height');
    final unit = state.getData<HeightUnit>('heightUnit');
    if (height == null || unit == null) return 'Not set';
    return Formatters.height(height, unit.firestoreValue);
  }

  /// Builds goal display with icon.
  Widget _buildGoalDisplay(state, ThemeData theme, ColorScheme colorScheme) {
    final goal = state.getData<FitnessGoal>('goal');
    if (goal == null) {
      return Text('Not set', style: theme.textTheme.bodyMedium);
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingSm),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(goal.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: AppSizes.spacingSm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                goal.displayName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                goal.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds equipment display.
  Widget _buildEquipmentDisplay(
    state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final equipment = state.getData<EquipmentType>('equipment');
    if (equipment == null) {
      return Text('Not set', style: theme.textTheme.bodyMedium);
    }

    final details = state.getData<List<String>>('equipmentDetails') ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(equipment.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: AppSizes.spacingXs),
            Text(
              equipment.displayName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        if (details.isNotEmpty) ...[
          const SizedBox(height: AppSizes.spacingXs),
          Wrap(
            spacing: AppSizes.spacingXs,
            runSpacing: AppSizes.spacingXs,
            children: details.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacingSm,
                  vertical: AppSizes.spacing2xs,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Text(
                  item,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  /// Builds dietary restrictions display.
  Widget _buildDietaryDisplay(state, ThemeData theme, ColorScheme colorScheme) {
    final restrictions = state.getData<List<DietaryRestriction>>(
      'dietaryRestrictions',
    );
    final notes = state.getData<String>('dietaryNotes');

    if (restrictions == null || restrictions.isEmpty) {
      return Text('Not set', style: theme.textTheme.bodyMedium);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSizes.spacingXs,
          runSpacing: AppSizes.spacingXs,
          children: restrictions.map((restriction) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacingSm,
                vertical: AppSizes.spacing2xs,
              ),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(restriction.icon),
                  const SizedBox(width: AppSizes.spacing2xs),
                  Text(
                    restriction.displayName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        if (notes != null && notes.isNotEmpty) ...[
          const SizedBox(height: AppSizes.spacingSm),
          Text(
            'Additional notes:',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSizes.spacing2xs),
          Text(
            notes,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
