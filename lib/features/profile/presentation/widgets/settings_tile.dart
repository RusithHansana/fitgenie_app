import 'package:fitgenie_app/core/constants/app_sizes.dart';
import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';

/// Reusable list tile component for settings options.
///
/// This widget provides a consistent design for settings list items with:
/// - Optional leading icon
/// - Title text (required)
/// - Optional subtitle text
/// - Optional trailing widget (chevron, toggle, or custom)
/// - Tap handling
/// - Consistent styling across the app
///
/// The tile follows Material Design patterns with proper touch targets,
/// spacing, and visual feedback on interaction.
///
/// Layout:
/// ```
/// ┌────────────────────────────────────┐
/// │ [Icon]  Title              [Trail] │
/// │         Subtitle                   │
/// └────────────────────────────────────┘
/// ```
///
/// Usage:
/// ```dart
/// // Simple tile with navigation
/// SettingsTile(
///   title: 'Edit Profile',
///   leading: Icon(Icons.edit),
///   onTap: () => context.push('/profile/edit'),
/// )
///
/// // Tile with subtitle and chevron
/// SettingsTile(
///   title: 'Regenerate Plan',
///   subtitle: 'Create a new 7-day plan',
///   leading: Icon(Icons.refresh),
///   showChevron: true,
///   onTap: () => showRegenerateDialog(),
/// )
///
/// // Tile with custom trailing widget
/// SettingsTile(
///   title: 'Notifications',
///   leading: Icon(Icons.notifications),
///   trailing: Switch(value: true, onChanged: (val) {}),
/// )
/// ```
class SettingsTile extends StatelessWidget {
  /// The main title text displayed in the tile.
  final String title;

  /// Optional subtitle text displayed below the title.
  ///
  /// Typically used for additional context or description.
  final String? subtitle;

  /// Optional leading icon displayed before the title.
  final Widget? leading;

  /// Optional trailing widget displayed at the end of the tile.
  ///
  /// Can be any widget (chevron, toggle, badge, etc.).
  /// If null and [showChevron] is true, a chevron icon will be shown.
  final Widget? trailing;

  /// Whether to show a chevron icon at the end.
  ///
  /// Only applies if [trailing] is null. Defaults to false.
  final bool showChevron;

  /// Callback invoked when the tile is tapped.
  ///
  /// If null, the tile will not be interactive (no ripple effect).
  final VoidCallback? onTap;

  /// Whether the tile is enabled.
  ///
  /// Disabled tiles have reduced opacity and cannot be tapped.
  final bool enabled;

  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.showChevron = false,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacingMd,
              vertical: AppSizes.spacingMd,
            ),
            child: Row(
              children: [
                // Leading icon
                if (leading != null) ...[
                  IconTheme(
                    data: IconThemeData(color: colorScheme.onSurface, size: 24),
                    child: leading!,
                  ),
                  const SizedBox(width: AppSizes.spacingMd),
                ],

                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSizes.spacing2xs),
                        Text(
                          subtitle!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Trailing widget or chevron
                if (trailing != null)
                  trailing!
                else if (showChevron)
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A divider variant for settings sections.
///
/// Provides visual separation between groups of settings tiles.
///
/// Usage:
/// ```dart
/// Column(
///   children: [
///     SettingsTile(title: 'Setting 1'),
///     SettingsTile(title: 'Setting 2'),
///     SettingsDivider(),
///     SettingsTile(title: 'Setting 3'),
///   ],
/// )
/// ```
class SettingsDivider extends StatelessWidget {
  /// Optional left margin for the divider.
  ///
  /// Use this to align with the title text when leading icons are present.
  final double indent;

  const SettingsDivider({super.key, this.indent = 0});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: indent,
      color: context.colorScheme.outlineVariant,
    );
  }
}

/// A header widget for settings sections.
///
/// Provides a labeled section header with optional padding.
///
/// Usage:
/// ```dart
/// Column(
///   children: [
///     SettingsSectionHeader(title: 'Account'),
///     SettingsTile(title: 'Delete Account'),
///     SettingsTile(title: 'Sign Out'),
///   ],
/// )
/// ```
class SettingsSectionHeader extends StatelessWidget {
  /// The section title text.
  final String title;

  /// Optional padding above the header.
  final double topPadding;

  /// Optional padding below the header.
  final double bottomPadding;

  const SettingsSectionHeader({
    super.key,
    required this.title,
    this.topPadding = AppSizes.spacingLg,
    this.bottomPadding = AppSizes.spacingSm,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Padding(
      padding: EdgeInsets.only(
        top: topPadding,
        bottom: bottomPadding,
        left: AppSizes.spacingMd,
        right: AppSizes.spacingMd,
      ),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
