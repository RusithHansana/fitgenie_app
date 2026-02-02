import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable text input widget with consistent styling and validation support.
///
/// This widget wraps [TextFormField] to provide a unified input interface
/// across the app with Material 3 styling, automatic validation integration,
/// and special handling for password fields with visibility toggle.
///
/// Features:
/// - Consistent Material 3 input decoration from theme
/// - Form validation integration via [FormFieldValidator]
/// - Password visibility toggle for secure inputs
/// - Prefix/suffix icon support
/// - Keyboard type and input action configuration
/// - Auto-validation on user interaction
/// - Max length with counter display
///
/// Usage:
/// ```dart
/// AppTextField(
///   controller: _emailController,
///   label: 'Email',
///   hint: 'your.email@example.com',
///   keyboardType: TextInputType.emailAddress,
///   validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
/// )
/// ```
///
/// Password field usage:
/// ```dart
/// AppTextField(
///   controller: _passwordController,
///   label: 'Password',
///   obscureText: true,
///   validator: Validators.password,
/// )
/// ```
class AppTextField extends StatefulWidget {
  /// Controller for the text field.
  ///
  /// Required to manage the text input state externally.
  final TextEditingController controller;

  /// Label text displayed above the input field.
  ///
  /// Animates to top position when field is focused or has content.
  final String label;

  /// Hint text displayed when field is empty and unfocused.
  ///
  /// Provides additional guidance about expected input format.
  final String? hint;

  /// Validator function for form validation.
  ///
  /// Called automatically when form is validated or on user interaction
  /// if [autovalidateMode] is enabled. Return error message string if
  /// validation fails, or null if valid.
  final String? Function(String?)? validator;

  /// Whether to obscure the text input (for passwords).
  ///
  /// When true, displays dots/asterisks instead of actual characters
  /// and shows a visibility toggle icon in the suffix position.
  ///
  /// Defaults to false.
  final bool obscureText;

  /// Icon to display before the input field.
  ///
  /// Typically used for semantic indication of field type
  /// (e.g., Icons.email for email fields).
  final IconData? prefixIcon;

  /// Icon to display after the input field.
  ///
  /// Note: For password fields ([obscureText] = true), the suffix position
  /// is automatically used for the visibility toggle icon.
  final IconData? suffixIcon;

  /// Keyboard type for the input.
  ///
  /// Affects the on-screen keyboard layout shown to users.
  /// Examples: [TextInputType.emailAddress], [TextInputType.number]
  final TextInputType keyboardType;

  /// Text input action button shown on keyboard.
  ///
  /// Determines the action button on the keyboard (e.g., "Next", "Done").
  /// Defaults to [TextInputAction.next].
  final TextInputAction textInputAction;

  /// Whether the field is enabled for input.
  ///
  /// When false, field is visually disabled and does not accept input.
  /// Defaults to true.
  final bool enabled;

  /// Maximum number of characters allowed.
  ///
  /// When set, displays a character counter and prevents input beyond limit.
  final int? maxLength;

  /// Maximum number of lines for the input field.
  ///
  /// For single-line inputs, use 1 (default).
  /// For multiline text areas, use null or a specific line count.
  final int? maxLines;

  /// Minimum number of lines for multiline inputs.
  ///
  /// Only applicable when [maxLines] is null or > 1.
  final int? minLines;

  /// Callback invoked when field value changes.
  ///
  /// Useful for real-time validation or dependent field updates.
  final void Function(String)? onChanged;

  /// Callback invoked when user submits the field (e.g., presses Done).
  final void Function(String)? onSubmitted;

  /// List of input formatters to apply to the field.
  ///
  /// Examples: number-only, capitalization, custom masking.
  final List<TextInputFormatter>? inputFormatters;

  /// Autofill hints for platform autofill support.
  ///
  /// Examples: [AutofillHints.email], [AutofillHints.password]
  final Iterable<String>? autofillHints;

  /// Creates an [AppTextField] with the specified properties.
  ///
  /// The [controller] and [label] parameters are required.
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.enabled = true,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.autofillHints,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  /// Internal state for password visibility toggle.
  ///
  /// Only used when [widget.obscureText] is true.
  bool _isObscured = true;

  @override
  void initState() {
    super.initState();
    // Initialize obscured state based on widget property
    _isObscured = widget.obscureText;
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset obscured state if obscureText property changes
    if (oldWidget.obscureText != widget.obscureText) {
      _isObscured = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
        suffixIcon: _buildSuffixIcon(),
        enabled: widget.enabled,
        fillColor: context.colorScheme.surfaceContainer,
        // Counter is automatically added by TextFormField when maxLength is set
      ),
      obscureText: widget.obscureText && _isObscured,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      enabled: widget.enabled,
      maxLength: widget.maxLength,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.minLines,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      inputFormatters: widget.inputFormatters,
      autofillHints: widget.autofillHints,
      // Auto-validate after first interaction to provide immediate feedback
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  /// Builds the suffix icon based on field type.
  ///
  /// For password fields ([obscureText] = true), shows visibility toggle.
  /// For other fields, shows the provided [suffixIcon] if any.
  Widget? _buildSuffixIcon() {
    if (widget.obscureText) {
      // Password field - show visibility toggle
      return IconButton(
        icon: Icon(
          _isObscured
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
        ),
        onPressed: widget.enabled
            ? () {
                setState(() {
                  _isObscured = !_isObscured;
                });
              }
            : null,
        tooltip: _isObscured ? 'Show password' : 'Hide password',
      );
    } else if (widget.suffixIcon != null) {
      // Non-password field with custom suffix icon
      return Icon(widget.suffixIcon);
    }
    return null;
  }
}
