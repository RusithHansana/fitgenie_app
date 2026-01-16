/// Centralized constants for AI model configuration.
///
/// This class provides constants for configuring the Gemini AI model
/// used throughout the application for plan generation and chat features.
///
/// Model Configuration Philosophy:
/// - Use gemini-1.5-flash for optimal speed/quality balance
/// - Temperature controls creativity (0.0 = deterministic, 1.0 = creative)
/// - Top-k and top-p control response diversity
/// - Safety settings balance protection with usability
///
/// These values are tuned for fitness plan generation and should be
/// adjusted carefully based on testing and user feedback.
class AiConstants {
  AiConstants._(); // Private constructor to prevent instantiation

  // ==========================================================================
  // MODEL CONFIGURATION
  // ==========================================================================

  /// Gemini model name to use for all AI operations.
  ///
  /// gemini-1.5-flash provides the best balance of:
  /// - Speed: Fast response times for better UX
  /// - Quality: High-quality plan generation
  /// - Cost: Lower cost per request vs pro models
  static const String modelName = 'gemini-1.5-flash';

  // ==========================================================================
  // GENERATION PARAMETERS
  // ==========================================================================

  /// Temperature for response generation (0.0 - 1.0).
  ///
  /// Controls randomness in output:
  /// - 0.0: Deterministic, focused responses
  /// - 0.7: Balanced creativity and consistency (recommended)
  /// - 1.0: Maximum creativity and variation
  ///
  /// 0.7 provides good variety while maintaining plan structure and quality.
  static const double temperature = 0.7;

  /// Top-k sampling parameter (number of tokens to consider).
  ///
  /// Limits vocabulary to top K most likely tokens at each step:
  /// - Lower values (10-20): More focused, predictable responses
  /// - Medium values (40): Balanced diversity (recommended)
  /// - Higher values (100+): More diverse but potentially less coherent
  ///
  /// 40 provides diverse responses while maintaining quality.
  static const int topK = 40;

  /// Top-p (nucleus) sampling parameter (0.0 - 1.0).
  ///
  /// Selects tokens whose cumulative probability exceeds p:
  /// - Lower values (0.5): More focused responses
  /// - Medium values (0.95): Balanced quality and diversity (recommended)
  /// - Higher values (0.99): Maximum diversity
  ///
  /// 0.95 ensures high-quality responses with good variation.
  static const double topP = 0.95;

  /// Maximum output tokens per generation.
  ///
  /// Limits the length of generated responses:
  /// - 2048: Short responses (quick replies)
  /// - 8192: Full plans with detailed descriptions (recommended)
  /// - 16384+: Very long outputs (may increase costs)
  ///
  /// 8192 provides sufficient space for complete weekly plans with
  /// exercise descriptions, nutrition guidelines, and explanations.
  static const int maxOutputTokens = 8192;

  // ==========================================================================
  // SAFETY SETTINGS
  // ==========================================================================

  /// Safety threshold for content filtering.
  ///
  /// Options:
  /// - HarmBlockThreshold.none: No filtering (not recommended)
  /// - HarmBlockThreshold.low: Block only high-confidence harmful content
  /// - HarmBlockThreshold.medium: Balanced protection (recommended)
  /// - HarmBlockThreshold.high: Strictest filtering
  ///
  /// Medium provides good protection while minimizing false positives
  /// for legitimate fitness and nutrition content.
  ///
  /// Note: This is a string constant for use in documentation.
  /// Actual HarmBlockThreshold enum values are used in code.
  static const String safetyThresholdDescription = 'medium';
}
