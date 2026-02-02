import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fitgenie_app/core/config/environment.dart';
import 'package:fitgenie_app/core/theme/app_theme.dart';
import 'package:fitgenie_app/core/utils/rate_limiter.dart';
import 'package:fitgenie_app/firebase_options.dart';
import 'package:fitgenie_app/routing/app_router.dart';
import 'package:fitgenie_app/shared/services/hive_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Application entry point handling initialization and app widget setup.
///
/// Initialization sequence (order is critical):
/// 1. WidgetsFlutterBinding - Initialize Flutter framework
/// 2. Environment configuration - Load .env file for API keys
/// 3. Firebase - Initialize with platform-specific options
/// 4. Firebase App Check - Security layer for API calls
/// 5. Hive - Local storage initialization
/// 6. System UI - Configure status bar and navigation bar
/// 7. runApp - Start the Flutter application wrapped in ProviderScope
///
/// The ProviderScope wraps the entire app to enable Riverpod state management
/// throughout the widget tree.
void main() async {
  // Ensure Flutter framework is initialized before any async operations
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment configuration
  // Uses .env.development for debug builds, .env.production for release
  try {
    await EnvironmentConfig.loadFromBuildMode();
  } catch (e) {
    // Log error but continue - app can function without environment variables
    // in development mode. Production builds should fail if env is missing.
    debugPrint('Failed to load environment configuration: $e');
  }

  // Initialize Firebase with platform-specific configuration
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Activate Firebase App Check for security
  // Uses debug providers in development, production tokens in release
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  // Initialize Hive for local storage
  // Opens all required boxes for offline-first functionality
  await HiveService.initialize();

  // Initialize rate limiter for API request management
  // Loads persisted daily request counts from Hive
  await RateLimiter().initialize();

  // Configure system UI overlay style
  // Makes status bar transparent with dark icons for light theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Set preferred orientations (portrait only for MVP)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Run app wrapped in ProviderScope for Riverpod
  runApp(const ProviderScope(child: FitGenieApp()));
}

/// Root application widget for FitGenie.
///
/// This ConsumerWidget sets up the MaterialApp.router with:
/// - Go router configuration from [appRouterProvider]
/// - Light and dark themes from [AppTheme]
/// - System theme mode for automatic switching
/// - App title and basic Material 3 configuration
///
/// The router handles all navigation including authentication guards,
/// onboarding flow, and main app screens. It automatically redirects
/// based on auth state and onboarding completion status.
class FitGenieApp extends ConsumerWidget {
  const FitGenieApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the router provider to get GoRouter instance
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      // App identification
      title: 'FitGenie',

      // Routing configuration
      routerConfig: router,

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Follows system preference
      // Remove debug banner in release mode
      debugShowCheckedModeBanner: false,

      // Material 3 design language
      // Already enabled in AppTheme, but explicit here for clarity
    );
  }
}
