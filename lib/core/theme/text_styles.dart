import 'package:flutter/material.dart';

/// Typography definitions for FitGenie app following Material 3 type scale.
///
/// This class provides a complete TextTheme using the Inter font family
/// (or system default) with carefully chosen sizes and weights that follow
/// the Material Design 3 type scale specification.
///
/// Type Scale Usage:
/// - Display: Large numbers, streak counts (57sp/45sp/36sp)
/// - Headline: Section headers, screen titles (32sp/28sp/24sp)
/// - Title: Card titles, important labels (22sp/16sp/14sp)
/// - Body: Content text, descriptions (16sp/14sp)
/// - Label: Buttons, chips, small labels (14sp/12sp/11sp)
///
/// Font Family:
/// - Primary: Inter (modern, highly legible sans-serif)
/// - Fallback: System default if Inter not available
///
/// Usage:
/// ```dart
/// Text(
///   'Welcome',
///   style: AppTextStyles.textTheme.displayLarge,
/// );
/// ```
///
/// Or via context extension:
/// ```dart
/// Text(
///   'Welcome',
///   style: context.textTheme.displayLarge,
/// );
/// ```
class AppTextStyles {
  AppTextStyles._(); // Private constructor to prevent instantiation

  /// Base font family for the app.
  ///
  /// Uses Inter for its excellent readability and modern appearance.
  /// Falls back to system default if Inter is not available.
  ///
  /// Note: To use Inter font, add google_fonts package or include font files.
  /// For simplicity in this implementation, we use the system default.
  static const String fontFamily = 'Inter';

  // ==========================================================================
  // COMPLETE TEXT THEME
  // ==========================================================================

  /// Complete Material 3 TextTheme with all 13 text styles defined.
  ///
  /// This provides the full type scale from display (largest) to label (smallest).
  /// Each style has appropriate size, weight, and letter spacing for its use case.
  static TextTheme get textTheme {
    return const TextTheme(
      // ========================================================================
      // DISPLAY STYLES - Largest text, used for emphasis
      // ========================================================================

      /// Display Large - 57sp
      ///
      /// Usage: Streak numbers, celebration counts, hero numbers
      /// Example: "🔥 42" (streak display)
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        height: 1.12,
      ),

      /// Display Medium - 45sp
      ///
      /// Usage: Large celebration numbers, milestone counts
      /// Example: "100 workouts completed!"
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.16,
      ),

