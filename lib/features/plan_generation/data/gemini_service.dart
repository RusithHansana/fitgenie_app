import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logger/logger.dart';
import 'package:fitgenie_app/core/config/app_config.dart';
import 'package:fitgenie_app/core/constants/ai_constants.dart';
import 'package:fitgenie_app/core/exceptions/ai_exception.dart';
import 'package:fitgenie_app/core/utils/json_parser.dart';
import 'package:fitgenie_app/core/utils/retry_helper.dart';
import 'package:fitgenie_app/core/utils/rate_limiter.dart';

/// Response validation modes for plan generation.
enum PlanResponseType {
  /// Full 7-day plan response.
  fullPlan,

  /// Partial days response (1-3 days).
  partialDays,

  /// Outline-only response for weekly structure.
  outline,

  /// Partial modification response (changed days only).
  partialModification,
}

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
  /// Logger instance for tracking operations and errors.
  final Logger logger;

  /// Creates a GeminiService instance.
  ///
  /// Initializes the Gemini model with API key from app configuration.
  /// The model is lazily created on first use.
  ///
  /// Parameters:
  /// - [logger]: Logger instance for tracking operations
  GeminiService({required this.logger}) {
    _initializeModel();
  }

  /// The Gemini generative model instance.
  late final GenerativeModel _model;

  /// Whether the model has been initialized.
  bool _isInitialized = false;

  /// Rate limiter to keep Gemini requests under 5 RPM.
  static final RateLimiter _rateLimiter = RateLimiter(
    maxRequests: 4,
    window: const Duration(minutes: 1),
  );

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
      () => _executeGeneration(prompt, responseType: PlanResponseType.fullPlan),
      onRetry: (attempt, delay, error) {
        // Log retry attempts for debugging
        logger.w(
          'Gemini generation retry $attempt after ${delay}s: ${error.toString()}',
        );
      },
    );
  }

  /// Generates a weekly outline used for batched plan generation.
  ///
  /// Returns: Parsed JSON Map containing planId and dayOutline.
  Future<Map<String, dynamic>> generatePlanOutline(String prompt) async {
    return await RetryHelper.retryGeminiCall<Map<String, dynamic>>(
      () => _executeGeneration(prompt, responseType: PlanResponseType.outline),
      onRetry: (attempt, delay, error) {
        logger.w(
          'Gemini outline retry $attempt after ${delay}s: ${error.toString()}',
        );
      },
    );
  }

  /// Generates a partial batch of plan days (1-3 days).
  ///
  /// Returns: Parsed JSON Map containing days array.
  Future<Map<String, dynamic>> generatePlanBatch(String prompt) async {
    return await RetryHelper.retryGeminiCall<Map<String, dynamic>>(
      () => _executeGeneration(
        prompt,
        responseType: PlanResponseType.partialDays,
      ),
      onRetry: (attempt, delay, error) {
        logger.w(
          'Gemini batch retry $attempt after ${delay}s: ${error.toString()}',
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
  @Deprecated('Use modifyPlanPartial instead for partial modifications')
  Future<Map<String, dynamic>> modifyPlan(String prompt) async {
    return await RetryHelper.retryGeminiCall<Map<String, dynamic>>(
      () => _executeGeneration(prompt, responseType: PlanResponseType.fullPlan),
      onRetry: (attempt, delay, error) {
        logger.w(
          'Gemini modification retry $attempt after ${delay}s: ${error.toString()}',
        );
      },
    );
  }

  /// Modifies an existing plan with partial updates.
  ///
  /// Returns only the modified days/items, not the full plan.
  /// The repository will merge these changes with the existing plan.
  ///
  /// Parameters:
  /// - [prompt]: Partial modification prompt from PromptBuilder
  ///
  /// Returns: Parsed JSON Map with modification result containing:
  /// - modificationType: dayReplacement, workoutUpdate, mealUpdate, rejected
  /// - modifiedDays: Array of changed days only
  /// - explanation: AI's description of changes
  ///
  /// Throws:
  /// - [AiException] with appropriate error type for all failures
  ///
  /// Example:
  /// ```dart
  /// final result = await service.modifyPlanPartial(prompt);
  /// if (result['modificationType'] == 'rejected') {
  ///   throw AiException(AiErrorType.invalidRequest, result['explanation']);
  /// }
  /// ```
  Future<Map<String, dynamic>> modifyPlanPartial(String prompt) async {
    return await RetryHelper.retryGeminiCall<Map<String, dynamic>>(
      () => _executeGeneration(
        prompt,
        responseType: PlanResponseType.partialModification,
      ),
      onRetry: (attempt, delay, error) {
        logger.w(
          'Gemini partial modification retry $attempt after ${delay}s: ${error.toString()}',
        );
      },
    );
  }

  /// Executes the actual API call to Gemini.
  ///
  /// Internal method that performs the generation with timeout.
  /// This is separated from public methods to enable retry wrapping.
  Future<Map<String, dynamic>> _executeGeneration(
    String prompt, {
    required PlanResponseType responseType,
  }) async {
    if (!_isInitialized) {
      throw const AiException(
        AiErrorType.unknown,
        'Gemini model not initialized',
      );
    }

    try {
      // Enforce request rate limiting
      await _rateLimiter.acquire();

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

        // Validate based on expected response type
        switch (responseType) {
          case PlanResponseType.fullPlan:
            _validatePlanJson(jsonMap);
            break;
          case PlanResponseType.partialDays:
            _validatePartialPlanJson(jsonMap);
            break;
          case PlanResponseType.outline:
            _validateOutlineJson(jsonMap);
            break;
          case PlanResponseType.partialModification:
            _validatePartialModificationJson(jsonMap);
            break;
        }

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

  /// Validates that the parsed JSON contains required fields for a batch.
  ///
  /// Checks for:
  /// - 'days' field exists and is a list
  /// - 'days' list has 1-3 items
  /// - each day has a valid dayIndex
  void _validatePartialPlanJson(Map<String, dynamic> json) {
    if (!json.containsKey('days')) {
      throw const AiException(
        AiErrorType.invalidResponse,
        'Plan batch JSON missing required field: days',
      );
    }

    final days = json['days'];
    if (days is! List) {
      throw AiException(
        AiErrorType.invalidResponse,
        'Plan batch field "days" must be a list, got ${days.runtimeType}',
      );
    }

    if (days.isEmpty || days.length > 3) {
      throw AiException(
        AiErrorType.invalidResponse,
        'Plan batch must include 1-3 days, got ${days.length}',
      );
    }

    for (final day in days) {
      if (day is! Map<String, dynamic>) {
        throw const AiException(
          AiErrorType.invalidResponse,
          'Each day must be a JSON object',
        );
      }

      if (!day.containsKey('dayIndex')) {
        throw const AiException(
          AiErrorType.invalidResponse,
          'Each day must include dayIndex',
        );
      }
    }
  }

  /// Validates that the outline JSON has all required fields.
  ///
  /// Checks for:
  /// - 'planId' field exists
  /// - 'dayOutline' list with exactly 7 items
  /// - each outline item has dayIndex, workoutType, intensity
  void _validateOutlineJson(Map<String, dynamic> json) {
    if (!json.containsKey('planId')) {
      throw const AiException(
        AiErrorType.invalidResponse,
        'Outline JSON missing required field: planId',
      );
    }

    if (!json.containsKey('dayOutline')) {
      throw const AiException(
        AiErrorType.invalidResponse,
        'Outline JSON missing required field: dayOutline',
      );
    }

    final outline = json['dayOutline'];
    if (outline is! List) {
      throw AiException(
        AiErrorType.invalidResponse,
        'Outline field "dayOutline" must be a list, got ${outline.runtimeType}',
      );
    }

    if (outline.length != 7) {
      throw AiException(
        AiErrorType.invalidResponse,
        'Outline must have exactly 7 days, got ${outline.length}',
      );
    }

    for (final day in outline) {
      if (day is! Map<String, dynamic>) {
        throw const AiException(
          AiErrorType.invalidResponse,
          'Each outline day must be a JSON object',
        );
      }

      if (!day.containsKey('dayIndex') ||
          !day.containsKey('workoutType') ||
          !day.containsKey('intensity')) {
        throw const AiException(
          AiErrorType.invalidResponse,
          'Each outline day must include dayIndex, workoutType, intensity',
        );
      }
    }
  }

  /// Validates that the partial modification JSON has required fields.
  ///
  /// Checks for:
  /// - 'modificationType' field exists and is valid
  /// - 'modifiedDays' field exists (can be empty for rejected)
  /// - 'explanation' field exists
  /// - each modified day has valid dayIndex (0-6)
  void _validatePartialModificationJson(Map<String, dynamic> json) {
    // Check for required modificationType field
    if (!json.containsKey('modificationType')) {
      throw const AiException(
        AiErrorType.invalidResponse,
        'Modification response missing required field: modificationType',
      );
    }

    final modificationType = json['modificationType'];
    final validTypes = ['dayReplacement', 'workoutUpdate', 'mealUpdate', 'rejected'];
    if (!validTypes.contains(modificationType)) {
      throw AiException(
        AiErrorType.invalidResponse,
        'Invalid modificationType: $modificationType. Must be one of: $validTypes',
      );
    }

    // Check for explanation field
    if (!json.containsKey('explanation')) {
      throw const AiException(
        AiErrorType.invalidResponse,
        'Modification response missing required field: explanation',
      );
    }

    // For rejected modifications, modifiedDays can be empty
    if (modificationType == 'rejected') {
      return;
    }

    // For accepted modifications, validate modifiedDays
    if (!json.containsKey('modifiedDays')) {
      throw const AiException(
        AiErrorType.invalidResponse,
        'Modification response missing required field: modifiedDays',
      );
    }

    final modifiedDays = json['modifiedDays'];
    if (modifiedDays is! List) {
      throw AiException(
        AiErrorType.invalidResponse,
        'modifiedDays must be a list, got ${modifiedDays.runtimeType}',
      );
    }

    if (modifiedDays.isEmpty) {
      throw const AiException(
        AiErrorType.invalidResponse,
        'modifiedDays must contain at least one day for non-rejected modifications',
      );
    }

    if (modifiedDays.length > 7) {
      throw AiException(
        AiErrorType.invalidResponse,
        'modifiedDays cannot exceed 7 days, got ${modifiedDays.length}',
      );
    }

    // Validate each modified day
    for (final day in modifiedDays) {
      if (day is! Map<String, dynamic>) {
        throw const AiException(
          AiErrorType.invalidResponse,
          'Each modified day must be a JSON object',
        );
      }

      if (!day.containsKey('dayIndex')) {
        throw const AiException(
          AiErrorType.invalidResponse,
          'Each modified day must include dayIndex',
        );
      }

      final dayIndex = day['dayIndex'];
      if (dayIndex is! int || dayIndex < 0 || dayIndex > 6) {
        throw AiException(
          AiErrorType.invalidResponse,
          'dayIndex must be an integer 0-6, got $dayIndex',
        );
      }
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
      // Enforce request rate limiting
      await _rateLimiter.acquire();

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
