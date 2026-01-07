import 'dart:convert';

import 'package:fitgenie_app/core/exceptions/ai_exception.dart';

/// Safe JSON parsing utilities for Gemini API responses.
///
/// This class handles the complexities of parsing JSON from AI-generated
/// responses, which may be wrapped in markdown code blocks or contain
/// extraneous text.
///
/// Critical for plan generation reliability:
/// - Gemini may wrap JSON in ```json code blocks
/// - Responses may include explanatory text before/after JSON
/// - Must validate that required fields exist
/// - Must provide helpful error messages for debugging
///
/// Usage:
/// ```dart
/// try {
///   final data = JsonParser.parseGeminiResponse(aiResponse);
///   final plan = WeeklyPlan.fromJson(data);
/// } on AiException catch (e) {
///   // Handle parse error
///   print(e.userFriendlyMessage);
/// }
/// ```
class JsonParser {
  JsonParser._(); // Private constructor to prevent instantiation

  // ==========================================================================
  // GEMINI RESPONSE PARSING
  // ==========================================================================

  /// Parses JSON from a Gemini API response string.
  ///
  /// Handles multiple response formats:
  /// - Plain JSON object: `{"key": "value"}`
  /// - Markdown-wrapped: ```json\n{"key": "value"}\n```
  /// - With explanatory text: "Here's your plan:\n```json\n{...}\n```"
  ///
  /// Returns the parsed JSON as a Map`<String, dynamic>`.
  /// Throws [AiException] with [AiErrorType.parseError] if parsing fails.
  ///
  /// Example:
  /// ```dart
  /// // Plain JSON
  /// final data1 = JsonParser.parseGeminiResponse('{"name": "John"}');
  ///
  /// // Markdown-wrapped
  /// final data2 = JsonParser.parseGeminiResponse('```json\n{"name": "John"}\n```');
  ///
  /// // With text
  /// final data3 = JsonParser.parseGeminiResponse(
  ///   'Here is your plan:\n```json\n{"name": "John"}\n```'
  /// );
  /// ```
  static Map<String, dynamic> parseGeminiResponse(String response) {
    if (response.trim().isEmpty) {
      throw const AiException(
        AiErrorType.parseError,
        'Empty response from Gemini API',
      );
    }

    try {
      // Try to extract JSON from markdown code block first
      final jsonString = extractJsonBlock(response);

      // Try to parse the extracted or raw string
      final decoded = jsonDecode(jsonString);

      // Ensure it's a Map (not a List or primitive)
      if (decoded is! Map<String, dynamic>) {
        throw const AiException(
          AiErrorType.parseError,
          'Response is not a JSON object',
        );
      }

      return decoded;
    } on FormatException catch (e) {
      throw AiException(
        AiErrorType.parseError,
        'Invalid JSON format: ${e.message}',
      );
    } on AiException {
      rethrow;
    } catch (e) {
      throw AiException(AiErrorType.parseError, 'Failed to parse response: $e');
    }
  }

  /// Extracts JSON block from markdown code fences or plain text.
  ///
  /// Handles:
  /// - Plain JSON: `{"key": "value"}` → returns as-is
  /// - JSON code block: ```json\n{...}\n``` → extracts content
  /// - Generic code block: ```\n{...}\n``` → extracts content
  /// - Text with JSON: "Here's your data: {...}" → extracts JSON portion
  ///
  /// Returns the extracted JSON string.
  /// Throws [AiException] if no valid JSON block is found.
  ///
  /// Example:
  /// ```dart
  /// final json1 = JsonParser.extractJsonBlock('{"name": "John"}');
  /// // Returns: '{"name": "John"}'
  ///
  /// final json2 = JsonParser.extractJsonBlock('```json\n{"name": "John"}\n```');
  /// // Returns: '{"name": "John"}'
  /// ```
  static String extractJsonBlock(String text) {
    final trimmed = text.trim();

    // Pattern 1: Try to extract from ```json or ``` code blocks
    final codeBlockPattern = RegExp(
      r'```(?:json)?\s*\n?([\s\S]*?)\n?```',
      multiLine: true,
    );

    final codeBlockMatch = codeBlockPattern.firstMatch(trimmed);
    if (codeBlockMatch != null) {
      final content = codeBlockMatch.group(1)?.trim();
      if (content != null && content.isNotEmpty) {
        return content;
      }
    }

    // Pattern 2: Try to find JSON object boundaries { ... }
    final jsonObjectPattern = RegExp(r'\{[\s\S]*\}', multiLine: true);

    final jsonMatch = jsonObjectPattern.firstMatch(trimmed);
    if (jsonMatch != null) {
      final content = jsonMatch.group(0)?.trim();
      if (content != null && content.isNotEmpty) {
        return content;
      }
    }

    // Pattern 3: Try to find JSON array boundaries [ ... ]
    final jsonArrayPattern = RegExp(r'\[[\s\S]*\]', multiLine: true);

    final arrayMatch = jsonArrayPattern.firstMatch(trimmed);
    if (arrayMatch != null) {
      final content = arrayMatch.group(0)?.trim();
      if (content != null && content.isNotEmpty) {
        return content;
      }
    }

    // If already looks like valid JSON, return as-is
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      return trimmed;
    }

