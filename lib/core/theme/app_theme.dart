import 'package:fitgenie_app/core/constants/app_colors.dart';
import 'package:fitgenie_app/core/constants/app_sizes.dart';
import 'package:fitgenie_app/core/theme/color_scheme.dart';
import 'package:fitgenie_app/core/theme/text_styles.dart';
import 'package:flutter/material.dart';

/// Main theme configuration for FitGenie app.
///
/// This class assembles all theme components (colors, typography, component themes)
/// into complete Material 3 ThemeData objects for light and dark modes.
///
/// Usage in main.dart:
/// ```dart
/// MaterialApp(
///   theme: AppTheme.lightTheme,
///   darkTheme: AppTheme.darkTheme,
///   themeMode: ThemeMode.system,
/// );
/// ```
///
/// Theme Philosophy:
/// - Material Design 3 (Material You) with useMaterial3: true
/// - Custom brand colors via ColorScheme.fromSeed()
/// - Inter font family for modern, professional typography
/// - Consistent border radius (16dp standard) for cohesive UI
/// - Elevated surfaces use tonal elevation instead of shadows
class AppTheme {
  AppTheme._(); // Private constructor to prevent instantiation

  // ==========================================================================
  // LIGHT THEME
  // ==========================================================================

  /// Light mode theme configuration.
  ///
  /// Uses energetic coral primary color with Material 3 color harmonization.
  /// Optimized for readability and meets WCAG 2.1 AA accessibility standards.
  static ThemeData get lightTheme {
    final colorScheme = AppColorScheme.light;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: AppTextStyles.textTheme,

      // Scaffold background
      scaffoldBackgroundColor: AppColors.surfaceLight,

      // Divider theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // App bar theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextStyles.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        color: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        margin: const EdgeInsets.all(0),
      ),

      // Filled button theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.buttonHeightSm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacingLg,
            vertical: AppSizes.spacingMd,
          ),
          textStyle: AppTextStyles.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.buttonHeightSm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacingLg,
            vertical: AppSizes.spacingMd,
          ),
          side: BorderSide(color: colorScheme.outline),
          textStyle: AppTextStyles.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacingMd,
            vertical: AppSizes.spacingSm,
          ),
          textStyle: AppTextStyles.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.buttonHeightSm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacingLg,
            vertical: AppSizes.spacingMd,
          ),
          elevation: 0,
          textStyle: AppTextStyles.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacingMd,
          vertical: AppSizes.spacingMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: AppTextStyles.textTheme.bodyLarge,
        hintStyle: AppTextStyles.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        errorStyle: AppTextStyles.textTheme.bodySmall?.copyWith(
          color: colorScheme.error,
        ),
      ),

      // Checkbox theme
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
      ),

      // Radio theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        selectedColor: colorScheme.secondaryContainer,
        disabledColor: colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacingMd,
          vertical: AppSizes.spacingSm,
        ),
      ),

      // Bottom navigation bar theme
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTextStyles.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          );
        }),
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: AppTextStyles.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        titleTextStyle: AppTextStyles.textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
        ),
        contentTextStyle: AppTextStyles.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),

      // Bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 3,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusLg),
          ),
        ),
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),

      // Progress indicator theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),

      // Icon theme
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: AppSizes.iconMd,
      ),
    );
  }

  // ==========================================================================
  // DARK THEME
  // ==========================================================================

  /// Dark mode theme configuration.
  ///
  /// Uses slightly lighter primary color for better visibility on dark backgrounds.
  /// Maintains brand identity while optimizing for low-light conditions.
  static ThemeData get darkTheme {
    final colorScheme = AppColorScheme.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: AppTextStyles.textTheme,

      // Scaffold background
      scaffoldBackgroundColor: AppColors.surfaceDark,

      // Divider theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // App bar theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextStyles.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        color: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        margin: const EdgeInsets.all(0),
      ),

      // Filled button theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.buttonHeightSm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacingLg,
            vertical: AppSizes.spacingMd,
          ),
          textStyle: AppTextStyles.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.buttonHeightSm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacingLg,
            vertical: AppSizes.spacingMd,
          ),
          side: BorderSide(color: colorScheme.outline),
          textStyle: AppTextStyles.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacingMd,
            vertical: AppSizes.spacingSm,
          ),
          textStyle: AppTextStyles.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.buttonHeightSm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacingLg,
            vertical: AppSizes.spacingMd,
          ),
          elevation: 0,
          textStyle: AppTextStyles.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacingMd,
          vertical: AppSizes.spacingMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: AppTextStyles.textTheme.bodyLarge,
        hintStyle: AppTextStyles.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        errorStyle: AppTextStyles.textTheme.bodySmall?.copyWith(
          color: colorScheme.error,
        ),
      ),

      // Checkbox theme
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
      ),

      // Radio theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.secondaryContainer,
        disabledColor: colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        labelStyle: WidgetStateTextStyle.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.textTheme.labelLarge!.copyWith(
              color: colorScheme.onSecondaryContainer,
            );
          }
          return AppTextStyles.textTheme.labelLarge!.copyWith(
            color: colorScheme.onSurface,
          );
        }),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacingMd,
          vertical: AppSizes.spacingSm,
        ),
      ),

      // Bottom navigation bar theme
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTextStyles.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          );
        }),
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: AppTextStyles.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        titleTextStyle: AppTextStyles.textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
        ),
        contentTextStyle: AppTextStyles.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),

      // Bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 3,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusLg),
          ),
        ),
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),

      // Progress indicator theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),

      // Icon theme
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: AppSizes.iconMd,
      ),
    );
  }
}
