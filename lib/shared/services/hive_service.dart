import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Centralized Hive service for local storage initialization and box management.
///
/// This service must be initialized once at app startup via [initialize()]
/// before any repository accesses local storage. It manages all Hive boxes
/// and TypeAdapter registrations for the application.
///
/// Usage:
/// ```dart
/// await HiveService.initialize();
/// final userBox = HiveService.userProfileBox;
/// ```
class HiveService {
  // Private constructor to prevent instantiation
  HiveService._();

  // Box name constants
  static const String _userProfileBoxName = 'user_profiles';
  static const String _weeklyPlanBoxName = 'weekly_plans';
  static const String _completionsBoxName = 'completions';
  static const String _syncQueueBoxName = 'sync_queue';

  // Box references (lazy-loaded)
  static Box<Map<dynamic, dynamic>>? _userProfileBox;
  static Box<Map<dynamic, dynamic>>? _weeklyPlanBox;
  static Box<Map<dynamic, dynamic>>? _completionsBox;
  static Box<Map<dynamic, dynamic>>? _syncQueueBox;

  // Initialization flag
  static bool _isInitialized = false;

  /// Initializes Hive with Flutter-specific path configuration and registers
  /// all TypeAdapters for domain models.
  ///
  /// Must be called once at app startup after [WidgetsFlutterBinding.ensureInitialized()].
  ///
  /// Throws [HiveError] if initialization fails.
  /// Throws [StateError] if called multiple times.
  static Future<void> initialize() async {
    if (_isInitialized) {
      throw StateError('HiveService has already been initialized');
    }

    try {
      // Initialize Hive with Flutter-specific directory
      if (Platform.isAndroid || Platform.isIOS) {
        final appDocumentDir = await getApplicationDocumentsDirectory();
        await Hive.initFlutter(appDocumentDir.path);
      } else {
        // For web and desktop platforms
        await Hive.initFlutter();
      }

      // Register TypeAdapters for all domain models
      // Note: TypeAdapter classes are generated via build_runner
      // Format: ModelNameAdapter with sequential typeIds

      // User and auth related adapters (typeIds 0-9)
      if (!Hive.isAdapterRegistered(0)) {
        // UserModel adapter registration will be added when model is generated
        // Hive.registerAdapter(UserModelAdapter());
      }

      // Weekly plan related adapters (typeIds 10-19)
      if (!Hive.isAdapterRegistered(10)) {
        // WeeklyPlanAdapter registration will be added when model is generated
        // Hive.registerAdapter(WeeklyPlanAdapter());
      }

      if (!Hive.isAdapterRegistered(11)) {
        // DailyPlanAdapter registration will be added when model is generated
        // Hive.registerAdapter(DailyPlanAdapter());
      }

      if (!Hive.isAdapterRegistered(12)) {
        // WorkoutAdapter registration will be added when model is generated
        // Hive.registerAdapter(WorkoutAdapter());
      }

      if (!Hive.isAdapterRegistered(13)) {
        // ExerciseAdapter registration will be added when model is generated
        // Hive.registerAdapter(ExerciseAdapter());
      }

      if (!Hive.isAdapterRegistered(14)) {
        // MealPlanAdapter registration will be added when model is generated
        // Hive.registerAdapter(MealPlanAdapter());
      }

      if (!Hive.isAdapterRegistered(15)) {
        // MealAdapter registration will be added when model is generated
        // Hive.registerAdapter(MealAdapter());
      }

      // Completion tracking adapters (typeIds 20-29)
      if (!Hive.isAdapterRegistered(20)) {
        // CompletionAdapter registration will be added when model is generated
        // Hive.registerAdapter(CompletionAdapter());
      }

      // Sync queue adapters (typeIds 30-39)
      if (!Hive.isAdapterRegistered(30)) {
        // SyncQueueItemAdapter registration will be added when model is generated
        // Hive.registerAdapter(SyncQueueItemAdapter());
      }

      // Open all required boxes
      // Using Map<dynamic, dynamic> as generic type for flexibility
      // Individual repositories will handle type casting
      _userProfileBox = await Hive.openBox<Map<dynamic, dynamic>>(
        _userProfileBoxName,
      );

      _weeklyPlanBox = await Hive.openBox<Map<dynamic, dynamic>>(
        _weeklyPlanBoxName,
      );

      _completionsBox = await Hive.openBox<Map<dynamic, dynamic>>(
        _completionsBoxName,
      );

      _syncQueueBox = await Hive.openBox<Map<dynamic, dynamic>>(
        _syncQueueBoxName,
      );

      _isInitialized = true;
    } catch (e) {
      // Wrap any errors in HiveError for consistent error handling
      throw HiveError('Failed to initialize HiveService: $e');
    }
  }

  /// Returns the user profile box for storing cached user data.
  ///
  /// Throws [StateError] if HiveService has not been initialized.
  static Box<Map<dynamic, dynamic>> get userProfileBox {
    _ensureInitialized();
    return _userProfileBox!;
  }

  /// Returns the weekly plan box for storing cached workout and meal plans.
  ///
  /// Throws [StateError] if HiveService has not been initialized.
  static Box<Map<dynamic, dynamic>> get weeklyPlanBox {
    _ensureInitialized();
    return _weeklyPlanBox!;
  }

  /// Returns the completions box for storing workout/meal completion records.
  ///
  /// Throws [StateError] if HiveService has not been initialized.
  static Box<Map<dynamic, dynamic>> get completionsBox {
    _ensureInitialized();
    return _completionsBox!;
  }

  /// Returns the sync queue box for storing pending offline operations.
  ///
  /// Throws [StateError] if HiveService has not been initialized.
  static Box<Map<dynamic, dynamic>> get syncQueueBox {
    _ensureInitialized();
    return _syncQueueBox!;
  }

  /// Verifies that HiveService has been properly initialized.
  ///
  /// Throws [StateError] if [initialize()] has not been called.
  static void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'HiveService has not been initialized. '
        'Call HiveService.initialize() in main() before accessing boxes.',
      );
    }
  }

  /// Closes all open Hive boxes and resets initialization state.
  ///
  /// Should be called during app shutdown or for testing purposes.
  /// After calling this method, [initialize()] must be called again
  /// before accessing any boxes.
  static Future<void> close() async {
    await _userProfileBox?.close();
    await _weeklyPlanBox?.close();
    await _completionsBox?.close();
    await _syncQueueBox?.close();

    _userProfileBox = null;
    _weeklyPlanBox = null;
    _completionsBox = null;
    _syncQueueBox = null;
    _isInitialized = false;
  }

  /// Clears all data from all boxes.
  ///
  /// WARNING: This will delete all locally cached data including:
  /// - User profiles
  /// - Weekly plans
  /// - Completion records
  /// - Pending sync queue items
  ///
  /// Use with caution, typically only for logout or data reset scenarios.
  ///
  /// Throws [StateError] if HiveService has not been initialized.
  static Future<void> clearAllData() async {
    _ensureInitialized();

    await Future.wait([
      _userProfileBox!.clear(),
      _weeklyPlanBox!.clear(),
      _completionsBox!.clear(),
      _syncQueueBox!.clear(),
    ]);
  }

  /// Returns true if HiveService has been initialized and is ready for use.
  static bool get isInitialized => _isInitialized;
}
