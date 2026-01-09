import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';

/// Social authentication buttons placeholder for future OAuth providers.
///
/// This widget displays Google and Apple sign-in buttons in a disabled state
/// for MVP. The buttons are styled appropriately but do not have functionality
/// in the current version.
///
/// Post-MVP Implementation:
/// - Google Sign-In integration
/// - Apple Sign-In integration (iOS)
/// - Social account linking
///
/// Usage:
/// ```dart
/// SocialButtons(
///   onGoogleSignIn: () async {
///     // Will be implemented post-MVP
///   },
///   onAppleSignIn: () async {
///     // Will be implemented post-MVP
///   },
/// )
/// ```
class SocialButtons extends StatelessWidget {
  /// Optional callback for Google sign-in (not used in MVP)
  final VoidCallback? onGoogleSignIn;

  /// Optional callback for Apple sign-in (not used in MVP)
  final VoidCallback? onAppleSignIn;

  const SocialButtons({super.key, this.onGoogleSignIn, this.onAppleSignIn});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Divider with "OR" text
        Row(
          children: [
            Expanded(child: Divider(color: context.colorScheme.outlineVariant)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(child: Divider(color: context.colorScheme.outlineVariant)),
          ],
        ),
        const SizedBox(height: 24),

        // Social sign-in buttons
        Column(
          children: [
            // Google Sign-In button
            _SocialButton(
              label: 'Continue with Google',
              icon: Icons.g_mobiledata,
              onPressed: null, // Disabled for MVP
              backgroundColor: context.colorScheme.surface,
              textColor: context.colorScheme.onSurface,
              borderColor: context.colorScheme.outline,
            ),
            const SizedBox(height: 12),

            // Apple Sign-In button
            _SocialButton(
              label: 'Continue with Apple',
              icon: Icons.apple,
              onPressed: null, // Disabled for MVP
              backgroundColor: context.colorScheme.inverseSurface,
              textColor: context.colorScheme.onInverseSurface,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // "Coming Soon" indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'Social sign-in coming soon',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Internal widget for rendering individual social sign-in buttons.
class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    const disabledOpacity = 0.5;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor.withValues(
            alpha: isDisabled ? disabledOpacity : 1.0,
          ),
          foregroundColor: textColor.withValues(
            alpha: isDisabled ? disabledOpacity : 1.0,
          ),
          side: BorderSide(
            color: (borderColor ?? backgroundColor).withValues(
              alpha: isDisabled ? 0.3 : 1.0,
            ),
            width: 1,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: textColor.withValues(
                alpha: isDisabled ? disabledOpacity : 1.0,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: textColor.withValues(
                  alpha: isDisabled ? disabledOpacity : 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
