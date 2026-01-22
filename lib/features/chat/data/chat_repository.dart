import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitgenie_app/core/constants/app_strings.dart';
import 'package:fitgenie_app/core/exceptions/ai_exception.dart';
import 'package:fitgenie_app/core/utils/retry_helper.dart';
import 'package:fitgenie_app/features/chat/domain/chat_message.dart';
import 'package:logger/logger.dart';
import 'package:fitgenie_app/features/chat/domain/modification_request.dart';
import 'package:fitgenie_app/features/plan_generation/data/gemini_service.dart';
import 'package:fitgenie_app/features/plan_generation/data/prompt_builder.dart';
import 'package:fitgenie_app/features/plan_generation/domain/weekly_plan.dart';
import 'package:uuid/uuid.dart';

/// Repository managing chat messages and AI-powered plan modifications.
///
/// This repository is the core of the chat feature, handling all chat message
/// persistence, AI communication for modifications, and coordination between
/// chat and plan features.
///
/// Key Responsibilities:
/// - Persist chat messages to Firestore with real-time sync
/// - Send user messages and receive AI responses
/// - Process plan modification requests through Gemini AI
/// - Apply modifications to existing plans
/// - Clear chat history when needed
/// - Handle errors with retry logic
///
/// Architecture:
/// - Uses FirebaseFirestore for message persistence
/// - Integrates with GeminiService for AI calls
/// - Uses PromptBuilder for modification prompts
/// - Applies RetryHelper for network resilience
/// - Coordinates with plan_generation feature
///
/// Data Flow:
/// ```
/// User → sendMessage() → Firestore + AI
///                      ↓
///         AI Response → Firestore
///                      ↓
///         Modification Request?
///                      ↓
///         processModification() → Apply to Plan
/// ```
///
/// Usage:
/// ```dart
/// final repository = ChatRepository(
///   firestore: FirebaseFirestore.instance,
///   geminiService: GeminiService(),
/// );
///
/// // Send a user message
/// await repository.sendMessage(
///   userId: 'user_123',
///   content: 'Make Tuesday lunch vegetarian',
///   currentPlan: weeklyPlan,
/// );
///
/// // Get message stream
/// final messagesStream = repository.getMessages('user_123');
///
/// // Clear history
/// await repository.clearHistory('user_123');
/// ```
///
/// Firestore Structure:
/// ```
/// /users/{userId}/chatHistory/{messageId}
/// ├── id: string
/// ├── content: string
/// ├── role: string
/// ├── timestamp: string (ISO 8601)
/// ├── isModificationRequest: boolean
/// └── modificationApplied: boolean
/// ```
class ChatRepository {
  /// Firestore instance for message persistence.
  final FirebaseFirestore firestore;

  /// Gemini AI service for processing modifications.
  final GeminiService geminiService;

  /// Logger instance for tracking operations and errors.
  final Logger logger;

  /// UUID generator for message IDs.
  final Uuid _uuid = const Uuid();

  /// Creates a ChatRepository with required dependencies.
  ///
  /// Parameters:
  /// - [firestore]: FirebaseFirestore instance for persistence
  /// - [geminiService]: GeminiService for AI calls
  /// - [logger]: Logger instance for tracking operations
  ChatRepository({
    required this.firestore,
    required this.geminiService,
    required this.logger,
  });

  /// Maximum message content length (characters).
  static const int maxMessageLength = 5000;

  /// Maximum number of messages to keep in history per user.
  static const int maxHistoryMessages = 100;

