import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:fitgenie_app/shared/widgets/app_text_field.dart';
import 'package:fitgenie_app/shared/widgets/app_button.dart';
import 'package:fitgenie_app/core/utils/validators.dart';

/// Enum defining the mode of the authentication form.
enum AuthMode {
  /// Login mode - sign in with existing account
  login,

  /// Register mode - create new account
  register,
}

/// Reusable authentication form widget for login and registration.
///
/// This widget provides a stateful form with email and password fields,
/// validation, and submission handling. It can be used in both login
/// and registration contexts by setting the appropriate [mode].
///
/// Features:
/// - Email and password validation using [Validators]
/// - Loading state with disabled inputs during submission
/// - Error display for both field-level and form-level errors
/// - Keyboard management (dismiss on submit)
/// - Consistent styling via AppTextField and AppButton
///
/// Usage:
/// ```dart
/// AuthForm(
///   mode: AuthMode.login,
///   isLoading: isLoading,
///   error: errorMessage,
///   onSubmit: (email, password) async {
///     await authRepository.signInWithEmail(
///       email: email,
///       password: password,
///     );
///   },
/// )
/// ```
class AuthForm extends StatefulWidget {
  /// The mode of the form (login or register)
  final AuthMode mode;

  /// Whether the form is currently submitting (shows loading state)
  final bool isLoading;

  /// Optional error message to display above the form
  final String? error;

  /// Callback invoked when form is submitted with valid credentials
  final Future<void> Function(String email, String password) onSubmit;

  const AuthForm({
    super.key,
    required this.mode,
    required this.onSubmit,
    this.isLoading = false,
    this.error,
  });

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Track whether fields have been touched for validation timing
  bool _emailTouched = false;
  bool _passwordTouched = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Validates and submits the form.
  Future<void> _handleSubmit() async {
    // Mark all fields as touched
    setState(() {
      _emailTouched = true;
      _passwordTouched = true;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    // Call onSubmit callback
    await widget.onSubmit(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = widget.mode == AuthMode.login;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Form-level error display
          if (widget.error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: context.colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.error!,
                      style: TextStyle(
                        color: context.colorScheme.error,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Email field
          AppTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !widget.isLoading,
            prefixIcon: Icons.email_outlined,
            validator: (value) {
              // Only validate if field has been touched
              if (!_emailTouched) return null;
              return Validators.email(value);
            },
            onChanged: (value) {
              // Mark as touched on first change
              if (!_emailTouched) {
                setState(() => _emailTouched = true);
              }
              // Revalidate if already showing error
              if (_emailTouched) {
                _formKey.currentState?.validate();
              }
            },
          ),
          const SizedBox(height: 16),

          // Password field
          AppTextField(
            controller: _passwordController,
            label: 'Password',
            hint: isLogin ? 'Enter your password' : 'Create a password',
            obscureText: true,
            textInputAction: TextInputAction.done,
            enabled: !widget.isLoading,
            prefixIcon: Icons.lock_outlined,
            validator: (value) {
              // Only validate if field has been touched
              if (!_passwordTouched) return null;
              return Validators.password(value);
            },
            onChanged: (value) {
              // Mark as touched on first change
              if (!_passwordTouched) {
                setState(() => _passwordTouched = true);
              }
              // Revalidate if already showing error
              if (_passwordTouched) {
                _formKey.currentState?.validate();
              }
            },
            onSubmitted: (value) {
              // Submit form when user presses "done" on keyboard
              _handleSubmit();
            },
          ),
          const SizedBox(height: 8),

          // Password requirements hint (only in register mode)
          if (!isLogin)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'Password must be at least 8 characters',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Submit button
          AppButton(
            onPressed: widget.isLoading ? null : _handleSubmit,
            isLoading: widget.isLoading,
            label: isLogin ? 'Login' : 'Register',
          ),
        ],
      ),
    );
  }
}
