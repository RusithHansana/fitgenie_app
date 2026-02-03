import 'package:fitgenie_app/core/constants/app_sizes.dart';
import 'package:fitgenie_app/core/constants/app_strings.dart';
import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:fitgenie_app/features/chat/chat_providers.dart';
import 'package:fitgenie_app/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:fitgenie_app/features/chat/presentation/widgets/chat_input.dart';
import 'package:fitgenie_app/features/chat/presentation/widgets/modification_chips.dart';
import 'package:fitgenie_app/features/chat/presentation/widgets/typing_indicator.dart';
import 'package:fitgenie_app/routing/app_router.dart';
import 'package:fitgenie_app/shared/widgets/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Chat interface screen for plan modifications and assistance.
///
/// This is the primary AI interaction screen where users can have natural
/// language conversations with FitGenie to modify their fitness plans.
/// It provides a ChatGPT-style interface with message history, typing
/// indicators, and quick-action chips.
///
/// Features:
/// - Real-time message stream from Firestore
/// - Auto-scroll to bottom on new messages
/// - Typing indicator during AI response
/// - Quick modification chips for common actions
/// - Empty state for new conversations
/// - Error handling with retry
/// - Keyboard-aware layout
/// - Pull-to-refresh for manual sync
///
/// Layout Structure:
/// ```
/// ┌─────────────────────────────┐
/// │ AppBar: "Chat"              │
/// ├─────────────────────────────┤
/// │                             │
/// │ Message List (scrollable)   │
/// │ • ChatBubble (user)         │
/// │ • ChatBubble (assistant)    │
/// │ • TypingIndicator (if AI)   │
/// │                             │
/// ├─────────────────────────────┤
/// │ ModificationChips (scroll)  │
/// ├─────────────────────────────┤
/// │ ChatInput (with send)       │
/// └─────────────────────────────┘
/// ```
///
/// User Flow:
/// 1. User opens chat from dashboard FAB or bottom nav
/// 2. Sees message history or empty state
/// 3. Types message or taps suggestion chip
/// 4. Typing indicator appears
/// 5. AI response arrives and displays
/// 6. If modification: plan updates automatically
/// 7. User can continue conversation
///
/// Usage:
/// ```dart
/// // Navigate to chat screen
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (_) => ChatScreen()),
/// );
///
/// // Or via router
/// context.go('/chat');
/// ```
///
/// Architecture Notes:
/// - ConsumerStatefulWidget for scroll controller management
/// - Uses Riverpod for all state management
/// - Integrates with plan_generation feature for modifications
/// - Messages persist across sessions via Firestore
/// - Follows Material 3 design patterns
class ChatScreen extends ConsumerStatefulWidget {
  /// Creates a ChatScreen.
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  /// Scroll controller for message list.
  late final ScrollController _scrollController;

  /// Whether the user has manually scrolled away from bottom.
  bool _userScrolledAway = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Listen to scroll position to detect manual scrolling
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Handles scroll position changes.
  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    // Check if user is at bottom
    final isAtBottom =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50;

    if (_userScrolledAway && isAtBottom) {
      setState(() {
        _userScrolledAway = false;
      });
    } else if (!_userScrolledAway && !isAtBottom) {
      setState(() {
        _userScrolledAway = true;
      });
    }
  }

  /// Scrolls to the bottom of the message list.
  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;

    if (animate) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  /// Handles sending a message.
  Future<void> _handleSendMessage(String content) async {
    // Set typing state
    ref.read(isTypingProvider.notifier).setTyping(true);

    try {
      // Send message via provider
      await ref.read(sendChatMessageProvider(content: content).future);

      // Scroll to bottom to show new messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      // Error handling is done by the provider
      // UI will show error via ErrorDisplay
    } finally {
      // Clear typing state
      ref.read(isTypingProvider.notifier).setTyping(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    // Watch messages stream
    final messagesAsync = ref.watch(chatMessagesProvider);
    final isTyping = ref.watch(isTypingProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goToDashboard(),
          tooltip: 'Back to Dashboard',
        ),
        title: const Text(AppStrings.chatScreenTitle),
        actions: [
          // Clear chat history button
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: AppStrings.chatClearHistoryTooltip,
            onPressed: () => _showClearHistoryDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                // Show empty state if no messages
                if (messages.isEmpty && !isTyping) {
                  return _buildEmptyState(context);
                }

                // Auto-scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!_userScrolledAway) {
                    _scrollToBottom(animate: true);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSizes.spacingMd,
                  ),
                  itemCount: messages.length + (isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show typing indicator at the end
                    if (index == messages.length) {
                      return const TypingIndicator(showLabel: true);
                    }

                    final message = messages[index];
                    return ChatBubble(message: message);
                  },
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              ),
              error: (error, stack) => ErrorDisplay(
                error: error,
                onRetry: () {
                  ref.invalidate(chatMessagesProvider);
                },
              ),
            ),
          ),

          // Modification chips (quick actions)
          ModificationChips(
            onChipTap: _handleSendMessage,
            isEnabled: !isTyping,
          ),

          // Chat input
          ChatInput(onSend: _handleSendMessage, isEnabled: !isTyping),
        ],
      ),
    );
  }

  /// Builds the empty state when no messages exist.
  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),

            const SizedBox(height: AppSizes.spacingLg),

            // Title
            Text(
              AppStrings.chatScreenTitle,
              style: context.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSizes.spacingSm),

            // Description
            Text(
              AppStrings.chatEmptyStateDescription,
              style: context.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSizes.spacingXl),

            // Example suggestions
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSizes.spacingSm,
              runSpacing: AppSizes.spacingSm,
              children: [
                _buildExampleChip(
                  context,
                  AppStrings.chatExampleEasier,
                  Icons.trending_down,
                ),
                _buildExampleChip(
                  context,
                  AppStrings.chatExampleSwapMeal,
                  Icons.swap_horiz,
                ),
                _buildExampleChip(
                  context,
                  AppStrings.chatExampleSkipWorkout,
                  Icons.event_busy,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds an example suggestion chip for the empty state.
  Widget _buildExampleChip(BuildContext context, String label, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ActionChip(
      label: Text(label),
      avatar: Icon(icon, size: 18),
      onPressed: () => _handleSendMessage(label),
      backgroundColor: colorScheme.surfaceContainerHighest,
      side: BorderSide(color: colorScheme.outlineVariant, width: 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      labelStyle: context.textTheme.labelMedium,
    );
  }

  /// Shows dialog to confirm clearing chat history.
  Future<void> _showClearHistoryDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.chatClearHistoryTitle),
        content: const Text(
          'This will delete all your messages. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.buttonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: context.colorScheme.error,
            ),
            child: const Text(AppStrings.buttonClear),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final deleted = await ref.read(clearChatHistoryProvider.future);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.chatHistoryClearedMessage.replaceAll(
                  '{count}',
                  '$deleted',
                ),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.errorClearHistoryFailed),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }
}
