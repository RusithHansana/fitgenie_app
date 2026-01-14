import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitgenie_app/core/constants/app_strings.dart';
import 'package:fitgenie_app/core/constants/app_sizes.dart';
import 'package:fitgenie_app/shared/widgets/app_text_field.dart';
import 'package:fitgenie_app/shared/widgets/app_button.dart';
import 'package:fitgenie_app/features/onboarding/domain/user_profile.dart';
import 'package:fitgenie_app/features/onboarding/onboarding_providers.dart';

/// Step for selecting available equipment type and specific items.
///
/// This is a key differentiator for FitGenie - users specify their equipment,
/// ensuring generated workouts use only what they actually have available.
/// This step is critical for trust-building as users see equipment tags
/// on their generated plans.
///
/// Features:
/// - Equipment category selection (Full Gym, Home Gym, Bodyweight, Mixed)
/// - Conditional details picker for Home Gym and Mixed
/// - Checkbox list for specific equipment items
/// - Custom equipment text input option
/// - Equipment validation before proceeding
///
/// Usage:
/// ```dart
/// EquipmentStep(
///   onNext: () {
///     // Advance to next step
///   },
/// )
/// ```
class EquipmentStep extends ConsumerStatefulWidget {
  /// Callback invoked when user completes this step and taps Next.
  final VoidCallback onNext;

  const EquipmentStep({super.key, required this.onNext});

  @override
  ConsumerState<EquipmentStep> createState() => _EquipmentStepState();
}

class _EquipmentStepState extends ConsumerState<EquipmentStep> {
  EquipmentType? _selectedEquipment;
  final Set<String> _selectedDetails = {};
  final TextEditingController _customEquipmentController =
      TextEditingController();

  /// Available equipment options for home gym / mixed.
  static const List<String> _equipmentOptions = [
    'Dumbbells',
    'Barbell',
    'Pull-up bar',
    'Resistance bands',
    'Kettlebells',
    'Medicine ball',
    'Yoga mat',
    'Bench',
    'Treadmill',
    'Stationary bike',
    'Rowing machine',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  /// Loads previously selected equipment if user returns to this step.
  void _loadExistingData() {
    final state = ref.read(onboardingStateProviderProvider);

    final equipment = state.getData<EquipmentType>('equipment');
    if (equipment != null) {
      _selectedEquipment = equipment;
    }

    final details = state.getData<List<String>>('equipmentDetails');
    if (details != null) {
      _selectedDetails.addAll(details);
    }

    final custom = state.getData<String>('equipmentCustom');
    if (custom != null) {
      _customEquipmentController.text = custom;
    }
  }

  @override
  void dispose() {
    _customEquipmentController.dispose();
    super.dispose();
  }

  /// Handles equipment type selection.
  void _selectEquipment(EquipmentType equipment) {
    setState(() {
      _selectedEquipment = equipment;
      // Clear details when switching types
      if (!equipment.requiresDetails) {
        _selectedDetails.clear();
        _customEquipmentController.clear();
      }
    });
  }

  /// Toggles an equipment detail checkbox.
  void _toggleEquipmentDetail(String detail) {
    setState(() {
      if (_selectedDetails.contains(detail)) {
        _selectedDetails.remove(detail);
      } else {
        _selectedDetails.add(detail);
      }
    });
  }

  /// Validates equipment selection and saves data.
  void _handleNext() {
    if (_selectedEquipment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your equipment type'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // For home gym and mixed, require at least one equipment selection
    if (_selectedEquipment!.requiresDetails && _selectedDetails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one equipment item'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Save to onboarding state
    final equipmentList = _selectedDetails.toList();
    if (_customEquipmentController.text.trim().isNotEmpty) {
      equipmentList.add(_customEquipmentController.text.trim());
    }

    ref.read(onboardingStateProviderProvider.notifier).updateMultipleData({
      'equipment': _selectedEquipment,
      'equipmentDetails': equipmentList,
    });

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: 5 / 7, // Step 5 of 7
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
                      AppStrings.onboardingEquipmentTitle,
                      style: context.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: AppSizes.spacingSm),

                    // Description
                    Text(
                      AppStrings.onboardingEquipmentDescription,
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: AppSizes.spacingXl),

                    // Equipment type selection
                    _buildEquipmentTypeCard(
                      type: EquipmentType.fullGym,
                      theme: context.theme,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: AppSizes.spacingSm),
                    _buildEquipmentTypeCard(
                      type: EquipmentType.homeGym,
                      theme: context.theme,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: AppSizes.spacingSm),
                    _buildEquipmentTypeCard(
                      type: EquipmentType.bodyweight,
                      theme: context.theme,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: AppSizes.spacingSm),
                    _buildEquipmentTypeCard(
                      type: EquipmentType.mixed,
                      theme: context.theme,
                      colorScheme: colorScheme,
                    ),

                    // Equipment details if applicable
                    if (_selectedEquipment != null &&
                        _selectedEquipment!.requiresDetails) ...[
                      const SizedBox(height: AppSizes.spacingLg),
                      Text(
                        'What equipment do you have?',
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacingSm),
                      _buildEquipmentCheckboxes(context.theme, colorScheme),
                      const SizedBox(height: AppSizes.spacingMd),
                      AppTextField(
                        controller: _customEquipmentController,
                        label: 'Other equipment (optional)',
                        hint: 'e.g., suspension trainer, foam roller',
                        prefixIcon: Icons.add_circle_outline,
                      ),
                    ],

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
                            Icons.info_outline,
                            size: AppSizes.iconMd,
                            color: colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: AppSizes.spacingSm),
                          Expanded(
                            child: Text(
                              'Your selected equipment will appear on your workouts. We\'ll never suggest exercises you can\'t do.',
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

  /// Builds an equipment type selection card.
  Widget _buildEquipmentTypeCard({
    required EquipmentType type,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _selectedEquipment == type;

    return InkWell(
      onTap: () => _selectEquipment(type),
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
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Center(
                child: Text(type.icon, style: const TextStyle(fontSize: 24)),
              ),
            ),

            const SizedBox(width: AppSizes.spacingMd),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    type.description,
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
              Icon(Icons.check_circle, color: colorScheme.primary)
            else
              Icon(Icons.circle_outlined, color: colorScheme.outline),
          ],
        ),
      ),
    );
  }

  /// Builds the equipment checkbox list.
  Widget _buildEquipmentCheckboxes(ThemeData theme, ColorScheme colorScheme) {
    return Wrap(
      spacing: AppSizes.spacingSm,
      runSpacing: AppSizes.spacingSm,
      children: _equipmentOptions.map((equipment) {
        final isSelected = _selectedDetails.contains(equipment);

        return FilterChip(
          selected: isSelected,
          label: Text(equipment),
          onSelected: (_) => _toggleEquipmentDetail(equipment),
          backgroundColor: colorScheme.surface,
          selectedColor: colorScheme.primaryContainer,
          showCheckmark: true,
          side: BorderSide(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.3),
          ),
        );
      }).toList(),
    );
  }
}
