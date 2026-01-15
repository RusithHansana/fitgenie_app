import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitgenie_app/core/constants/app_strings.dart';
import 'package:fitgenie_app/core/constants/app_sizes.dart';
import 'package:fitgenie_app/core/constants/dietary_options.dart';
import 'package:fitgenie_app/shared/widgets/app_text_field.dart';
import 'package:fitgenie_app/shared/widgets/app_button.dart';
import 'package:fitgenie_app/features/onboarding/onboarding_providers.dart';

/// Step for selecting dietary restrictions and preferences.
///
/// This step allows users to specify any dietary restrictions that must be
/// respected in their meal planning. Multiple selections are allowed, and
/// the app validates that selections don't conflict (e.g., vegan + pescatarian).
///
/// Features:
/// - Multi-select chip list for common restrictions
/// - "None" option that clears all other selections
/// - Optional notes field for allergies and additional details
/// - Conflict validation between restrictions
/// - Clear visual feedback for selected restrictions
///
/// Usage:
/// ```dart
/// DietaryStep(
///   onNext: () {
///     // Advance to next step
///   },
/// )
/// ```
class DietaryStep extends ConsumerStatefulWidget {
  /// Callback invoked when user completes this step and taps Next.
  final VoidCallback onNext;

  const DietaryStep({super.key, required this.onNext});

  @override
  ConsumerState<DietaryStep> createState() => _DietaryStepState();
}

class _DietaryStepState extends ConsumerState<DietaryStep> {
  final Set<DietaryRestriction> _selectedRestrictions = {};
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  /// Loads previously selected restrictions if user returns to this step.
  void _loadExistingData() {
    final state = ref.read(onboardingStateProviderProvider);

    final restrictions = state.getData<List<DietaryRestriction>>(
      'dietaryRestrictions',
    );
    if (restrictions != null) {
      _selectedRestrictions.addAll(restrictions);
    } else {
      // Default to "none" if nothing selected
      _selectedRestrictions.add(DietaryRestriction.none);
    }

    final notes = state.getData<String>('dietaryNotes');
    if (notes != null) {
      _notesController.text = notes;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Toggles a dietary restriction.
  void _toggleRestriction(DietaryRestriction restriction) {
    setState(() {
      if (restriction == DietaryRestriction.none) {
        // If "none" is selected, clear all other restrictions
        _selectedRestrictions.clear();
        _selectedRestrictions.add(DietaryRestriction.none);
      } else {
        // If selecting a specific restriction, remove "none"
        _selectedRestrictions.remove(DietaryRestriction.none);

        // Toggle the selected restriction
        if (_selectedRestrictions.contains(restriction)) {
          _selectedRestrictions.remove(restriction);
          // If nothing left, add "none"
          if (_selectedRestrictions.isEmpty) {
            _selectedRestrictions.add(DietaryRestriction.none);
          }
        } else {
          // Check for conflicts before adding
          bool hasConflict = false;
          for (final existing in _selectedRestrictions) {
            if (restriction.conflictsWith(existing)) {
              hasConflict = true;
              _showConflictMessage(restriction, existing);
              break;
            }
          }
          if (!hasConflict) {
            _selectedRestrictions.add(restriction);
          }
        }
      }
    });
  }

  /// Shows a message when conflicting restrictions are selected.
  void _showConflictMessage(
    DietaryRestriction newRestriction,
    DietaryRestriction existingRestriction,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${newRestriction.displayName} conflicts with ${existingRestriction.displayName}',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Validates selection and saves data.
  void _handleNext() {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    // Validate selection
    if (!DietaryRestrictionHelper.validateSelection(
      _selectedRestrictions.toList(),
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid dietary restriction selection'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Save to onboarding state
    ref.read(onboardingStateProviderProvider.notifier).updateMultipleData({
      'dietaryRestrictions': _selectedRestrictions.toList(),
      'dietaryNotes': _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    });

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dietary Preferences'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: 6 / 7, // Step 6 of 7
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
                      AppStrings.onboardingDietaryTitle,
                      style: context.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: AppSizes.spacingSm),

                    // Description
                    Text(
                      AppStrings.onboardingDietaryDescription,
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: AppSizes.spacingXl),

                    // Dietary restriction chips
                    _buildRestrictionChips(context.theme, colorScheme),

                    const SizedBox(height: AppSizes.spacingLg),

                    // Additional notes
                    AppTextField(
                      controller: _notesController,
                      label: AppStrings.labelDietaryNotes,
                      hint: AppStrings.placeholderDietaryNotes,
                      prefixIcon: Icons.note_outlined,
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
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
                            Icons.restaurant,
                            size: AppSizes.iconMd,
                            color: colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: AppSizes.spacingSm),
                          Expanded(
                            child: Text(
                              'All meal suggestions will respect your dietary restrictions. You can select multiple options.',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Show selected summary if multiple selected
                    if (_selectedRestrictions.length > 1 ||
                        (_selectedRestrictions.length == 1 &&
                            !_selectedRestrictions.first.isNone)) ...[
                      const SizedBox(height: AppSizes.spacingMd),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSizes.spacingMd),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: AppSizes.iconSm,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: AppSizes.spacingXs),
                                Text(
                                  'Selected restrictions:',
                                  style: context.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.spacingXs),
                            Text(
                              DietaryRestrictionHelper.formatMultiple(
                                _selectedRestrictions.toList(),
                              ),
                              style: context.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

  /// Builds the dietary restriction chip list.
  Widget _buildRestrictionChips(ThemeData theme, ColorScheme colorScheme) {
    return Wrap(
      spacing: AppSizes.spacingSm,
      runSpacing: AppSizes.spacingSm,
      children: [
        // "None" option first
        _buildRestrictionChip(
          restriction: DietaryRestriction.none,
          theme: theme,
          colorScheme: colorScheme,
        ),
        // All other options
        ...DietaryRestrictionHelper.selectableOptions.map(
          (restriction) => _buildRestrictionChip(
            restriction: restriction,
            theme: theme,
            colorScheme: colorScheme,
          ),
        ),
      ],
    );
  }

  /// Builds a single dietary restriction chip.
  Widget _buildRestrictionChip({
    required DietaryRestriction restriction,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _selectedRestrictions.contains(restriction);

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(restriction.icon),
          const SizedBox(width: AppSizes.spacingXs),
          Text(restriction.displayName),
        ],
      ),
      onSelected: (_) => _toggleRestriction(restriction),
      backgroundColor: colorScheme.surface,
      selectedColor: colorScheme.primaryContainer,
      showCheckmark: true,
      side: BorderSide(
        color: isSelected
            ? colorScheme.primary
            : colorScheme.outline.withValues(alpha: 0.3),
      ),
      tooltip: restriction.description,
    );
  }
}
