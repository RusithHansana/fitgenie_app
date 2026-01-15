import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitgenie_app/core/constants/app_strings.dart';
import 'package:fitgenie_app/core/constants/app_sizes.dart';
import 'package:fitgenie_app/core/utils/validators.dart';
import 'package:fitgenie_app/shared/widgets/app_text_field.dart';
import 'package:fitgenie_app/shared/widgets/app_button.dart';
import 'package:fitgenie_app/features/onboarding/domain/user_profile.dart';
import 'package:fitgenie_app/features/onboarding/onboarding_providers.dart';

/// Combined step collecting user's age and weight information.
///
/// This step combines age and weight collection to reduce the total number
/// of steps in the onboarding wizard, improving completion rates while
/// maintaining clarity.
///
/// Features:
/// - Age input with validation (13-100)
/// - Weight input with decimal support
/// - Weight unit selector (kg/lbs)
/// - Form validation before proceeding
/// - Restores previously entered values if user returns to this step
///
/// Usage:
/// ```dart
/// AgeWeightStep(
///   onNext: () {
///     // Advance to next step
///   },
/// )
/// ```
class AgeWeightStep extends ConsumerStatefulWidget {
  /// Callback invoked when user completes this step and taps Next.
  final VoidCallback onNext;

  const AgeWeightStep({super.key, required this.onNext});

  @override
  ConsumerState<AgeWeightStep> createState() => _AgeWeightStepState();
}

class _AgeWeightStepState extends ConsumerState<AgeWeightStep> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  WeightUnit _selectedUnit = WeightUnit.kg;

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController();
    _weightController = TextEditingController();
    _loadExistingData();
  }

  /// Loads previously entered data if user returns to this step.
  void _loadExistingData() {
    final state = ref.read(onboardingStateProviderProvider);

    final age = state.getData<int>('age');
    if (age != null) {
      _ageController.text = age.toString();
    }

    final weight = state.getData<double>('weight');
    if (weight != null) {
      _weightController.text = weight.toString();
    }

    final unit = state.getData<WeightUnit>('weightUnit');
    if (unit != null) {
      _selectedUnit = unit;
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  /// Validates form and saves data to onboarding state.
  void _handleNext() {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() ?? false) {
      // Parse and save data
      final age = int.parse(_ageController.text.trim());
      final weight = double.parse(_weightController.text.trim());

      ref.read(onboardingStateProviderProvider.notifier).updateMultipleData({
        'age': age,
        'weight': weight,
        'weightUnit': _selectedUnit,
      });

      // Proceed to next step
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About You'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: 2 / 7, // Step 2 of 7
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.screenMarginMobile),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSizes.spacingMd),

                      // Title
                      Text(
                        AppStrings.onboardingAgeTitle,
                        style: context.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),

                      const SizedBox(height: AppSizes.spacingSm),

                      // Description
                      Text(
                        AppStrings.onboardingAgeDescription,
                        style: context.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: AppSizes.spacingXl),

                      // Age Input
                      AppTextField(
                        controller: _ageController,
                        label: AppStrings.labelAge,
                        hint: 'e.g., 28',
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.cake,
                        validator: Validators.age,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                      ),

                      const SizedBox(height: AppSizes.spacingLg),

                      // Weight Input
                      AppTextField(
                        controller: _weightController,
                        label: AppStrings.labelWeight,
                        hint: _selectedUnit == WeightUnit.kg
                            ? 'e.g., 75'
                            : 'e.g., 165',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.done,
                        prefixIcon: Icons.monitor_weight,
                        validator: Validators.weight,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,1}'),
                          ),
                        ],
                        onSubmitted: (_) => _handleNext(),
                      ),

                      const SizedBox(height: AppSizes.spacingLg),

                      // Weight Unit Selector
                      Text(
                        AppStrings.labelWeightUnit,
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),

                      const SizedBox(height: AppSizes.spacingSm),

                      SegmentedButton<WeightUnit>(
                        segments: [
                          const ButtonSegment<WeightUnit>(
                            value: WeightUnit.kg,
                            label: Text(AppStrings.unitKg),
                            icon: Icon(Icons.scale),
                          ),
                          const ButtonSegment<WeightUnit>(
                            value: WeightUnit.lbs,
                            label: Text(AppStrings.unitLbs),
                            icon: Icon(Icons.scale),
                          ),
                        ],
                        selected: {_selectedUnit},
                        onSelectionChanged: (Set<WeightUnit> selected) {
                          setState(() {
                            _selectedUnit = selected.first;
                          });
                        },
                        style: const ButtonStyle(
                          padding: WidgetStatePropertyAll(
                            EdgeInsets.symmetric(
                              horizontal: AppSizes.spacingMd,
                              vertical: AppSizes.spacingSm,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSizes.spacingMd),

                      // Helper text
                      Container(
                        padding: const EdgeInsets.all(AppSizes.spacingMd),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
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
                                'We use this information to create a safe and effective plan tailored to you.',
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
}
