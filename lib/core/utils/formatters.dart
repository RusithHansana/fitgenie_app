/// Data formatting utilities for consistent display throughout the app.
///
/// This class provides static methods for formatting numbers, units, durations,
/// and other data types for user-facing display. All formats follow the UX
/// specification to ensure consistency.
///
/// Usage:
/// ```dart
/// final weightText = Formatters.weight(75, 'kg');      // "75 kg"
/// final heightText = Formatters.height(180, 'cm');     // "180 cm"
/// final durationText = Formatters.duration(45);        // "45 mins"
/// final streakText = Formatters.streak(12);            // "🔥 12 days"
/// ```
///
/// All formatters respect user preferences (unit systems) and provide
/// graceful handling of edge cases (zero values, singular/plural).
class Formatters {
  Formatters._(); // Private constructor to prevent instantiation

  // ==========================================================================
  // WEIGHT FORMATTING
  // ==========================================================================

  /// Formats weight with appropriate unit.
  ///
  /// Supports both metric (kg) and imperial (lbs) units.
  ///
  /// Example:
  /// ```dart
  /// Formatters.weight(75, 'kg');      // "75 kg"
  /// Formatters.weight(75.5, 'kg');    // "75.5 kg"
  /// Formatters.weight(165, 'lbs');    // "165 lbs"
  /// Formatters.weight(165.25, 'lbs'); // "165.3 lbs" (rounded to 1 decimal)
  /// ```
  static String weight(num value, String unit) {
    // Remove unnecessary decimals for whole numbers
    final formattedValue = value == value.toInt()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);

