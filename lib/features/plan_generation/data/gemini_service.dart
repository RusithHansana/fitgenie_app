import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:fitgenie_app/core/config/app_config.dart';
import 'package:fitgenie_app/core/constants/ai_constants.dart';
import 'package:fitgenie_app/core/exceptions/ai_exception.dart';
import 'package:fitgenie_app/core/utils/json_parser.dart';
import 'package:fitgenie_app/core/utils/retry_helper.dart';

/// Service for interacting with Google Gemini AI API.
///
/// This service encapsulates all Gemini API communication with:
/// - Automatic retry logic for transient failures
/// - Error transformation to typed AiException
/// - Response parsing and validation via JsonParser
/// - Timeout handling per architecture spec
/// - Rate limit management
///
/// Key Responsibilities:
/// - Execute plan generation prompts
/// - Execute plan modification prompts
/// - Parse JSON responses from AI
/// - Transform API errors to app-specific exceptions
/// - Apply exponential backoff retry for failures
///
/// Usage:
/// ```dart
/// final service = GeminiService();
///
/// // Generate a new plan
/// final planJson = await service.generatePlan(promptString);
/// final plan = WeeklyPlan.fromJson(planJson);
///
/// // Modify existing plan
/// final modifiedJson = await service.modifyPlan(modificationPrompt);
/// ```
///
/// Error Handling:
/// - Network errors → AiException(AiErrorType.networkError)
/// - Rate limits → AiException(AiErrorType.rateLimited)
/// - Invalid responses → AiException(AiErrorType.invalidResponse)
/// - Parse errors → AiException(AiErrorType.parseError)
/// - Timeouts → AiException(AiErrorType.timeout)
///
/// Architecture Notes:
/// - Uses gemini-1.5-flash model for speed (as per requirements)
/// - 60-second timeout for generation calls
/// - Max 3 retries with exponential backoff
/// - API key loaded from AppConfig
class GeminiService {
  /// Creates a GeminiService instance.
  ///
  /// Initializes the Gemini model with API key from app configuration.
  /// The model is lazily created on first use.
  GeminiService() {
    _initializeModel();
  }

  /// The Gemini generative model instance.
  late final GenerativeModel _model;

  /// Whether the model has been initialized.
  bool _isInitialized = false;

