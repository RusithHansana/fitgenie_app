import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fitgenie_app/features/chat/data/chat_repository.dart';
import 'package:fitgenie_app/features/chat/domain/chat_message.dart';
import 'package:fitgenie_app/features/auth/auth_providers.dart';
import 'package:fitgenie_app/features/plan_generation/plan_providers.dart';
import 'package:fitgenie_app/shared/providers/firebase_providers.dart'
    hide currentUserIdProvider;
import 'package:fitgenie_app/shared/providers/logger_provider.dart';

part 'chat_providers.g.dart';

/// Provider for ChatRepository singleton.
///
/// Creates and caches the chat repository for message management and
/// AI-powered plan modifications.
///
/// Dependencies:
/// - [firestoreProvider] - Firestore for message persistence
/// - [geminiServiceProvider] - AI service for modifications
///
/// Usage:
/// ```dart
/// final repository = ref.read(chatRepositoryProvider);
/// await repository.sendMessage(...);
/// ```
@Riverpod(keepAlive: true)
ChatRepository chatRepository(ChatRepositoryRef ref) {
  return ChatRepository(
    firestore: ref.watch(firestoreProvider),
    geminiService: ref.watch(geminiServiceProvider),
    planRepository: ref.watch(planRepositoryProvider),
    logger: ref.watch(loggerProvider),
  );
}

/// Provider for chat messages stream.
///
/// Returns a real-time stream of chat messages for the current user,
/// ordered chronologically (oldest first).
///
/// Auto-updates when:
/// - New messages are sent
/// - Messages are modified (e.g., modificationApplied flag)
/// - User ID changes (login/logout)
///
/// Returns empty list if user is not authenticated.
///
/// Usage:
/// ```dart
/// final messagesAsync = ref.watch(chatMessagesProvider);
/// messagesAsync.when(
///   data: (messages) => ChatList(messages: messages),
///   loading: () => LoadingIndicator(),
///   error: (e, st) => ErrorDisplay(error: e),
/// );
/// ```
@riverpod
Stream<List<ChatMessage>> chatMessages(ChatMessagesRef ref) {
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    // Not authenticated - return empty stream
    return Stream.value([]);
  }

  final repository = ref.watch(chatRepositoryProvider);
  return repository.getMessages(userId);
}

/// Provider for sending a message action.
///
/// This is an action provider that sends a user message and gets an AI response.
/// The message is automatically persisted to Firestore and the chat stream updates.
///
/// Parameters:
/// - [content]: The message content to send
///
/// Returns: The assistant's response message
///
/// Throws:
/// - [ArgumentError] if content is empty or too long
/// - [AiException] if AI processing fails
/// - [StateError] if user not authenticated
///
/// Usage:
/// ```dart
/// // Send message
/// try {
///   final response = await ref.read(
///     sendChatMessageProvider(content: 'Make Tuesday easier').future,
///   );
///   print(response.content);
/// } on AiException catch (e) {
///   showError(e.userFriendlyMessage);
/// }
/// ```
@riverpod
Future<ChatMessage> sendChatMessage(
  SendChatMessageRef ref, {
  required String content,
}) async {
  // Get current user ID
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    throw StateError('User must be authenticated to send messages');
  }

  // Get current plan for context
  final currentPlan = await ref.read(currentPlanProvider.future);

  // Send message via repository
  final repository = ref.watch(chatRepositoryProvider);
  final response = await repository.sendMessage(
    userId: userId,
    content: content,
    currentPlan: currentPlan,
  );

  // If modification was applied, invalidate current plan to refresh UI
  if (response.modificationApplied) {
    ref.invalidate(currentPlanProvider);
  }

  return response;
}

/// Provider for typing indicator state.
///
/// Indicates whether the AI is currently generating a response.
/// Used to show typing indicator animation in the chat UI.
///
/// Usage:
/// ```dart
/// final isTyping = ref.watch(isTypingProvider);
/// if (isTyping) {
///   return TypingIndicator();
/// }
/// ```
@riverpod
class IsTyping extends _$IsTyping {
  @override
  bool build() => false;

  /// Sets the typing state.
  void setTyping(bool value) {
    state = value;
  }
}

/// Provider for modification in progress state.
///
/// Indicates whether a plan modification is currently being processed.
/// Used to show loading states and disable input during modification.
///
/// Usage:
/// ```dart
/// final isModifying = ref.watch(modificationInProgressProvider);
/// ChatInput(
///   enabled: !isModifying,
/// )
/// ```
@riverpod
class ModificationInProgress extends _$ModificationInProgress {
  @override
  bool build() => false;

