import 'package:fitgenie_app/core/constants/app_sizes.dart';
import 'package:fitgenie_app/core/constants/app_strings.dart';
import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:fitgenie_app/features/auth/domain/user_model.dart';
import 'package:fitgenie_app/features/onboarding/domain/user_profile.dart';
import 'package:flutter/material.dart';

/// Header widget displaying user avatar and basic information.
///
/// This widget shows:
/// - Circular avatar with user's email initial
/// - User email address
/// - "Member since {date}" formatted string
/// - Optional edit button
///
/// The avatar uses the first letter of the user's email address as the
/// initial, displayed in a colored circle. The color is derived from the
/// primary color scheme for consistency with the app theme.
///
/// Layout:
/// ```
/// ┌─────────────────────────────┐
/// │    [Avatar]                 │
/// │   user@email.com            │
/// │   Member since June 2025    │
/// │   [Edit Profile Button]     │
/// └─────────────────────────────┘
/// ```
///
/// Usage:
/// ```dart
/// ProfileHeader(
///   user: currentUser,
///   profile: userProfile,
///   onEditPressed: () {
///     context.push('/profile/edit');
///   },
/// )
/// ```
class ProfileHeader extends StatelessWidget {
  /// The authenticated user model containing email and createdAt.
  final UserModel user;

  /// The user profile containing fitness data.
  ///
  /// Optional - only used if additional profile-specific display is needed.
  final UserProfile? profile;

  /// Callback invoked when the edit button is tapped.
  ///
  /// If null, the edit button will not be displayed.
  final VoidCallback? onEditPressed;

  const ProfileHeader({
    super.key,
    required this.user,
    this.profile,
    this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppSizes.radiusLg),
        ),
      ),
      child: Column(
        children: [
          // Avatar
          _buildAvatar(context),

          const SizedBox(height: AppSizes.spacingMd),

          // Email
          Text(
            user.email,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onPrimaryContainer,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSizes.spacingXs),

          // Member since
          Text(
            _getMemberSinceText(),
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),

          // Edit button (if callback provided)
          if (onEditPressed != null) ...[
            const SizedBox(height: AppSizes.spacingLg),
            FilledButton.icon(
              onPressed: onEditPressed,
              icon: const Icon(Icons.edit_outlined, size: 20),
              label: const Text(AppStrings.buttonEditProfile),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the circular avatar with user initial.
  Widget _buildAvatar(BuildContext context) {
    final colorScheme = context.colorScheme;
    final initial = _getUserInitial();

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primary,
        border: Border.all(
          color: colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: context.textTheme.headlineLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  /// Extracts the first letter of the email as the avatar initial.
  ///
  /// Converts to uppercase for consistent display.
  /// Falls back to 'U' if email is empty or invalid.
  String _getUserInitial() {
    if (user.email.isEmpty) return 'U';
    return user.email[0].toUpperCase();
  }

  /// Formats the member since date as a human-readable string.
  ///
  /// Format: "Member since {Month} {Year}"
  /// Example: "Member since June 2025"
  String _getMemberSinceText() {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final date = user.createdAt;
    final monthName = months[date.month - 1];
    return 'Member since $monthName ${date.year}';
  }
}
