import 'package:fitgenie_app/core/constants/app_sizes.dart';
import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';

/// Text input widget for composing chat messages.
///
/// This widget provides a text field for users to compose messages with a
/// send button. It handles keyboard management, multi-line input, and
/// disabled states during message sending.
///
/// Features:
/// - Multi-line text input (max 4 lines with auto-expansion)
/// - Send button with icon
/// - Disabled state when sending or offline
/// - Clear text on successful send
/// - Hint text for guidance
/// - Keyboard submit handling (Enter to send on desktop)
/// - Minimum height enforcement for comfortable input
///
/// Visual Design:
/// - Filled TextField with rounded corners
/// - Send button integrated on the right side
/// - Primary color for enabled send button
/// - Disabled styling when not ready to send
/// - Keyboard-aware layout (doesn't get hidden by keyboard)
///
/// Usage:
/// ```dart
/// ChatInput(
///   onSend: (text) async {
///     await sendMessage(text);
///   },
///   isEnabled: !isSending,
/// )
/// ```
///
/// Architecture Notes:
/// - StatefulWidget to manage TextEditingController
/// - Follows Material 3 theming
/// - Integrates with bottom navigation layout
/// - Supports accessibility features
class ChatInput extends StatefulWidget {
  /// Callback invoked when the user sends a message.
  ///
  /// The callback receives the trimmed message content.
  /// If the callback is async, consider showing loading state.
  final ValueChanged<String> onSend;

  /// Whether the input is enabled.
  ///
  /// When false, the text field and send button are disabled.
  /// Use this to prevent input during message sending or offline state.
  final bool isEnabled;

  /// Optional hint text to display in the text field.
  ///
  /// Defaults to "Ask me to modify your plan..."
  final String? hintText;

  /// Creates a ChatInput widget.
  ///
  /// The [onSend] callback is required. Set [isEnabled] to false
  /// to disable input during processing.
  const ChatInput({
    super.key,
    required this.onSend,
    this.isEnabled = true,
    this.hintText,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  /// Text editing controller for the input field.
  late final TextEditingController _controller;

  /// Focus node for the input field.
  late final FocusNode _focusNode;

  /// Whether the send button should be enabled.
  ///
  /// True when text is not empty and input is enabled.
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    // Listen to text changes to update send button state
    _controller.addListener(_updateSendButtonState);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateSendButtonState);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Updates the send button enabled state based on text content.
  void _updateSendButtonState() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (_canSend != hasText) {
      setState(() {
        _canSend = hasText;
      });
    }
  }

  /// Handles sending the message.
  void _handleSend() {
    if (!_canSend || !widget.isEnabled) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Call the onSend callback
    widget.onSend(text);

    // Clear the input field
    _controller.clear();

    // Keep focus on the input field for continued conversation
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.only(
        left: AppSizes.spacingMd,
        right: AppSizes.spacingMd,
        top: AppSizes.spacingSm,
        bottom: AppSizes.spacingSm + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Text input field
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.isEnabled,
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: widget.isEnabled ? (_) => _handleSend() : null,
              decoration: InputDecoration(
                hintText: widget.hintText ?? 'Ask me to modify your plan...',
                hintStyle: context.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacingMd,
                  vertical: AppSizes.spacingMd,
                ),
                isDense: true,
              ),
              style: context.textTheme.bodyLarge,
            ),
          ),

          const SizedBox(width: AppSizes.spacingSm),

          // Send button
          _buildSendButton(context),
        ],
      ),
    );
  }

  /// Builds the send button with appropriate state styling.
  Widget _buildSendButton(BuildContext context) {
    final colorScheme = context.colorScheme;

    final isButtonEnabled = _canSend && widget.isEnabled;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isButtonEnabled
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: isButtonEnabled ? _handleSend : null,
        icon: Icon(
          Icons.send_rounded,
          color: isButtonEnabled
              ? colorScheme.onPrimary
              : colorScheme.onSurfaceVariant,
        ),
        tooltip: isButtonEnabled ? 'Send message' : 'Type a message to send',
        splashRadius: 24,
      ),
    );
  }
}
