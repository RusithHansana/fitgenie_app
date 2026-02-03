import 'package:fitgenie_app/core/constants/app_colors.dart';
import 'package:fitgenie_app/core/constants/app_sizes.dart';
import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:fitgenie_app/features/chat/domain/chat_message.dart';
import 'package:flutter/material.dart';

/// Message bubble widget for displaying chat messages.
///
/// This widget displays individual chat messages with appropriate styling
/// based on the message role (user vs assistant vs system). It follows the
/// ChatGPT-style conversation interface pattern as specified in the UX design.
///
/// Features:
/// - Role-based styling (user right-aligned, assistant left-aligned)
/// - Timestamp display with relative formatting
/// - Modification status indicators (checkmark for applied modifications)
/// - Loading state for pending modifications
/// - Responsive width (max 80% of screen width)
/// - Accessible with semantic labels
///
/// Visual Design:
/// - User messages: Right-aligned, primary color background
/// - Assistant messages: Left-aligned, surface color background
/// - System messages: Center-aligned, neutral styling
/// - Timestamps: Subtle, below message content
/// - Success indicators: Checkmark icon for applied modifications
/// - Loading indicators: Spinner for pending modifications
///
/// Usage:
/// ```dart
/// ChatBubble(
///   message: ChatMessage(
///     id: 'msg_123',
///     content: 'Make Tuesday lunch vegetarian',
///     role: MessageRole.user,
///     timestamp: DateTime.now(),
///     isModificationRequest: true,
///     modificationApplied: false,
///   ),
/// )
/// ```
///
/// Architecture Notes:
/// - Follows Material 3 theming via Theme.of(context)
/// - Uses existing AppSizes constants for spacing
/// - Stateless widget for performance
/// - Supports dark mode automatically
class ChatBubble extends StatelessWidget {
  /// The chat message to display.
  final ChatMessage message;

  /// Creates a ChatBubble widget.
  ///
  /// The [message] parameter is required and contains all display data.
  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    // Determine alignment based on role
    final alignment = _getAlignment();

    // Determine colors based on role
    final backgroundColor = _getBackgroundColor(colorScheme);
    final textColor = _getTextColor(colorScheme);

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacingMd,
          vertical: AppSizes.spacingSm,
        ),
        child: Column(
          crossAxisAlignment: message.isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Message bubble
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacingMd,
                vertical: AppSizes.spacingMd,
              ),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: _getBorderRadius(),
                boxShadow: message.isSystem
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message content
                  Text(
                    message.content,
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: textColor,
                      height: 1.4,
                    ),
                  ),

                  // Status indicators (for modification requests)
                  if (message.isModificationRequest) ...[
                    const SizedBox(height: AppSizes.spacingSm),
                    _buildStatusIndicator(context),
                  ],
                ],
              ),
            ),

            // Timestamp
            if (!message.isSystem) ...[
              const SizedBox(height: AppSizes.spacing2xs),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacingSm,
                ),
                child: Text(
                  message.relativeTimestamp,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Gets the alignment based on message role.
  AlignmentGeometry _getAlignment() {
    switch (message.role) {
      case MessageRole.user:
        return Alignment.centerRight;
      case MessageRole.assistant:
        return Alignment.centerLeft;
      case MessageRole.system:
        return Alignment.center;
    }
  }

  /// Gets the background color based on message role.
  Color _getBackgroundColor(ColorScheme colorScheme) {
    switch (message.role) {
      case MessageRole.user:
        return colorScheme.primaryContainer;
      case MessageRole.assistant:
        return colorScheme.surfaceContainer;
      case MessageRole.system:
        return colorScheme.surfaceContainerHigh.withValues(alpha: 0.5);
    }
  }

  /// Gets the text color based on message role.
  Color _getTextColor(ColorScheme colorScheme) {
    switch (message.role) {
      case MessageRole.user:
        return colorScheme.onPrimaryContainer;
      case MessageRole.assistant:
        return colorScheme.onSurface;
      case MessageRole.system:
        return colorScheme.onSurfaceVariant;
    }
  }

  /// Gets the border radius for the bubble.
  BorderRadius _getBorderRadius() {
    switch (message.role) {
      case MessageRole.user:
        // User bubbles: rounded on left, slightly flat on bottom-right
        return const BorderRadius.only(
          topLeft: Radius.circular(AppSizes.radiusMd),
          topRight: Radius.circular(AppSizes.radiusMd),
          bottomLeft: Radius.circular(AppSizes.radiusMd),
          bottomRight: Radius.circular(AppSizes.spacingSm),
        );
      case MessageRole.assistant:
        // Assistant bubbles: rounded on right, slightly flat on bottom-left
        return const BorderRadius.only(
          topLeft: Radius.circular(AppSizes.radiusMd),
          topRight: Radius.circular(AppSizes.radiusMd),
          bottomLeft: Radius.circular(AppSizes.spacingSm),
          bottomRight: Radius.circular(AppSizes.radiusMd),
        );
      case MessageRole.system:
        // System messages: fully rounded
        return BorderRadius.circular(AppSizes.radiusMd);
    }
  }

  /// Builds the status indicator for modification requests.
  Widget _buildStatusIndicator(BuildContext context) {
    final colorScheme = context.colorScheme;

    if (message.isLoading) {
      // Show loading spinner for pending modifications
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                message.isUser
                    ? colorScheme.onPrimaryContainer.withValues(alpha: 0.6)
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.spacingSm),
          Text(
            'Applying changes...',
            style: context.textTheme.bodySmall?.copyWith(
              color: message.isUser
                  ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                  : colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    } else if (message.showSuccessIndicator) {
      // Show checkmark for applied modifications
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 14, color: colorScheme.tertiary),
          const SizedBox(width: AppSizes.spacingSm),
          Text(
            'Changes applied',
            style: context.textTheme.bodySmall?.copyWith(
              color: message.isUser
                  ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                  : colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