  /// Initializes the Gemini model with configuration.
  ///
  /// Uses configuration from AiConstants for optimal speed/quality balance.
  /// See AiConstants for detailed explanations of each parameter value.
  void _initializeModel() {
    if (_isInitialized) return;

    try {
      final apiKey = AppConfig.geminiApiKey;

      _model = GenerativeModel(
        model: AiConstants.modelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: AiConstants.temperature,
          topK: AiConstants.topK,
          topP: AiConstants.topP,
          maxOutputTokens: AiConstants.maxOutputTokens,
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
          SafetySetting(
            HarmCategory.sexuallyExplicit,
            HarmBlockThreshold.medium,
          ),
          SafetySetting(
            HarmCategory.dangerousContent,
            HarmBlockThreshold.medium,
          ),
        ],
      );

      _isInitialized = true;
    } catch (e) {
      throw AiException(
        AiErrorType.invalidApiKey,
        'Failed to initialize Gemini model: $e',
      );
    }
  }

  /// Generates a new fitness plan using the provided prompt.
  ///
  /// This method:
  /// 1. Sends the prompt to Gemini API
  /// 2. Waits for response (with timeout)
  /// 3. Parses JSON from response
  /// 4. Validates response structure
  /// 5. Returns parsed JSON Map
  ///
  /// Automatic retry with exponential backoff is applied for:
  /// - Network errors
  /// - Rate limit errors
  /// - Timeout errors
  ///
  /// Parameters:
  /// - [prompt]: Complete prompt string from PromptBuilder
  ///
  /// Returns: Parsed JSON Map ready for WeeklyPlan.fromJson()
  ///
  /// Throws:
  /// - [AiException] with appropriate error type for all failures
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final planJson = await service.generatePlan(promptString);
  ///   final plan = WeeklyPlan.fromJson(planJson);
  /// } on AiException catch (e) {
  ///   print('AI error: ${e.userFriendlyMessage}');
  /// }
  /// ```
  Future<Map<String, dynamic>> generatePlan(String prompt) async {
    return await RetryHelper.retryGeminiCall<Map<String, dynamic>>(
      () => _executeGeneration(prompt),
      onRetry: (attempt, delay, error) {
        // Log retry attempts for debugging
        print(
          'Gemini generation retry $attempt after ${delay}s: ${error.toString()}',
        );
      },
    );
  }

  /// Modifies an existing plan using the provided prompt.
  ///
  /// Similar to [generatePlan] but used for plan modifications.
  /// The prompt should include the current plan context.
  ///
  /// Parameters:
  /// - [prompt]: Complete modification prompt from PromptBuilder
  ///
  /// Returns: Parsed JSON Map with modified plan
  ///
  /// Throws:
  /// - [AiException] with appropriate error type for all failures
  ///
  /// Example:
  /// ```dart
  /// final modifiedJson = await service.modifyPlan(modPrompt);
  /// final updatedPlan = WeeklyPlan.fromJson(modifiedJson);
  /// ```
  Future<Map<String, dynamic>> modifyPlan(String prompt) async {
    return await RetryHelper.retryGeminiCall<Map<String, dynamic>>(
      () => _executeGeneration(prompt),
      onRetry: (attempt, delay, error) {
        print(
          'Gemini modification retry $attempt after ${delay}s: ${error.toString()}',
        );
      },
    );
  }

  /// Executes the actual API call to Gemini.
  ///
  /// Internal method that performs the generation with timeout.
  /// This is separated from public methods to enable retry wrapping.
  Future<Map<String, dynamic>> _executeGeneration(String prompt) async {
    if (!_isInitialized) {
      throw const AiException(
        AiErrorType.unknown,
        'Gemini model not initialized',
      );
    }

    try {
      // Generate content with timeout
      final response = await _model
          .generateContent([Content.text(prompt)])
          .timeout(
            Duration(seconds: AppConfig.aiGenerationTimeoutSeconds),
            onTimeout: () {
              throw AiException(
                AiErrorType.timeout,
                'Gemini API request timed out after ${AppConfig.aiGenerationTimeoutSeconds} seconds',
              );
            },
          );

      // Extract text from response
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw const AiException(
          AiErrorType.invalidResponse,
          'Gemini returned empty response',
        );
      }

      // Check for safety blocks
      if (response.candidates.isEmpty) {
        throw const AiException(
          AiErrorType.contentFiltered,
          'Content was blocked by safety filters',
        );
      }

      // Parse JSON from response using JsonParser
      try {
        final jsonMap = JsonParser.parseGeminiResponse(text);

        // Validate that we have required top-level fields
        _validatePlanJson(jsonMap);

        return jsonMap;
      } on AiException {
        // Re-throw parsing exceptions as-is
        rethrow;
      } catch (e) {
        throw AiException(
          AiErrorType.parseError,
          'Failed to parse Gemini response: $e',
        );
      }
    } on AiException {
      // Re-throw AiExceptions without wrapping
      rethrow;
    } on GenerativeAIException catch (e) {
      // Transform Gemini-specific errors to AiException
      throw _transformGeminiException(e);
    } catch (e) {
      // Catch-all for unexpected errors
      throw AiException(
        AiErrorType.unknown,
        'Unexpected error during generation: $e',
      );
    }
  }

  /// Validates that the parsed JSON contains required plan fields.
  ///
  /// Checks for:
  /// - 'id' field exists
  /// - 'days' field exists and is a list
  /// - 'days' list has exactly 7 items
  ///
  /// Throws [AiException] with [AiErrorType.invalidResponse] if validation fails.
  void _validatePlanJson(Map<String, dynamic> json) {
    // Check for required fields
    if (!json.containsKey('id')) {
      throw const AiException(
        AiErrorType.invalidResponse,
        'Plan JSON missing required field: id',
      );
    }

    if (!json.containsKey('days')) {
      throw const AiException(
        AiErrorType.invalidResponse,
        'Plan JSON missing required field: days',
      );
    }

    // Validate days is a list
    final days = json['days'];
    if (days is! List) {
      throw AiException(
        AiErrorType.invalidResponse,
        'Plan JSON field "days" must be a list, got ${days.runtimeType}',
      );
    }

    // Validate we have exactly 7 days
    if (days.length != 7) {
      throw AiException(
        AiErrorType.invalidResponse,
        'Plan must have exactly 7 days, got ${days.length}',
      );
    }
  }

  /// Transforms Gemini API exceptions to typed AiExceptions.
  ///
  /// Maps various Gemini error conditions to appropriate AiErrorType:
  /// - 429 status → rateLimited
  /// - 401/403 → invalidApiKey
  /// - Network errors → networkError
  /// - Other → unknown
  AiException _transformGeminiException(GenerativeAIException e) {
    final message = e.message.toLowerCase();

    // Check for rate limiting
    if (message.contains('rate limit') ||
        message.contains('quota') ||
        message.contains('429')) {
      return AiException(
        AiErrorType.rateLimited,
        'Gemini API rate limit exceeded: ${e.message}',
      );
    }

    // Check for authentication errors
    if (message.contains('api key') ||
        message.contains('401') ||
        message.contains('403') ||
        message.contains('unauthorized')) {
      return AiException(
        AiErrorType.invalidApiKey,
        'Gemini API key invalid or missing: ${e.message}',
      );
    }

    // Check for network-related errors
    if (message.contains('network') ||
        message.contains('connection') ||
        message.contains('timeout')) {
      return AiException(
        AiErrorType.networkError,
        'Network error during Gemini API call: ${e.message}',
      );
    }

    // Check for content filtering
    if (message.contains('safety') || message.contains('blocked')) {
      return AiException(
        AiErrorType.contentFiltered,
        'Content blocked by safety filters: ${e.message}',
      );
    }

    // Generic API error
    return AiException(AiErrorType.unknown, 'Gemini API error: ${e.message}');
  }

  /// Sends a simple chat message to Gemini for quick interactions.
  ///
  /// Used for conversational responses that don't require full plan generation.
  /// Lighter weight than full plan generation.
  ///
  /// Parameters:
  /// - [message]: User's message or question
  ///
  /// Returns: AI's text response
  ///
  /// Throws:
  /// - [AiException] for any errors
  ///
  /// Example:
  /// ```dart
  /// final response = await service.sendChatMessage(
  ///   'Can you explain why Tuesday is a rest day?',
  /// );
  /// ```
  Future<String> sendChatMessage(String message) async {
    if (!_isInitialized) {
      throw const AiException(
        AiErrorType.unknown,
        'Gemini model not initialized',
      );
    }

    try {
      final response = await _model
          .generateContent([Content.text(message)])
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw const AiException(
                AiErrorType.timeout,
                'Chat message timed out',
              );
            },
          );

      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw const AiException(
          AiErrorType.invalidResponse,
          'Empty response from Gemini',
        );
      }

      return text.trim();
    } on AiException {
      rethrow;
    } on GenerativeAIException catch (e) {
      throw _transformGeminiException(e);
    } catch (e) {
      throw AiException(AiErrorType.unknown, 'Chat error: $e');
    }
  }
}
