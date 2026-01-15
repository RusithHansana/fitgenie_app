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

/// Step collecting user's height with unit selection.
///
/// This step handles both metric (cm) and imperial (ft/in) height inputs.
/// For imperial, it provides separate feet and inches inputs and converts
/// to total inches for internal storage.
///
/// Features:
/// - Height input with unit selector
/// - Metric mode: single input in centimeters
/// - Imperial mode: separate feet and inches inputs
/// - Automatic conversion and validation
/// - Restores previously entered values if user returns
///
/// Usage:
/// ```dart
/// HeightStep(
///   onNext: () {
///     // Advance to next step
///   },
/// )
/// ```
class HeightStep extends ConsumerStatefulWidget {
  /// Callback invoked when user completes this step and taps Next.
  final VoidCallback onNext;

  const HeightStep({super.key, required this.onNext});

  @override
  ConsumerState<HeightStep> createState() => _HeightStepState();
}

class _HeightStepState extends ConsumerState<HeightStep> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _heightController; // For cm
  late final TextEditingController _feetController; // For imperial feet
  late final TextEditingController _inchesController; // For imperial inches
  HeightUnit _selectedUnit = HeightUnit.cm;

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController();
    _feetController = TextEditingController();
    _inchesController = TextEditingController();
    _loadExistingData();
  }

  /// Loads previously entered data if user returns to this step.
  void _loadExistingData() {
    final state = ref.read(onboardingStateProviderProvider);

    final unit = state.getData<HeightUnit>('heightUnit');
    if (unit != null) {
      _selectedUnit = unit;
    }

    final height = state.getData<double>('height');
    if (height != null) {
      if (_selectedUnit == HeightUnit.cm) {
        _heightController.text = height.toInt().toString();
      } else {
        // Height is stored as total inches for imperial
        final totalInches = height.toInt();
        final feet = totalInches ~/ 12;
        final inches = totalInches % 12;
        _feetController.text = feet.toString();
        _inchesController.text = inches.toString();
      }
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    super.dispose();
  }

  /// Validates form and saves data to onboarding state.
  void _handleNext() {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() ?? false) {
      double heightValue;

      if (_selectedUnit == HeightUnit.cm) {
        // Store cm value directly
        heightValue = double.parse(_heightController.text.trim());
      } else {
        // Convert ft/in to total inches for storage
        final feet = int.parse(_feetController.text.trim());
        final inches = int.parse(_inchesController.text.trim());
        heightValue = (feet * 12 + inches).toDouble();
      }

      ref.read(onboardingStateProviderProvider.notifier).updateMultipleData({
        'height': heightValue,
        'heightUnit': _selectedUnit,
      });

      // Proceed to next step
      widget.onNext();
    }
  }

  /// Validates feet input (3-8 feet is reasonable range).
  String? _validateFeet(String? value) {
    return Validators.compose([
      Validators.required,
      Validators.numeric,
      Validators.range(3, 8),
    ])(value);
  }

  /// Validates inches input (0-11 inches).
  String? _validateInches(String? value) {
    return Validators.compose([
      Validators.required,
      Validators.numeric,
      Validators.range(0, 11),
    ])(value);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Height'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: 3 / 7, // Step 3 of 7
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
                        AppStrings.onboardingHeightTitle,
                        style: context.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),

                      const SizedBox(height: AppSizes.spacingSm),

                      // Description
                      Text(
                        AppStrings.onboardingHeightDescription,
                        style: context.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: AppSizes.spacingXl),

                      // Height Unit Selector
                      Text(
                        AppStrings.labelHeightUnit,
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),

                      const SizedBox(height: AppSizes.spacingSm),

                      SegmentedButton<HeightUnit>(
                        segments: [
                          const ButtonSegment<HeightUnit>(
                            value: HeightUnit.cm,
                            label: Text(AppStrings.unitCm),
                            icon: Icon(Icons.straighten),
                          ),
                          const ButtonSegment<HeightUnit>(
                            value: HeightUnit.ftIn,
                            label: Text(AppStrings.unitFtIn),
                            icon: Icon(Icons.straighten),
                          ),
                        ],
                        selected: {_selectedUnit},
                        onSelectionChanged: (Set<HeightUnit> selected) {
                          setState(() {
                            _selectedUnit = selected.first;
                            // Clear inputs when switching units
                            _heightController.clear();
                            _feetController.clear();
                            _inchesController.clear();
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

                      const SizedBox(height: AppSizes.spacingXl),

                      // Conditional input based on selected unit
                      if (_selectedUnit == HeightUnit.cm)
                        _buildMetricInput()
                      else
                        _buildImperialInput(),

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
                                'We\'ll use this to calculate your fitness metrics and personalize your plan.',
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

  /// Builds the metric (cm) input field.
  Widget _buildMetricInput() {
    return AppTextField(
      controller: _heightController,
      label: AppStrings.labelHeight,
      hint: 'e.g., 180',
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      prefixIcon: Icons.height,
      validator: Validators.height,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3),
      ],
      onSubmitted: (_) => _handleNext(),
    );
  }

  /// Builds the imperial (ft/in) input fields.
  Widget _buildImperialInput() {
    return Row(
      children: [
        // Feet input
        Expanded(
          child: AppTextField(
            controller: _feetController,
            label: 'Feet',
            hint: 'e.g., 5',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.height,
            validator: _validateFeet,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
          ),
        ),

        const SizedBox(width: AppSizes.spacingMd),

        // Inches input
        Expanded(
          child: AppTextField(
            controller: _inchesController,
            label: 'Inches',
            hint: 'e.g., 11',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.height,
            validator: _validateInches,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            onSubmitted: (_) => _handleNext(),
          ),
        ),
      ],
    );
  }
}
