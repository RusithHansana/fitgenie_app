import 'package:fitgenie_app/core/constants/app_sizes.dart';
import 'package:fitgenie_app/core/constants/app_strings.dart';
import 'package:fitgenie_app/core/constants/dietary_options.dart';
import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:fitgenie_app/core/utils/validators.dart';
import 'package:fitgenie_app/features/onboarding/domain/user_profile.dart';
import 'package:fitgenie_app/features/profile/profile_providers.dart';
import 'package:fitgenie_app/shared/widgets/app_button.dart';
import 'package:fitgenie_app/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen for editing user profile information.
///
/// This screen provides a form for users to update their profile data including:
/// - Age, weight, height (biometric data)
/// - Fitness goal selection
/// - Equipment type and details
/// - Dietary restrictions
///
/// After saving, if significant changes are detected (goal, equipment, or diet),
/// the user is prompted to regenerate their plan to reflect the updates.
///
/// The screen uses a StatefulWidget to manage form state and validation,
/// with Riverpod for data persistence and navigation.
///
/// Route: `/profile/edit`
///
/// Usage:
/// ```dart
/// // In router configuration
/// GoRoute(
///   path: '/profile/edit',
///   builder: (context, state) => const EditProfileScreen(),
/// )
/// ```
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  UserProfile? _originalProfile;

  // Form controllers
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _dietaryNotesController;

  // Form state
  WeightUnit _weightUnit = WeightUnit.kg;
  HeightUnit _heightUnit = HeightUnit.cm;
  FitnessGoal? _selectedGoal;
  EquipmentType? _selectedEquipment;
  final Set<String> _selectedEquipmentDetails = {};
  final Set<DietaryRestriction> _selectedDietaryRestrictions = {};

  // Available equipment options
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
    _ageController = TextEditingController();
    _weightController = TextEditingController();
    _heightController = TextEditingController();
    _dietaryNotesController = TextEditingController();
    _loadProfileData();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _dietaryNotesController.dispose();
    super.dispose();
  }

  /// Loads existing profile data into form fields.
  Future<void> _loadProfileData() async {
    final profileAsync = ref.read(profileProvider);
    final profile = profileAsync.value;

    if (profile != null) {
      setState(() {
        _originalProfile = profile;
        _ageController.text = profile.age.toString();
        _weightController.text = profile.weight.toString();
        _weightUnit = profile.weightUnit;
        _heightController.text = profile.height.toString();
        _heightUnit = profile.heightUnit;
        _selectedGoal = profile.goal;
        _selectedEquipment = profile.equipment;
        _selectedEquipmentDetails.addAll(profile.equipmentDetails);
        _selectedDietaryRestrictions.addAll(profile.dietaryRestrictions);
        _dietaryNotesController.text = profile.dietaryNotes ?? '';
      });
    }
  }

  /// Validates and saves the updated profile.
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedGoal == null || _selectedEquipment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Build updated profile
      final updatedProfile = UserProfile(
        age: int.parse(_ageController.text),
        weight: double.parse(_weightController.text),
        weightUnit: _weightUnit,
        height: double.parse(_heightController.text),
        heightUnit: _heightUnit,
        goal: _selectedGoal!,
        equipment: _selectedEquipment!,
        equipmentDetails: _selectedEquipmentDetails.toList(),
        dietaryRestrictions: _selectedDietaryRestrictions.toList(),
        dietaryNotes: _dietaryNotesController.text.trim().isEmpty
            ? null
            : _dietaryNotesController.text.trim(),
      );

      // Save profile
      await ref.read(updateProfileProvider(updatedProfile).future);

      if (!mounted) return;

      // Check if significant changes warrant plan regeneration
      if (_originalProfile != null) {
        final hasChanges = ref.read(
          hasSignificantChangesProvider(_originalProfile!, updatedProfile),
        );

        if (hasChanges) {
          await _showRegenerationPrompt();
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.successProfileUpdated)),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: context.colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Shows dialog prompting user to regenerate plan after significant changes.
  Future<void> _showRegenerationPrompt() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate Plan?'),
        content: const Text(
          'You\'ve made significant changes to your profile. Would you like to regenerate your plan to reflect these updates?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      // TODO: Navigate to plan generation when implemented
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plan regeneration will be available soon'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profileEditTitle),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.screenMarginMobile),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Biometric section
              _buildSectionHeader('Personal Information'),
              const SizedBox(height: AppSizes.spacingMd),
              _buildBiometricFields(),

              const SizedBox(height: AppSizes.spacingXl),

              // Goal section
              _buildSectionHeader(AppStrings.sectionGoal),
              const SizedBox(height: AppSizes.spacingMd),
              _buildGoalSelection(),

              const SizedBox(height: AppSizes.spacingXl),

              // Equipment section
              _buildSectionHeader(AppStrings.sectionEquipment),
              const SizedBox(height: AppSizes.spacingMd),
              _buildEquipmentSelection(),

              const SizedBox(height: AppSizes.spacingXl),

              // Dietary section
              _buildSectionHeader(AppStrings.sectionDietary),
              const SizedBox(height: AppSizes.spacingMd),
              _buildDietarySelection(),

              const SizedBox(height: AppSizes.spacingXl),

              // Action buttons
              _buildActionButtons(),

              const SizedBox(height: AppSizes.spacingXl),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds section header text.
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: context.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: context.colorScheme.onSurface,
      ),
    );
  }

  /// Builds biometric input fields (age, weight, height).
  Widget _buildBiometricFields() {
    return Column(
      children: [
        // Age
        AppTextField(
          controller: _ageController,
          label: AppStrings.labelAge,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: Validators.age,
        ),

        const SizedBox(height: AppSizes.spacingMd),

        // Weight
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: AppTextField(
                controller: _weightController,
                label: AppStrings.labelWeight,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                ],
                validator: Validators.weight,
              ),
            ),
            const SizedBox(width: AppSizes.spacingMd),
            Expanded(
              child: DropdownButtonFormField<WeightUnit>(
                initialValue: _weightUnit,
                decoration: const InputDecoration(
                  labelText: AppStrings.labelWeightUnit,
                ),
                items: WeightUnit.values.map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text(unit.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _weightUnit = value);
                  }
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSizes.spacingMd),

        // Height
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: AppTextField(
                controller: _heightController,
                label: AppStrings.labelHeight,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                ],
                validator: Validators.height,
              ),
            ),
            const SizedBox(width: AppSizes.spacingMd),
            Expanded(
              child: DropdownButtonFormField<HeightUnit>(
                initialValue: _heightUnit,
                decoration: const InputDecoration(
                  labelText: AppStrings.labelHeightUnit,
                ),
                items: HeightUnit.values.map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text(unit.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _heightUnit = value);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds fitness goal selection cards.
  Widget _buildGoalSelection() {
    return Wrap(
      spacing: AppSizes.spacingMd,
      runSpacing: AppSizes.spacingMd,
      children: FitnessGoal.values.map((goal) {
        final isSelected = _selectedGoal == goal;
        return ChoiceChip(
          label: Text(goal.displayName),
          selected: isSelected,
          onSelected: (selected) {
            setState(() => _selectedGoal = goal);
          },
        );
      }).toList(),
    );
  }

  /// Builds equipment type selection.
  Widget _buildEquipmentSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSizes.spacingMd,
          runSpacing: AppSizes.spacingMd,
          children: EquipmentType.values.map((equipment) {
            final isSelected = _selectedEquipment == equipment;
            return ChoiceChip(
              label: Text(equipment.displayName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedEquipment = equipment;
                  if (!equipment.requiresDetails) {
                    _selectedEquipmentDetails.clear();
                  }
                });
              },
            );
          }).toList(),
        ),

        // Equipment details (if required)
        if (_selectedEquipment?.requiresDetails ?? false) ...[
          const SizedBox(height: AppSizes.spacingMd),
          Text(
            'Select your equipment:',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSizes.spacingSm),
          Wrap(
            spacing: AppSizes.spacingSm,
            runSpacing: AppSizes.spacingSm,
            children: _equipmentOptions.map((equipment) {
              final isSelected = _selectedEquipmentDetails.contains(equipment);
              return FilterChip(
                label: Text(equipment),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedEquipmentDetails.add(equipment);
                    } else {
                      _selectedEquipmentDetails.remove(equipment);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  /// Builds dietary restrictions selection.
  Widget _buildDietarySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSizes.spacingSm,
          runSpacing: AppSizes.spacingSm,
          children: DietaryRestriction.values.map((restriction) {
            final isSelected = _selectedDietaryRestrictions.contains(
              restriction,
            );
            return FilterChip(
              label: Text(restriction.displayName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedDietaryRestrictions.add(restriction);
                  } else {
                    _selectedDietaryRestrictions.remove(restriction);
                  }
                });
              },
            );
          }).toList(),
        ),

        const SizedBox(height: AppSizes.spacingMd),

        AppTextField(
          controller: _dietaryNotesController,
          label: AppStrings.labelDietaryNotes,
          hint: AppStrings.placeholderDietaryNotes,
          maxLines: 3,
        ),
      ],
    );
  }

  /// Builds action buttons (Save and Cancel).
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text(AppStrings.buttonCancel),
          ),
        ),
        const SizedBox(width: AppSizes.spacingMd),
        Expanded(
          child: AppButton(
            onPressed: _isLoading ? null : _handleSave,
            isLoading: _isLoading,
            label: AppStrings.buttonSave,
          ),
        ),
      ],
    );
  }
}
