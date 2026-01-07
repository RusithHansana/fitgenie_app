import 'package:fitgenie_app/core/constants/app_sizes.dart';
import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';

/// Reusable button widget with consistent styling and loading state support.
///
/// This widget provides a unified button interface across the app with three
/// visual variants (primary, secondary, text) that automatically inherit theme
/// styles from [AppTheme]. It handles loading states by showing a centered
/// [CircularProgressIndicator] and disabling interaction.
///
/// Features:
/// - Three button variants following Material 3 design
/// - Built-in loading state with automatic disabling
/// - Full-width option for forms and CTAs
/// - Minimum touch target size enforcement (44dp)
/// - Accessibility support via semantic labels
///
/// Usage:
/// ```dart
/// AppButton(
///   label: 'Login',
///   onPressed: _handleLogin,
///   isLoading: _isLoggingIn,
///   variant: ButtonVariant.primary,
/// )
/// ```
///
/// Variants:
/// - [ButtonVariant.primary]: Filled button for primary actions (sign up, save)
/// - [ButtonVariant.secondary]: Outlined button for secondary actions (cancel)
/// - [ButtonVariant.text]: Text button for tertiary actions (skip, back)
class AppButton extends StatelessWidget {
  /// The text label displayed on the button.
  final String label;

  /// Callback invoked when button is pressed.
  ///
  /// If null or [isLoading] is true, button will be disabled.
  final VoidCallback? onPressed;

  /// Whether the button is in loading state.
  ///
  /// When true, displays [CircularProgressIndicator] instead of label
  /// and disables [onPressed] callback.
  final bool isLoading;

  /// Visual style variant of the button.
  ///
  /// Defaults to [ButtonVariant.primary].
  final ButtonVariant variant;

  /// Whether the button should expand to full available width.
  ///
  /// When true, button uses [double.infinity] width via [SizedBox.expand].
  /// When false, button sizes to content with theme padding.
  ///
  /// Defaults to false.
  final bool fullWidth;

  /// Optional icon to display before the label.
  ///
  /// Icon is only shown when [isLoading] is false.
  final IconData? icon;

  /// Creates an [AppButton] with the specified properties.
  ///
  /// The [label] parameter is required and must not be empty.
  /// The [onPressed] callback can be null to create a disabled button.
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = ButtonVariant.primary,
    this.fullWidth = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if button should be disabled
    // Disabled if onPressed is null OR loading
    final bool isDisabled = onPressed == null || isLoading;

    // Build the button child (label with optional icon, or loading indicator)
    Widget buttonChild;
    if (isLoading) {
      // Show loading indicator with fixed size to prevent button resize
      buttonChild = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            _getLoadingIndicatorColor(context),
          ),
        ),
      );
    } else if (icon != null) {
      // Show icon + label
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: AppSizes.spacingSm),
          Text(label),
        ],
      );
    } else {
      // Show label only
      buttonChild = Text(label);
    }

    // Build the appropriate button variant
    Widget button = switch (variant) {
      ButtonVariant.primary => FilledButton(
        onPressed: isDisabled ? null : onPressed,
        child: buttonChild,
      ),
      ButtonVariant.secondary => OutlinedButton(
        onPressed: isDisabled ? null : onPressed,
        child: buttonChild,
      ),
      ButtonVariant.text => TextButton(
        onPressed: isDisabled ? null : onPressed,
        child: buttonChild,
      ),
    };

    // Wrap in SizedBox for full width if needed
    if (fullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }

    // Ensure minimum touch target height
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizes.touchTargetMin),
      child: button,
    );
  }

  /// Returns the appropriate loading indicator color based on variant.
  ///
  /// - Primary: Uses onPrimary color (white on colored background)
  /// - Secondary: Uses primary color (colored on transparent background)
  /// - Text: Uses primary color (colored on transparent background)
  Color _getLoadingIndicatorColor(BuildContext context) {
    return switch (variant) {
      ButtonVariant.primary => context.colorScheme.onPrimary,
      ButtonVariant.secondary => context.colorScheme.primary,
      ButtonVariant.text => context.colorScheme.primary,
    };
  }
}

/// Visual style variants for [AppButton].
///
/// Each variant corresponds to a different Material 3 button type with
/// appropriate styling for its semantic meaning in the interface.
enum ButtonVariant {
  /// Filled button with primary color background.
  ///
  /// Used for primary actions that are the main focus of the screen.
  /// Examples: "Login", "Sign Up", "Generate Plan", "Save"
  primary,

  /// Outlined button with border and no background fill.
  ///
  /// Used for secondary actions that are important but not primary.
  /// Examples: "Cancel", "Edit", "Skip for now"
  secondary,

  /// Text-only button with no border or background.
  ///
  /// Used for tertiary actions and less prominent options.
  /// Examples: "Forgot Password?", "Back", "Learn More"
  text,
}