  /// Sets the modification in progress state.
  void setInProgress(bool value) {
    state = value;
  }
}

/// Provider for checking if chat has any messages.
///
/// Returns true if the user has at least one message in their chat history.
/// Useful for showing empty states.
///
/// Usage:
/// ```dart
/// final hasMessages = ref.watch(hasChatMessagesProvider);
/// hasMessages.when(
///   data: (hasMsg) => hasMsg ? ChatList() : EmptyState(),
///   loading: () => LoadingIndicator(),
///   error: (e, st) => ErrorDisplay(error: e),
/// );
/// ```
@riverpod
Future<bool> hasChatMessages(HasChatMessagesRef ref) async {
  final messagesAsync = ref.watch(chatMessagesProvider);
  return messagesAsync.when(
    data: (messages) => messages.isNotEmpty,
    loading: () => false,
    error: (_, __) => false,
  );
}

/// Provider for the last chat message.
///
/// Returns the most recent message in the chat, or null if no messages exist.
/// Useful for showing a preview of the last interaction.
///
/// Usage:
/// ```dart
/// final lastMessageAsync = ref.watch(lastChatMessageProvider);
/// lastMessageAsync.when(
///   data: (message) => message != null
///       ? Text(message.content)
///       : Text('No messages yet'),
///   loading: () => CircularProgressIndicator(),
///   error: (e, st) => Text('Error'),
/// );
/// ```
@riverpod
Future<ChatMessage?> lastChatMessage(LastChatMessageRef ref) async {
  final messagesAsync = ref.watch(chatMessagesProvider);
  return messagesAsync.when(
    data: (messages) => messages.isNotEmpty ? messages.last : null,
    loading: () => null,
    error: (_, __) => null,
  );
}

/// Provider for clearing chat history action.
///
/// Deletes all chat messages for the current user.
/// Returns the number of messages deleted.
///
/// Usage:
/// ```dart
/// // Clear chat history
/// final deleted = await ref.read(clearChatHistoryProvider.future);
/// showMessage('Deleted $deleted messages');
/// ```
@riverpod
Future<int> clearChatHistory(ClearChatHistoryRef ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return 0;
  }

  final repository = ref.watch(chatRepositoryProvider);
  return await repository.clearHistory(userId);
}

/// Provider for counting total messages.
///
/// Returns the total number of messages in the chat history.
/// Useful for displaying message count in UI.
///
/// Usage:
/// ```dart
/// final countAsync = ref.watch(chatMessageCountProvider);
/// countAsync.when(
///   data: (count) => Text('$count messages'),
///   loading: () => Text('...'),
///   error: (e, st) => Text('Error'),
/// );
/// ```
@riverpod
Future<int> chatMessageCount(ChatMessageCountRef ref) async {
  final messagesAsync = ref.watch(chatMessagesProvider);
  return messagesAsync.when(
    data: (messages) => messages.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
}

/// Provider for getting messages by role.
///
/// Filters messages to only those from a specific role.
/// Useful for analytics or displaying only user/assistant messages.
///
/// Parameters:
/// - [role]: The message role to filter by
///
/// Usage:
/// ```dart
/// final userMessagesAsync = ref.watch(
///   messagesByRoleProvider(MessageRole.user),
/// );
/// ```
@riverpod
Future<List<ChatMessage>> messagesByRole(
  MessagesByRoleRef ref,
  MessageRole role,
) async {
  final messagesAsync = ref.watch(chatMessagesProvider);
  return messagesAsync.when(
    data: (messages) => messages.where((msg) => msg.role == role).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
}

/// Provider for pending modifications count.
///
/// Returns the number of modification requests that haven't been applied yet.
/// Useful for showing pending modifications indicator.
///
/// Usage:
/// ```dart
/// final pendingAsync = ref.watch(pendingModificationsCountProvider);
/// pendingAsync.when(
///   data: (count) => count > 0 ? Badge(count: count) : SizedBox(),
///   loading: () => SizedBox(),
///   error: (e, st) => SizedBox(),
/// );
/// ```
@riverpod
Future<int> pendingModificationsCount(PendingModificationsCountRef ref) async {
  final messagesAsync = ref.watch(chatMessagesProvider);
  return messagesAsync.when(
    data: (messages) => messages.where((msg) => msg.isLoading).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
}