    // No valid JSON found
    throw AiException(
      AiErrorType.parseError,
      'Could not extract JSON from response: ${text.substring(0, text.length > 100 ? 100 : text.length)}...',
    );
  }

  // ==========================================================================
  // SAFE DECODING
  // ==========================================================================

  /// Safely attempts to decode a JSON string.
  ///
  /// Returns the decoded value or null if decoding fails.
  /// Does not throw exceptions.
  ///
  /// Example:
  /// ```dart
  /// final data = JsonParser.tryDecode('{"name": "John"}');
  /// // Returns: {"name": "John"}
  ///
  /// final invalid = JsonParser.tryDecode('invalid json');
  /// // Returns: null
  /// ```
  static dynamic tryDecode(String jsonString) {
    try {
      return jsonDecode(jsonString);
    } catch (_) {
      return null;
    }
  }

  /// Safely attempts to decode a JSON string to a Map.
  ///
  /// Returns the decoded Map or null if decoding fails or result is not a Map.
  /// Does not throw exceptions.
  ///
  /// Example:
  /// ```dart
  /// final data = JsonParser.tryDecodeMap('{"name": "John"}');
  /// // Returns: {"name": "John"}
  ///
  /// final array = JsonParser.tryDecodeMap('[1, 2, 3]');
  /// // Returns: null (not a map)
  /// ```
  static Map<String, dynamic>? tryDecodeMap(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  /// Safely attempts to decode a JSON string to a List.
  ///
  /// Returns the decoded List or null if decoding fails or result is not a List.
  /// Does not throw exceptions.
  ///
  /// Example:
  /// ```dart
  /// final data = JsonParser.tryDecodeList('[1, 2, 3]');
  /// // Returns: [1, 2, 3]
  ///
  /// final object = JsonParser.tryDecodeList('{"name": "John"}');
  /// // Returns: null (not a list)
  /// ```
  static List<dynamic>? tryDecodeList(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      return decoded is List ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  // ==========================================================================
  // VALIDATION
  // ==========================================================================

  /// Validates that a JSON map contains all required fields.
  ///
  /// Throws [AiException] with [AiErrorType.invalidResponse] if any
  /// required field is missing.
  ///
  /// Example:
  /// ```dart
  /// final data = {"name": "John", "age": 30};
  /// JsonParser.validateRequiredFields(data, ['name', 'age']);
  /// // No exception
  ///
  /// JsonParser.validateRequiredFields(data, ['name', 'email']);
  /// // Throws AiException: Missing required field: email
  /// ```
  static void validateRequiredFields(
    Map<String, dynamic> data,
    List<String> requiredFields,
  ) {
    for (final field in requiredFields) {
      if (!data.containsKey(field)) {
        throw AiException(
          AiErrorType.invalidResponse,
          'Missing required field: $field',
        );
      }
    }
  }

  /// Validates that a JSON map contains at least one of the specified fields.
  ///
  /// Throws [AiException] with [AiErrorType.invalidResponse] if none of
  /// the fields are present.
  ///
  /// Example:
  /// ```dart
  /// final data = {"email": "user@example.com"};
  /// JsonParser.validateAtLeastOneField(data, ['email', 'phone']);
  /// // No exception (email is present)
  ///
  /// JsonParser.validateAtLeastOneField(data, ['phone', 'address']);
  /// // Throws AiException: Must have at least one of: phone, address
  /// ```
  static void validateAtLeastOneField(
    Map<String, dynamic> data,
    List<String> fields,
  ) {
    final hasAny = fields.any((field) => data.containsKey(field));
    if (!hasAny) {
      throw AiException(
        AiErrorType.invalidResponse,
        'Must have at least one of: ${fields.join(", ")}',
      );
    }
  }

  /// Validates that a field value is of the expected type.
  ///
  /// Throws [AiException] with [AiErrorType.invalidResponse] if the field
  /// is missing or not of the expected type.
  ///
  /// Example:
  /// ```dart
  /// final data = {"name": "John", "age": 30};
  /// JsonParser.validateFieldType(data, 'name', String);
  /// // No exception
  ///
  /// JsonParser.validateFieldType(data, 'age', String);
  /// // Throws AiException: Field 'age' must be of type String
  /// ```
  static void validateFieldType(
    Map<String, dynamic> data,
    String field,
    Type expectedType,
  ) {
    if (!data.containsKey(field)) {
      throw AiException(
        AiErrorType.invalidResponse,
        'Missing required field: $field',
      );
    }

    final value = data[field];
    if (value.runtimeType != expectedType) {
      throw AiException(
        AiErrorType.invalidResponse,
        'Field \'$field\' must be of type $expectedType, got ${value.runtimeType}',
      );
    }
  }

  // ==========================================================================
  // SAFE VALUE EXTRACTION
  // ==========================================================================

  /// Safely extracts a String value from a JSON map.
  ///
  /// Returns the value or the default if the field is missing or not a String.
  ///
  /// Example:
  /// ```dart
  /// final data = {"name": "John", "age": 30};
  /// final name = JsonParser.getString(data, 'name', 'Unknown');
  /// // Returns: "John"
  ///
  /// final email = JsonParser.getString(data, 'email', 'N/A');
  /// // Returns: "N/A"
  /// ```
  static String getString(
    Map<String, dynamic> data,
    String key,
    String defaultValue,
  ) {
    final value = data[key];
    return value is String ? value : defaultValue;
  }

  /// Safely extracts an int value from a JSON map.
  ///
  /// Returns the value or the default if the field is missing or not an int.
  static int getInt(Map<String, dynamic> data, String key, int defaultValue) {
    final value = data[key];
    return value is int ? value : defaultValue;
  }

  /// Safely extracts a double value from a JSON map.
  ///
  /// Returns the value or the default if the field is missing or not a double.
  /// Also accepts int values and converts them to double.
  static double getDouble(
    Map<String, dynamic> data,
    String key,
    double defaultValue,
  ) {
    final value = data[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return defaultValue;
  }

  /// Safely extracts a bool value from a JSON map.
  ///
  /// Returns the value or the default if the field is missing or not a bool.
  static bool getBool(
    Map<String, dynamic> data,
    String key,
    bool defaultValue,
  ) {
    final value = data[key];
    return value is bool ? value : defaultValue;
  }

  /// Safely extracts a List value from a JSON map.
  ///
  /// Returns the value or the default if the field is missing or not a List.
  static List<T> getList<T>(
    Map<String, dynamic> data,
    String key,
    List<T> defaultValue,
  ) {
    final value = data[key];
    if (value is List) {
      try {
        return value.cast<T>();
      } catch (_) {
        return defaultValue;
      }
    }
    return defaultValue;
  }

  /// Safely extracts a Map value from a JSON map.
  ///
  /// Returns the value or the default if the field is missing or not a Map.
  static Map<String, dynamic> getMap(
    Map<String, dynamic> data,
    String key,
    Map<String, dynamic> defaultValue,
  ) {
    final value = data[key];
    return value is Map<String, dynamic> ? value : defaultValue;
  }

  // ==========================================================================
  // PRETTY PRINTING
  // ==========================================================================

  /// Converts a JSON object to a pretty-printed string.
  ///
  /// Useful for debugging and logging.
  ///
  /// Example:
  /// ```dart
  /// final data = {"name": "John", "age": 30};
  /// print(JsonParser.prettyPrint(data));
  /// // Output:
  /// // {
  /// //   "name": "John",
  /// //   "age": 30
  /// // }
  /// ```
  static String prettyPrint(Object json) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(json);
    } catch (_) {
      return json.toString();
    }
  }
}