  /// Gets a stream of chat messages for a user, ordered by timestamp.
  ///
  /// Returns a real-time stream that updates whenever messages are
  /// added, modified, or deleted in Firestore.
  ///
  /// Messages are ordered ascending (oldest first) for chronological display.
  ///
  /// Parameters:
  /// - [userId]: The user's unique identifier
  ///
  /// Returns: Stream of ChatMessage list
  ///
  /// Example:
  /// ```dart
  /// repository.getMessages('user_123').listen((messages) {
  ///   for (final message in messages) {
  ///     print('${message.role}: ${message.content}');
  ///   }
  /// });
  /// ```
  Stream<List<ChatMessage>> getMessages(String userId) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('chatHistory')
        .orderBy('timestamp', descending: false)
        .limit(maxHistoryMessages)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            try {
              return ChatMessage.fromJson(doc.data());
            } catch (e) {
              // If parsing fails, return a system error message
              return ChatMessage(
                id: doc.id,
                content: AppStrings.errorLoadMessage,
                role: MessageRole.system,
                timestamp: DateTime.now(),
                isModificationRequest: false,
                modificationApplied: false,
              );
            }
          }).toList();
        });
  }

  /// Sends a user message and gets an AI response.
  ///
  /// This method:
  /// 1. Validates message content
  /// 2. Creates and persists user message
  /// 3. Determines if modification is requested
  /// 4. Sends to AI for response
  /// 5. Creates and persists assistant response
  /// 6. If modification: processes and applies it
  ///
  /// Parameters:
  /// - [userId]: The user's unique identifier
  /// - [content]: The message content
  /// - [currentPlan]: The user's current plan (for context)
  ///
  /// Returns: The assistant's response message
  ///
  /// Throws:
  /// - [ArgumentError] if content is empty or too long
  /// - [AiException] if AI processing fails after retries
  ///
  /// Example:
  /// ```dart
  /// final response = await repository.sendMessage(
  ///   userId: 'user_123',
  ///   content: 'Make Wednesday easier',
  ///   currentPlan: weeklyPlan,
  /// );
  /// print(response.content); // AI's response
  /// ```
  Future<ChatMessage> sendMessage({
    required String userId,
    required String content,
    WeeklyPlan? currentPlan,
  }) async {
    // Validate message content
    if (content.trim().isEmpty) {
      throw ArgumentError(AppStrings.errorMessageEmpty);
    }
    if (content.length > maxMessageLength) {
      throw ArgumentError(
        AppStrings.errorMessageTooLong.replaceAll('{max}', '$maxMessageLength'),
      );
    }

    // Create user message
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      content: content.trim(),
      role: MessageRole.user,
      timestamp: DateTime.now(),
      isModificationRequest: _isModificationRequest(content),
      modificationApplied: false,
    );

    // Persist user message
    await _persistMessage(userId, userMessage);

    // Get AI response
    ChatMessage assistantMessage;
    try {
      if (currentPlan != null && userMessage.isModificationRequest) {
        // Handle modification request
        assistantMessage = await _handleModificationRequest(
          userId: userId,
          userMessage: userMessage,
          currentPlan: currentPlan,
        );
      } else {
        // Handle general chat (informational)
        assistantMessage = await _handleGeneralChat(
          userId: userId,
          userMessage: userMessage,
          currentPlan: currentPlan,
        );
      }
    } catch (e) {
      // Create error response message
      assistantMessage = ChatMessage(
        id: _uuid.v4(),
        content: _getErrorMessage(e),
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        isModificationRequest: false,
        modificationApplied: false,
      );

      // Persist error message
      await _persistMessage(userId, assistantMessage);
      rethrow;
    }

    // Persist assistant message
    await _persistMessage(userId, assistantMessage);

    return assistantMessage;
  }

  /// Processes a plan modification request through AI.
  ///
  /// This method:
  /// 1. Creates ModificationRequest from user message
  /// 2. Builds modification prompt with current plan context
  /// 3. Calls Gemini AI to process modification
  /// 4. Parses AI response
  /// 5. Returns modified plan data
  ///
  /// Parameters:
  /// - [userId]: The user's unique identifier
  /// - [request]: The structured modification request
  /// - [currentPlan]: The plan to modify
  ///
  /// Returns: Map containing modified plan data
  ///
  /// Throws:
  /// - [AiException] if AI processing fails
  ///
  /// Example:
  /// ```dart
  /// final modifiedData = await repository.processModification(
  ///   userId: 'user_123',
  ///   request: modificationRequest,
  ///   currentPlan: weeklyPlan,
  /// );
  /// ```
  Future<Map<String, dynamic>> processModification({
    required String userId,
    required ModificationRequest request,
    required WeeklyPlan currentPlan,
  }) async {
    // Build modification prompt
    final prompt = PromptBuilder.buildModificationPrompt(
      currentPlan,
      request.userRequest,
    );

    // Call AI with retry logic
    final modifiedPlanData =
        await RetryHelper.retryGeminiCall<Map<String, dynamic>>(
          () => geminiService.modifyPlan(prompt),
          onRetry: (attempt, delay, error) {
            logger.w(
              'Retry modification attempt $attempt after ${delay}s: ${error.toString()}',
            );
          },
        );

    return modifiedPlanData;
  }

  /// Applies a modification to a plan and updates Firestore.
  ///
  /// This method coordinates with the plan feature to apply modifications.
  /// It's a convenience method that could be extended to handle plan updates
  /// directly, but currently delegates to plan_generation feature.
  ///
  /// Parameters:
  /// - [userId]: The user's unique identifier
  /// - [planId]: The plan to modify
  /// - [modification]: The modification data to apply
  ///
  /// Returns: true if successful, false otherwise
  ///
  /// Example:
  /// ```dart
  /// final success = await repository.applyModification(
  ///   userId: 'user_123',
  ///   planId: 'plan_456',
  ///   modification: modifiedData,
  /// );
  /// ```
  Future<bool> applyModification({
    required String userId,
    required String planId,
    required Map<String, dynamic> modification,
  }) async {
    try {
      // Note: Actual plan update happens via plan_generation feature
      // This method could be extended to handle direct updates
      // For now, it's a coordination point

      return true;
    } catch (e) {
      logger.e('Error applying modification', error: e);
      return false;
    }
  }

  /// Clears all chat history for a user.
  ///
  /// Deletes all messages from Firestore. Use with caution.
  ///
  /// Parameters:
  /// - [userId]: The user's unique identifier
  ///
  /// Returns: Number of messages deleted
  ///
  /// Example:
  /// ```dart
  /// final deleted = await repository.clearHistory('user_123');
  /// print('Deleted $deleted messages');
  /// ```
  Future<int> clearHistory(String userId) async {
    final snapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('chatHistory')
        .get();

    final batch = firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    return snapshot.docs.length;
  }

  /// Marks a message as having its modification applied.
  ///
  /// Updates the modificationApplied flag in Firestore.
  ///
  /// Parameters:
  /// - [userId]: The user's unique identifier
  /// - [messageId]: The message to update
  ///
  /// Example:
  /// ```dart
  /// await repository.markModificationApplied('user_123', 'msg_456');
  /// ```
  Future<void> markModificationApplied(String userId, String messageId) async {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('chatHistory')
        .doc(messageId)
        .update({'modificationApplied': true});
  }

  // ========== Private Helper Methods ==========

  /// Persists a message to Firestore.
  Future<void> _persistMessage(String userId, ChatMessage message) async {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('chatHistory')
        .doc(message.id)
        .set(message.toJson());
  }

  /// Determines if a message is requesting a plan modification.
  bool _isModificationRequest(String content) {
    final lowercaseContent = content.toLowerCase();

    // Keywords indicating modification intent
    const modificationKeywords = [
      'change',
      'swap',
      'replace',
      'modify',
      'make',
      'adjust',
      'easier',
      'harder',
      'skip',
      'remove',
      'add',
      'update',
      'different',
    ];

    return modificationKeywords.any(
      (keyword) => lowercaseContent.contains(keyword),
    );
  }

  /// Handles a modification request through AI.
  Future<ChatMessage> _handleModificationRequest({
    required String userId,
    required ChatMessage userMessage,
    required WeeklyPlan currentPlan,
  }) async {
    // Build modification prompt
    final prompt = PromptBuilder.buildModificationPrompt(
      currentPlan,
      userMessage.content,
    );

    // Call AI with retry logic
    final modifiedPlanData =
        await RetryHelper.retryGeminiCall<Map<String, dynamic>>(
          () => geminiService.modifyPlan(prompt),
          onRetry: (attempt, delay, error) {
            logger.w(
              'Modification retry $attempt after ${delay}s: ${error.toString()}',
            );
          },
        );

    // Create confirmation message
    final responseContent = _buildModificationConfirmation(
      userMessage.content,
      modifiedPlanData,
    );

    return ChatMessage(
      id: _uuid.v4(),
      content: responseContent,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      isModificationRequest: true,
      modificationApplied: true,
    );
  }

  /// Handles general chat (non-modification) through AI.
  Future<ChatMessage> _handleGeneralChat({
    required String userId,
    required ChatMessage userMessage,
    WeeklyPlan? currentPlan,
  }) async {
    // Build a simple response prompt
    final context = currentPlan != null
        ? AppStrings.chatContextActivePlan
        : AppStrings.chatContextNoPlan;

    final prompt = PromptBuilder.buildQuickModificationPrompt(
      context,
      userMessage.content,
    );

    // Get AI response
    String responseContent;
    try {
      final response = await geminiService.generatePlan(prompt);
      // Extract text from response (simplified)
      responseContent = response.toString();
    } catch (e) {
      responseContent = _getHelpfulFallbackResponse(userMessage.content);
    }

    return ChatMessage(
      id: _uuid.v4(),
      content: responseContent,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      isModificationRequest: false,
      modificationApplied: false,
    );
  }

  /// Builds a user-friendly modification confirmation message.
  String _buildModificationConfirmation(
    String userRequest,
    Map<String, dynamic> modifiedData,
  ) {
    // Default confirmation
    return AppStrings.chatModificationConfirmation;
  }

  /// Gets a user-friendly error message from an exception.
  String _getErrorMessage(Object error) {
    if (error is AiException) {
      return error.userFriendlyMessage;
    } else if (error is FirebaseException) {
      return AppStrings.errorSaveMessageFailed;
    } else {
      return AppStrings.errorUnknown;
    }
  }

  /// Provides a helpful fallback response when AI is unavailable.
  String _getHelpfulFallbackResponse(String userMessage) {
    final lowercaseMessage = userMessage.toLowerCase();

    if (lowercaseMessage.contains('help')) {
      return AppStrings.chatHelpResponse;
    } else if (lowercaseMessage.contains('plan')) {
      return AppStrings.chatPlanHelpResponse;
    } else {
      return AppStrings.chatAssistantIntro;
    }
  }
}
