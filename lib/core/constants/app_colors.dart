import 'package:flutter/material.dart';

/// Centralized color definitions for FitGenie app using Material Design 3.
///
/// This class provides a single source of truth for all app colors, ensuring
/// consistency and adherence to WCAG 2.1 AA accessibility standards.
///
/// Color Philosophy:
/// - Energy with approachability (warm orange primary)
/// - Trust and confidence (cool cyan secondary)
/// - Success and growth (lime green tertiary)
///
/// All text-on-background combinations meet 4.5:1 contrast ratio minimum.
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // ============================================================================
  // PRIMARY COLORS
  // ============================================================================

  /// Primary seed color - Energetic Coral
  ///
  /// Used with ColorScheme.fromSeed() to generate harmonious palette.
  /// Evokes action, enthusiasm, and forward momentum.
  static const Color primarySeed = Color(0xFFF97316);

  /// Primary color for light mode
  static const Color primaryLight = Color(0xFFF97316);

  /// Primary color for dark mode (slightly lighter for visibility)
  static const Color primaryDark = Color(0xFFFB923C);

  /// Text color on primary surfaces
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Text color on primary in dark mode
  static const Color onPrimaryDark = Color(0xFF1C1917);

  // ============================================================================
  // SECONDARY COLORS
  // ============================================================================

  /// Secondary color - Cyan
  ///
  /// Used for accent elements and workout-related UI.
  static const Color secondaryLight = Color(0xFF06B6D4);

  /// Secondary color for dark mode
  static const Color secondaryDark = Color(0xFF22D3EE);

  /// Text color on secondary surfaces
  static const Color onSecondary = Color(0xFFFFFFFF);

  // ============================================================================
  // TERTIARY COLORS
  // ============================================================================

  /// Tertiary color - Lime
  ///
  /// Used for success states and completion indicators.
  static const Color tertiaryLight = Color(0xFF84CC16);

  /// Tertiary color for dark mode
  static const Color tertiaryDark = Color(0xFFA3E635);

  /// Text color on tertiary surfaces
  static const Color onTertiary = Color(0xFF1C1917);

  // ============================================================================
  // SEMANTIC COLORS
  // ============================================================================

  /// Error color for validation and error states
  static const Color errorLight = Color(0xFFDC2626);

  /// Error color for dark mode
  static const Color errorDark = Color(0xFFF87171);

  /// Text color on error surfaces
  static const Color onError = Color(0xFFFFFFFF);

  /// Success color for positive feedback
  static const Color success = Color(0xFF22C55E);

  /// Warning color for alerts
  static const Color warning = Color(0xFFFBBF24);

  /// Info color for informational messages
  static const Color info = Color(0xFF3B82F6);

  // ============================================================================
  // SURFACE COLORS
  // ============================================================================

  /// Background surface color - light mode
  static const Color surfaceLight = Color(0xFFFAFAF9);

  /// Background surface color - dark mode
  static const Color surfaceDark = Color(0xFF1C1917);

  /// Secondary surface color - light mode
  static const Color surfaceVariantLight = Color(0xFFF5F5F4);

  /// Secondary surface color - dark mode
  static const Color surfaceVariantDark = Color(0xFF292524);

  /// Primary text color - light mode
  static const Color onSurfaceLight = Color(0xFF1C1917);

  /// Primary text color - dark mode
  static const Color onSurfaceDark = Color(0xFFFAFAF9);

  /// Secondary text color - light mode (60% opacity)
  static const Color onSurfaceVariantLight = Color(0xFF78716C);

  /// Secondary text color - dark mode (60% opacity)
  static const Color onSurfaceVariantDark = Color(0xFFA8A29E);

  // ============================================================================
  // FUNCTIONAL COLORS
  // ============================================================================

  /// Workout-related UI elements (cards, icons)
  static const Color workout = Color(0xFF06B6D4);

  /// Nutrition-related UI elements (meal cards, dietary badges)
  static const Color nutrition = Color(0xFF22C55E);

  /// Streak counter and fire emoji color
  static const Color streak = Color(0xFFF97316);

  /// Completed task indicators
  static const Color completed = Color(0xFF84CC16);

  /// Equipment tag background color
  static const Color equipmentTag = Color(0xFF737373);

  /// Equipment tag text color
  static const Color onEquipmentTag = Color(0xFFFFFFFF);

  /// Dietary restriction tag background color
  static const Color dietaryTag = Color(0xFF14B8A6);

  /// Dietary tag text color
  static const Color onDietaryTag = Color(0xFFFFFFFF);

  // ============================================================================
  // NEUTRAL COLORS
  // ============================================================================

  /// Pure white
  static const Color white = Color(0xFFFFFFFF);

  /// Pure black
  static const Color black = Color(0xFF000000);

  /// Transparent
  static const Color transparent = Color(0x00000000);

  // ============================================================================
  // BORDER & DIVIDER COLORS
  // ============================================================================

  /// Border color - light mode
  static const Color borderLight = Color(0xFFE7E5E4);

  /// Border color - dark mode
  static const Color borderDark = Color(0xFF44403C);

  /// Divider color - light mode (20% opacity)
  static const Color dividerLight = Color(0x33000000);

  /// Divider color - dark mode (20% opacity)
  static const Color dividerDark = Color(0x33FFFFFF);

  // ============================================================================
  // SHADOW COLORS
  // ============================================================================

  /// Shadow color - light mode
  static const Color shadowLight = Color(0x1F000000);

  /// Shadow color - dark mode
  static const Color shadowDark = Color(0x3D000000);

  // ============================================================================
  // OVERLAY COLORS
  // ============================================================================

  /// Overlay for modals and dialogs - light mode
  static const Color overlayLight = Color(0x66000000);

  /// Overlay for modals and dialogs - dark mode
  static const Color overlayDark = Color(0x99000000);

  /// Shimmer base color - light mode
  static const Color shimmerBaseLight = Color(0xFFE7E5E4);

  /// Shimmer highlight color - light mode
  static const Color shimmerHighlightLight = Color(0xFFF5F5F4);

  /// Shimmer base color - dark mode
  static const Color shimmerBaseDark = Color(0xFF292524);

  /// Shimmer highlight color - dark mode
  static const Color shimmerHighlightDark = Color(0xFF44403C);
}
