import 'package:fitgenie_app/core/constants/app_sizes.dart';
import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:fitgenie_app/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';

/// Placeholder widget for empty content states with optional action.
///
/// This widget provides a consistent, friendly interface for displaying empty
/// states throughout the app. It follows UX best practices by maintaining a
/// positive, encouraging tone and offering clear actions when appropriate.
///
/// Features:
/// - Large icon for visual hierarchy
/// - Title and description text
/// - Optional action button (e.g., "Generate Plan", "Add Item")
/// - Centered, responsive layout
/// - Consistent spacing and styling
/// - Encouraging, positive messaging
///
/// Usage:
/// ```dart
/// if (plans.isEmpty) {
///   return EmptyState(
///     icon: Icons.fitness_center,
///     title: 'No Plan Yet',
///     description: 'Generate your first personalized fitness plan to get started.',
///     actionLabel: 'Generate Plan',
///     onAction: _navigateToGeneration,
///   );
/// }
/// ```
///
/// Without action button:
/// ```dart
/// EmptyState(
///   icon: Icons.history,
///   title: 'No History',
///   description: 'Complete your first workout to see your progress here.',
/// )
/// ```
///
/// Design Philosophy:
/// Empty states should feel like opportunities, not dead ends. The tone is
/// encouraging ("Let's get started!") rather than negative ("Nothing here").
/// Always provide context about what will appear here once populated.
class EmptyState extends StatelessWidget {
  /// Icon displayed at the top of the empty state.
  ///
  /// Choose an icon that represents the missing content type.
  /// Examples: Icons.fitness_center (workouts), Icons.restaurant (meals),
  /// Icons.chat (messages), Icons.history (activity).
  final IconData icon;

  /// Title text describing the empty state.
  ///
  /// Should be concise and clear. Examples: "No Plans Yet", "No Messages",
  /// "Nothing Scheduled Today".
  final String title;

  /// Description text providing context and guidance.
  ///
  /// Explain what will appear here and optionally guide the user toward
  /// the action they should take. Keep it encouraging and actionable.
  final String description;

  /// Optional label for the action button.
  ///
  /// If null, no action button is displayed. Examples: "Generate Plan",
  /// "Add Workout", "Get Started", "Learn More".
  final String? actionLabel;

  /// Optional callback invoked when action button is tapped.
  ///
  /// Required if [actionLabel] is provided.
  final VoidCallback? onAction;

  /// Icon size in logical pixels.
  ///
  /// Defaults to 64dp for good visual hierarchy.
  final double iconSize;

  /// Icon color.
  ///
  /// If null, uses theme's onSurfaceVariant color for subtle appearance.
  final Color? iconColor;

  /// Creates an [EmptyState] widget.
  ///
  /// The [icon], [title], and [description] parameters are required.
  /// Provide both [actionLabel] and [onAction] to show an action button.
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.iconSize = 64,
    this.iconColor,
  }) : assert(
         actionLabel == null || onAction != null,
         'onAction must be provided when actionLabel is specified',
       );

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor =
        iconColor ?? context.colorScheme.onSurfaceVariant;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Icon(icon, size: iconSize, color: effectiveIconColor),
            const SizedBox(height: AppSizes.spacingLg),

            // Title
            Text(
              title,
              style: context.textTheme.headlineSmall?.copyWith(
                color: context.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spacingSm),

            // Description
            Text(
              description,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),

            // Action button (if provided)
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSizes.spacingXl),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: ButtonVariant.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact empty state for inline display within lists or sections.
///
/// A lighter-weight alternative to [EmptyState] suitable for displaying
/// within constrained spaces like list sections or card containers.
///
/// Usage:
/// ```dart
/// ListView(
///   children: [
///     SectionHeader('Recent Activity'),
///     if (activities.isEmpty)
///       CompactEmptyState(
///         message: 'No recent activity',
///         icon: Icons.history,
///       )
///     else
///       ...activities.map((a) => ActivityTile(a)),
///   ],
/// )
/// ```
class CompactEmptyState extends StatelessWidget {
  /// Message to display.
  final String message;

  /// Optional icon to display before the message.
  final IconData? icon;

  /// Optional action button label.
  final String? actionLabel;

  /// Optional action callback.
  final VoidCallback? onAction;

  /// Creates a [CompactEmptyState] for inline display.
  const CompactEmptyState({
    super.key,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacingMd,
        vertical: AppSizes.spacingXl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 20,
                  color: context.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSizes.spacingSm),
              ],
              Flexible(
                child: Text(
                  message,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSizes.spacingMd),
            AppButton(
              label: actionLabel!,
              onPressed: onAction,
              variant: ButtonVariant.text,
            ),
          ],
        ],
      ),
    );
  }
}
