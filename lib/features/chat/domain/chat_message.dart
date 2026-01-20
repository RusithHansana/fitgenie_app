import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/extensions/date_extensions.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

/// Enumeration of message roles in the chat conversation.
///
/// Determines the sender of a message and affects UI presentation.
enum MessageRole {
  /// Message sent by the user (human).
  ///
  /// Displayed on the right side of the chat interface with user styling.
  user,

  /// Message sent by the AI assistant (FitGenie).
  ///
  /// Displayed on the left side with assistant styling.
  assistant,

  /// System message (informational, non-conversational).
  ///
  /// Used for status updates like "Plan modified successfully".
  /// Displayed centered with neutral styling.
  system,
}

/// Represents a single message in the chat conversation.
///
/// This is the core domain model for the chat feature, representing messages
/// exchanged between the user and the AI assistant. Messages are persisted to
/// Firestore and cached locally for offline access.
///
/// Key Features:
/// - Immutable data structure via Freezed
/// - JSON serialization for Firestore storage
/// - Tracks modification requests and their application status
/// - Contains sender role and timestamp for ordering
/// - Unique ID for message identification and updates
///
/// Data Flow:
/// 1. User types message → ChatMessage created with role=user
/// 2. Message sent to ChatRepository → Persisted to Firestore
/// 3. AI processes request → ChatMessage created with role=assistant
/// 4. If modification: isModificationRequest=true, applied tracked
/// 5. Messages displayed in ChatBubble widgets ordered by timestamp
///
/// Storage:
/// - Firestore: `/users/{userId}/chatHistory/{messageId}`
/// - Real-time updates via Firestore snapshots
/// - Messages ordered by timestamp ascending (oldest first)
///
/// Example:
/// ```dart
/// // User message
/// final userMessage = ChatMessage(
///   id: 'msg_123',
///   content: 'Make Tuesday lunch vegetarian',
///   role: MessageRole.user,
///   timestamp: DateTime.now(),
///   isModificationRequest: true,
///   modificationApplied: false,
/// );
///
/// // Assistant response
/// final assistantMessage = ChatMessage(
///   id: 'msg_124',
///   content: 'I\'ve updated Tuesday\'s lunch to be vegetarian.',
///   role: MessageRole.assistant,
///   timestamp: DateTime.now(),
///   isModificationRequest: false,
///   modificationApplied: true,
/// );
///
/// // Parse from Firestore
/// final fromJson = ChatMessage.fromJson(firestoreDoc.data());
/// ```
///
/// Generated files:
/// - `chat_message.freezed.dart` - Freezed generated code
/// - `chat_message.g.dart` - JSON serialization code
///
/// Run `flutter pub run build_runner build` to generate after changes.
@freezed
class ChatMessage with _$ChatMessage {
  /// Private constructor for adding custom methods.
  const ChatMessage._();

  /// Creates a ChatMessage with the specified properties.
  ///
  /// All fields are required. The [timestamp] is stored as ISO 8601 string
  /// in JSON/Firestore and converted to DateTime in Dart.
  ///
  /// Parameters:
  /// - [id]: Unique identifier for the message
  /// - [content]: The text content of the message
  /// - [role]: Who sent the message (user, assistant, system)
  /// - [timestamp]: When the message was created
  /// - [isModificationRequest]: Whether this message requests a plan change
  /// - [modificationApplied]: Whether the modification was successfully applied
  const factory ChatMessage({
    /// Unique identifier for the message.
    ///
    /// Generated during message creation. Used as document ID in Firestore.
    ///
    /// Format: UUID v4 or timestamp-based unique ID.
    required String id,

    /// The text content of the message.
    ///
    /// For user messages: The user's natural language request
    /// For assistant messages: The AI's response
    /// For system messages: Status updates or notifications
    ///
    /// Maximum length: 5000 characters (enforced at repository level)
    required String content,

    /// The role of the message sender.
    ///
    /// Determines:
    /// - Message bubble alignment (left vs right)
    /// - Message bubble styling (colors, icons)
    /// - Message processing logic
    @JsonKey(name: 'role') required MessageRole role,

    /// Timestamp when the message was created.
    ///
    /// Stored as ISO 8601 string in JSON/Firestore.
    /// Used for:
    /// - Message ordering in chat list
    /// - Display of relative timestamps ("2 min ago")
    /// - Conversation history filtering
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
    required DateTime timestamp,

    /// Whether this message represents a plan modification request.
    ///
    /// When true, the message content should be parsed to determine
    /// the type of modification requested (swap meal, adjust workout, etc.).
    ///
    /// User messages: Determined by content analysis
    /// Assistant messages: True if confirming a modification
    @Default(false) bool isModificationRequest,

    /// Whether the requested modification was successfully applied.
    ///
    /// Only relevant when [isModificationRequest] is true.
    ///
    /// States:
    /// - false: Modification pending or failed
    /// - true: Modification successfully applied to plan
    ///
    /// Used to show checkmark indicator in ChatBubble.
    @Default(false) bool modificationApplied,
  }) = _ChatMessage;

  /// Creates a ChatMessage from a JSON map.
  ///
  /// Used for deserializing from:
  /// - Firestore documents
  /// - Local cache
  /// - API responses
  ///
  /// Example:
  /// ```dart
  /// final message = ChatMessage.fromJson({
  ///   'id': 'msg_123',
  ///   'content': 'Hello!',
  ///   'role': 'user',
  ///   'timestamp': '2026-01-20T10:30:00.000Z',
  ///   'isModificationRequest': false,
  ///   'modificationApplied': false,
  /// });
  /// ```
  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  /// Whether this is a user message.
  bool get isUser => role == MessageRole.user;

  /// Whether this is an assistant message.
  bool get isAssistant => role == MessageRole.assistant;

  /// Whether this is a system message.
  bool get isSystem => role == MessageRole.system;

  /// Whether this message should show a loading indicator.
  ///
  /// True for modification requests that haven't been applied yet.
  bool get isLoading => isModificationRequest && !modificationApplied;

  /// Whether this message should show a success checkmark.
  ///
  /// True for modification requests that have been successfully applied.
  bool get showSuccessIndicator => isModificationRequest && modificationApplied;

  /// Formatted relative timestamp for display.
  ///
  /// Examples:
  /// - "Just now" (< 1 min ago)
  /// - "2 min ago"
  /// - "1 hour ago"
  /// - "Yesterday"
  /// - "Jan 20" (older than 7 days)
  String get relativeTimestamp {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      // Format as "Jan 20"
      return timestamp.shortDate;
    }
  }
}

/// Converts a DateTime to ISO 8601 string for JSON serialization.
String _dateTimeToJson(DateTime dateTime) => dateTime.toIso8601String();

/// Converts an ISO 8601 string to DateTime for JSON deserialization.
DateTime _dateTimeFromJson(dynamic json) {
  if (json is String) {
    return DateTime.parse(json);
  } else if (json is DateTime) {
    return json;
  } else {
    throw FormatException('Invalid timestamp format: $json');
  }
}
