import 'package:flutter/material.dart';

/// BuildContext extension methods for convenient access to theme, media query,
/// and navigation APIs.
///
/// This extension reduces boilerplate throughout the presentation layer by
/// providing shorthand accessors for commonly used BuildContext-based APIs.
///
/// Usage:
/// ```dart
/// // Instead of: Theme.of(context).colorScheme.primary
/// final primaryColor = context.colorScheme.primary;
///
/// // Instead of: MediaQuery.of(context).size.width
/// final width = context.screenWidth;
///
/// // Instead of: ScaffoldMessenger.of(context).showSnackBar(...)
/// context.showSnackBar('Success!');
/// ```
///
/// All methods are safe to use within widget build methods and provide
/// type-safe access to the underlying APIs.
extension BuildContextExtensions on BuildContext {
  // ==========================================================================
  // THEME ACCESS
  // ==========================================================================

  /// Returns the current [ThemeData] for this context.
  ///
  /// Equivalent to `Theme.of(context)`.
  ThemeData get theme => Theme.of(this);

  /// Returns the current [ColorScheme] for this context.
  ///
  /// Equivalent to `Theme.of(context).colorScheme`.
  ColorScheme get colorScheme => theme.colorScheme;

  /// Returns the current [TextTheme] for this context.
  ///
  /// Equivalent to `Theme.of(context).textTheme`.
  TextTheme get textTheme => theme.textTheme;

  // ==========================================================================
  // MEDIA QUERY ACCESS
  // ==========================================================================

  /// Returns the full [MediaQueryData] for this context.
  ///
  /// Equivalent to `MediaQuery.of(context)`.
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Returns the screen width in logical pixels.
  ///
  /// Equivalent to `MediaQuery.of(context).size.width`.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Returns the screen height in logical pixels.
  ///
  /// Equivalent to `MediaQuery.of(context).size.height`.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Returns the screen size.
  ///
  /// Equivalent to `MediaQuery.of(context).size`.
  Size get screenSize => MediaQuery.sizeOf(this);

  /// Returns the top padding (safe area inset), typically the status bar height.
  double get topPadding => MediaQuery.paddingOf(this).top;

  /// Returns the bottom padding (safe area inset), typically for home indicator.
  double get bottomPadding => MediaQuery.paddingOf(this).bottom;

  /// Returns whether the device is in landscape orientation.
  bool get isLandscape => mediaQuery.orientation == Orientation.landscape;

  /// Returns whether the device is in portrait orientation.
  bool get isPortrait => mediaQuery.orientation == Orientation.portrait;

  /// Returns whether the screen width is considered tablet size (≥ 600dp).
  ///
  /// Uses Material Design breakpoint specification:
  /// - Phone: < 600dp
  /// - Tablet: ≥ 600dp
  /// - Desktop: ≥ 840dp
  bool get isTablet => screenWidth >= 600;

  /// Returns whether the screen width is considered desktop size (≥ 840dp).
  bool get isDesktop => screenWidth >= 840;

  // ==========================================================================
  // NAVIGATION ACCESS
  // ==========================================================================

  /// Returns the [NavigatorState] for this context.
  ///
  /// Equivalent to `Navigator.of(context)`.
  NavigatorState get navigator => Navigator.of(this);

  /// Pops the current route off the navigator.
  ///
  /// Equivalent to `Navigator.of(context).pop()`.
  void pop<T>([T? result]) => Navigator.of(this).pop(result);

  /// Returns whether the navigator can pop the current route.
  ///
  /// Equivalent to `Navigator.of(context).canPop()`.
  bool get canPop => Navigator.of(this).canPop();

  // ==========================================================================
  // SCAFFOLD MESSENGER ACCESS
  // ==========================================================================

  /// Displays a [SnackBar] with the given message.
  ///
  /// Provides a convenient way to show feedback messages to users without
  /// needing to access ScaffoldMessenger directly.
  ///
  /// Example:
  /// ```dart
  /// context.showSnackBar('Plan generated successfully!');
  /// ```
  ///
  /// For more complex snackbars, use [ScaffoldMessenger.of(context)] directly.
  void showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Displays an error [SnackBar] with the given message.
  ///
  /// Uses error color scheme for visual distinction.
  ///
  /// Example:
  /// ```dart
  /// context.showErrorSnackBar('Failed to load plan');
  /// ```
  void showErrorSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Displays a success [SnackBar] with the given message.
  ///
  /// Uses a green/success color for visual distinction.
  ///
  /// Example:
  /// ```dart
  /// context.showSuccessSnackBar('Workout completed!');
  /// ```
  void showSuccessSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: const Color(0xFF22C55E), // Success green
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================================================
  // FOCUS MANAGEMENT
  // ==========================================================================

  /// Unfocuses any currently focused widget, typically hiding the keyboard.
  ///
  /// Equivalent to `FocusScope.of(context).unfocus()`.
  ///
  /// Example:
  /// ```dart
  /// // Dismiss keyboard when tapping outside text fields
  /// GestureDetector(
  ///   onTap: () => context.unfocus(),
  ///   child: child,
  /// )
  /// ```
  void unfocus() {
    FocusScope.of(this).unfocus();
  }

  /// Returns the current [FocusNode] for this context.
  FocusNode? get focusNode => FocusScope.of(this).focusedChild;
}