    return '$formattedValue $unit';
  }

  // ==========================================================================
  // HEIGHT FORMATTING
  // ==========================================================================

  /// Formats height with appropriate unit.
  ///
  /// Supports metric (cm) and imperial (ft/in) units.
  /// For imperial, converts total inches to feet and inches format.
  ///
  /// Example:
  /// ```dart
  /// Formatters.height(180, 'cm');     // "180 cm"
  /// Formatters.height(71, 'ft-in');   // "5'11"" (71 inches)
  /// Formatters.height(72, 'ft-in');   // "6'0""
  /// ```
  static String height(num value, String unit) {
    if (unit == 'ft-in') {
      // Convert total inches to feet and inches
      final totalInches = value.toInt();
      final feet = totalInches ~/ 12;
      final inches = totalInches % 12;
      return "$feet'$inches\"";
    }

    // Metric (cm) - typically whole numbers
    return '${value.toInt()} $unit';
  }

  // ==========================================================================
  // DURATION FORMATTING
  // ==========================================================================

  /// Formats duration in minutes to human-readable string.
  ///
  /// Handles:
  /// - Minutes only (< 60 minutes)
  /// - Hours and minutes (≥ 60 minutes)
  /// - Singular/plural forms
  ///
  /// Example:
  /// ```dart
  /// Formatters.duration(30);    // "30 mins"
  /// Formatters.duration(1);     // "1 min"
  /// Formatters.duration(60);    // "1 hour"
  /// Formatters.duration(90);    // "1h 30m"
  /// Formatters.duration(125);   // "2h 5m"
  /// ```
  static String duration(int minutes) {
    if (minutes < 60) {
      return minutes == 1 ? '1 min' : '$minutes mins';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (remainingMinutes == 0) {
      return hours == 1 ? '1 hour' : '$hours hours';
    }

    return '${hours}h ${remainingMinutes}m';
  }

  /// Formats duration in seconds to MM:SS format.
  ///
  /// Used for workout timers and stopwatch displays.
  ///
  /// Example:
  /// ```dart
  /// Formatters.durationTimer(90);    // "01:30"
  /// Formatters.durationTimer(125);   // "02:05"
  /// Formatters.durationTimer(3665);  // "61:05"
  /// ```
  static String durationTimer(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // ==========================================================================
  // STREAK FORMATTING
  // ==========================================================================

  /// Formats streak count with fire emoji.
  ///
  /// Includes appropriate singular/plural form.
  ///
  /// Example:
  /// ```dart
  /// Formatters.streak(1);     // "🔥 1 day"
  /// Formatters.streak(7);     // "🔥 7 days"
  /// Formatters.streak(42);    // "🔥 42 days"
  /// Formatters.streak(0);     // "Start your streak!"
  /// ```
  static String streak(int count) {
    if (count == 0) {
      return 'Start your streak!';
    }

    return count == 1 ? '🔥 1 day' : '🔥 $count days';
  }

  /// Formats streak count as just the number with emoji (compact form).
  ///
  /// Used in space-constrained UI elements.
  ///
  /// Example:
  /// ```dart
  /// Formatters.streakCompact(7);    // "🔥 7"
  /// Formatters.streakCompact(42);   // "🔥 42"
  /// ```
  static String streakCompact(int count) {
    return '🔥 $count';
  }

  // ==========================================================================
  // PERCENTAGE FORMATTING
  // ==========================================================================

  /// Formats a decimal value as a percentage.
  ///
  /// Example:
  /// ```dart
  /// Formatters.percentage(0.75);      // "75%"
  /// Formatters.percentage(0.8333);    // "83%"
  /// Formatters.percentage(1.0);       // "100%"
  /// Formatters.percentage(0.5, 1);    // "50.0%"
  /// ```
  static String percentage(double value, {int decimals = 0}) {
    final percent = value * 100;
    return '${percent.toStringAsFixed(decimals)}%';
  }

  // ==========================================================================
  // CALORIE FORMATTING
  // ==========================================================================

  /// Formats calorie count.
  ///
  /// Example:
  /// ```dart
  /// Formatters.calories(450);      // "450 cal"
  /// Formatters.calories(1200);     // "1,200 cal"
  /// Formatters.calories(2500);     // "2,500 cal"
  /// ```
  static String calories(int value) {
    return '${_formatNumberWithCommas(value)} cal';
  }

  /// Formats calorie count in compact form (kcal).
  ///
  /// Example:
  /// ```dart
  /// Formatters.caloriesCompact(450);    // "450 kcal"
  /// Formatters.caloriesCompact(1200);   // "1.2k kcal"
  /// Formatters.caloriesCompact(2500);   // "2.5k kcal"
  /// ```
  static String caloriesCompact(int value) {
    if (value < 1000) {
      return '$value kcal';
    }

    final kValue = value / 1000;
    return '${kValue.toStringAsFixed(1)}k kcal';
  }

  // ==========================================================================
  // MACRO FORMATTING
  // ==========================================================================

  /// Formats macronutrient amount in grams.
  ///
  /// Example:
  /// ```dart
  /// Formatters.macros(45, 'protein');    // "45g protein"
  /// Formatters.macros(60, 'carbs');      // "60g carbs"
  /// Formatters.macros(20, 'fat');        // "20g fat"
  /// ```
  static String macros(num value, String type) {
    final formatted = value == value.toInt()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return '${formatted}g $type';
  }

  // ==========================================================================
  // EXERCISE FORMATTING
  // ==========================================================================

  /// Formats sets and reps for exercise display.
  ///
  /// Example:
  /// ```dart
  /// Formatters.setsReps(3, 12);      // "3 sets × 12 reps"
  /// Formatters.setsReps(4, 10);      // "4 sets × 10 reps"
  /// Formatters.setsReps(1, 20);      // "1 set × 20 reps"
  /// ```
  static String setsReps(int sets, int reps) {
    final setWord = sets == 1 ? 'set' : 'sets';
    final repWord = reps == 1 ? 'rep' : 'reps';
    return '$sets $setWord × $reps $repWord';
  }

  /// Formats sets and reps in compact form.
  ///
  /// Example:
  /// ```dart
  /// Formatters.setsRepsCompact(3, 12);   // "3×12"
  /// Formatters.setsRepsCompact(4, 10);   // "4×10"
  /// ```
  static String setsRepsCompact(int sets, int reps) {
    return '$sets×$reps';
  }

  // ==========================================================================
  // COUNT FORMATTING
  // ==========================================================================

  /// Formats a count with singular/plural noun.
  ///
  /// Example:
  /// ```dart
  /// Formatters.count(1, 'workout');      // "1 workout"
  /// Formatters.count(5, 'workout');      // "5 workouts"
  /// Formatters.count(1, 'exercise');     // "1 exercise"
  /// Formatters.count(3, 'exercise');     // "3 exercises"
  /// ```
  static String count(int value, String noun, {String? pluralForm}) {
    if (value == 1) {
      return '1 $noun';
    }

    final plural = pluralForm ?? '${noun}s';
    return '$value $plural';
  }

  // ==========================================================================
  // COMPLETION RATE FORMATTING
  // ==========================================================================

  /// Formats completion ratio as "X/Y" format.
  ///
  /// Example:
  /// ```dart
  /// Formatters.completionRatio(3, 4);    // "3/4"
  /// Formatters.completionRatio(7, 7);    // "7/7"
  /// ```
  static String completionRatio(int completed, int total) {
    return '$completed/$total';
  }

  /// Formats completion rate with percentage.
  ///
  /// Example:
  /// ```dart
  /// Formatters.completionRate(3, 4);     // "3/4 (75%)"
  /// Formatters.completionRate(7, 7);     // "7/7 (100%)"
  /// ```
  static String completionRate(int completed, int total) {
    if (total == 0) return '0/0 (0%)';

    final percent = (completed / total * 100).round();
    return '$completed/$total ($percent%)';
  }

  // ==========================================================================
  // COMPACT NUMBER FORMATTING
  // ==========================================================================

  /// Formats large numbers in compact form (K, M notation).
  ///
  /// Example:
  /// ```dart
  /// Formatters.compactNumber(999);       // "999"
  /// Formatters.compactNumber(1500);      // "1.5K"
  /// Formatters.compactNumber(1000000);   // "1M"
  /// Formatters.compactNumber(2500000);   // "2.5M"
  /// ```
  static String compactNumber(int value) {
    if (value < 1000) {
      return value.toString();
    }

    if (value < 1000000) {
      final kValue = value / 1000;
      return kValue == kValue.toInt()
          ? '${kValue.toInt()}K'
          : '${kValue.toStringAsFixed(1)}K';
    }

    final mValue = value / 1000000;
    return mValue == mValue.toInt()
        ? '${mValue.toInt()}M'
        : '${mValue.toStringAsFixed(1)}M';
  }

  // ==========================================================================
  // ORDINAL FORMATTING
  // ==========================================================================

  /// Formats number with ordinal suffix (1st, 2nd, 3rd, etc.).
  ///
  /// Example:
  /// ```dart
  /// Formatters.ordinal(1);     // "1st"
  /// Formatters.ordinal(2);     // "2nd"
  /// Formatters.ordinal(3);     // "3rd"
  /// Formatters.ordinal(4);     // "4th"
  /// Formatters.ordinal(21);    // "21st"
  /// ```
  static String ordinal(int value) {
    if (value % 100 >= 11 && value % 100 <= 13) {
      return '${value}th';
    }

    switch (value % 10) {
      case 1:
        return '${value}st';
      case 2:
        return '${value}nd';
      case 3:
        return '${value}rd';
      default:
        return '${value}th';
    }
  }

  // ==========================================================================
  // PRIVATE HELPERS
  // ==========================================================================

  /// Formats number with comma separators for thousands.
  ///
  /// Example: 1234567 → "1,234,567"
  static String _formatNumberWithCommas(int value) {
    final str = value.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }

    return buffer.toString();
  }

  // ==========================================================================
  // LIST FORMATTING
  // ==========================================================================

  /// Formats a list of items as comma-separated string with "and" for last item.
  ///
  /// Example:
  /// ```dart
  /// Formatters.list(['Apple']);                    // "Apple"
  /// Formatters.list(['Apple', 'Banana']);          // "Apple and Banana"
  /// Formatters.list(['A', 'B', 'C']);              // "A, B and C"
  /// Formatters.list(['A', 'B', 'C', 'D']);         // "A, B, C and D"
  /// ```
  static String list(List<String> items) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items[0];
    if (items.length == 2) return '${items[0]} and ${items[1]}';

    final allButLast = items.sublist(0, items.length - 1).join(', ');
    return '$allButLast and ${items.last}';
  }

  /// Formats a list of items as bullet points.
  ///
  /// Example:
  /// ```dart
  /// Formatters.bulletList(['Item 1', 'Item 2']);
  /// // Returns:
  /// // • Item 1
  /// // • Item 2
  /// ```
  static String bulletList(List<String> items) {
    return items.map((item) => '• $item').join('\n');
  }
}