      /// Display Small - 36sp
      ///
      /// Usage: Section hero text, large statistics
      /// Example: Weekly completion percentage
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.22,
      ),

      // ========================================================================
      // HEADLINE STYLES - Section headers and screen titles
      // ========================================================================

      /// Headline Large - 32sp
      ///
      /// Usage: Main screen titles, modal headers
      /// Example: "Generate Your Plan"
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.25,
      ),

      /// Headline Medium - 28sp
      ///
      /// Usage: Section headers, feature titles
      /// Example: "Today's Workout", "Meal Plan"
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.29,
      ),

      /// Headline Small - 24sp
      ///
      /// Usage: Card group headers, subsection titles
      /// Example: "Morning Routine", "Breakfast"
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.33,
      ),

      // ========================================================================
      // TITLE STYLES - Card titles and important labels
      // ========================================================================

      /// Title Large - 22sp
      ///
      /// Usage: Card titles, list item titles
      /// Example: "Dumbbell Chest Press", "Grilled Chicken Salad"
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.27,
      ),

      /// Title Medium - 16sp / Weight 500
      ///
      /// Usage: Prominent list items, dialog titles
      /// Example: Exercise names in workout list
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        height: 1.50,
      ),

      /// Title Small - 14sp / Weight 500
      ///
      /// Usage: Dense list items, small card titles
      /// Example: Meal ingredient items
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
      ),

      // ========================================================================
      // BODY STYLES - Content and descriptions
      // ========================================================================

      /// Body Large - 16sp
      ///
      /// Usage: Main body text, long-form content
      /// Example: Exercise instructions, meal descriptions
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.50,
      ),

      /// Body Medium - 14sp
      ///
      /// Usage: Standard body text, supporting descriptions
      /// Example: Sets/reps details, ingredient quantities
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
      ),

      /// Body Small - 12sp
      ///
      /// Usage: Captions, footnotes, tertiary information
      /// Example: Timestamps, metadata, helper text
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
      ),

      // ========================================================================
      // LABEL STYLES - Buttons, chips, and small labels
      // ========================================================================

      /// Label Large - 14sp / Weight 500
      ///
      /// Usage: Button text, prominent labels
      /// Example: "Generate Plan", "Save"
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
      ),

      /// Label Medium - 12sp / Weight 500
      ///
      /// Usage: Chip labels, tab labels, navigation labels
      /// Example: "Vegetarian", "Monday", "Dashboard"
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.33,
      ),

      /// Label Small - 11sp / Weight 500
      ///
      /// Usage: Small labels, badges, status indicators
      /// Example: "New", "Completed", equipment tags
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.45,
      ),
    );
  }

  // ==========================================================================
  // SEMANTIC TEXT STYLES
  // ==========================================================================

  /// Text style for streak numbers with emphasis.
  ///
  /// Large, bold display for streak count with flame emoji.
  /// Example: "🔥 42 days"
  static TextStyle get streakNumber {
    return textTheme.displayLarge!.copyWith(
      fontWeight: FontWeight.w700,
      color: const Color(0xFFF97316), // Primary color
    );
  }

  /// Text style for section headers in cards.
  ///
  /// Used for workout section headers, meal categories.
  /// Example: "Warm-up", "Main Course"
  static TextStyle get cardSectionHeader {
    return textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600);
  }

  /// Text style for exercise/meal details (sets, reps, calories).
  ///
  /// Compact, readable format for metadata.
  /// Example: "3 sets × 12 reps", "450 cal"
  static TextStyle get detailText {
    return textTheme.bodyMedium!.copyWith(
      fontWeight: FontWeight.w400,
      color: const Color(0xFF737373), // Neutral gray
    );
  }

  /// Text style for completion timestamps and metadata.
  ///
  /// Small, subtle text for secondary information.
  /// Example: "Completed 2 hours ago"
  static TextStyle get timestampText {
    return textTheme.bodySmall!.copyWith(
      color: const Color(0xFF737373), // Neutral gray
    );
  }

  /// Text style for error messages in forms.
  ///
  /// Red color with appropriate sizing for validation errors.
  static TextStyle get errorText {
    return textTheme.bodySmall!.copyWith(
      color: const Color(0xFFDC2626), // Error red
      fontWeight: FontWeight.w400,
    );
  }

  /// Text style for success messages.
  ///
  /// Green color for positive feedback.
  static TextStyle get successText {
    return textTheme.bodyMedium!.copyWith(
      color: const Color(0xFF22C55E), // Success green
      fontWeight: FontWeight.w500,
    );
  }

  /// Text style for warning messages.
  ///
  /// Yellow color for cautionary information.
  static TextStyle get warningText {
    return textTheme.bodyMedium!.copyWith(
      color: const Color(0xFFFBBF24), // Warning yellow
      fontWeight: FontWeight.w500,
    );
  }

  /// Text style for badge/chip labels.
  ///
  /// Small, bold text for equipment and dietary tags.
  /// Example: "Dumbbells", "Vegetarian"
  static TextStyle get badgeText {
    return textTheme.labelSmall!.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );
  }

  /// Text style for button text with emphasis.
  ///
  /// Slightly bolder than default label large.
  static TextStyle get buttonText {
    return textTheme.labelLarge!.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );
  }

  /// Text style for navigation labels.
  ///
  /// Used in bottom navigation and tabs.
  static TextStyle get navigationLabel {
    return textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w600);
  }

  // ==========================================================================
  // SPECIALIZED STYLES
  // ==========================================================================

  /// Text style for day names in week view.
  ///
  /// Medium weight, appropriate sizing for daily navigation.
  /// Example: "Monday", "Today"
  static TextStyle get dayName {
    return textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w600);
  }

  /// Text style for workout duration display.
  ///
  /// Prominent but not overwhelming, used for time indicators.
  /// Example: "45 minutes"
  static TextStyle get duration {
    return textTheme.titleMedium!.copyWith(
      fontWeight: FontWeight.w500,
      color: const Color(0xFF06B6D4), // Secondary cyan
    );
  }

  /// Text style for calorie counts.
  ///
  /// Emphasized numeric display for nutritional information.
  /// Example: "450 cal"
  static TextStyle get calories {
    return textTheme.titleMedium!.copyWith(
      fontWeight: FontWeight.w600,
      color: const Color(0xFF84CC16), // Tertiary lime
    );
  }
}
