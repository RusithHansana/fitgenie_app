import 'package:intl/intl.dart';

/// DateTime extension methods for formatting, comparison, and date manipulation.
///
/// This extension provides convenient methods for common date operations used
/// throughout FitGenie, including display formatting, date comparisons, and
/// Firestore date key generation.
///
/// Usage:
/// ```dart
/// final today = DateTime.now();
/// print(today.displayDate);        // "Monday, January 5"
/// print(today.shortDate);          // "Jan 5"
/// print(today.isToday);            // true
/// print(today.toIso8601DateOnly);  // "2026-01-05"
/// ```
///
/// Date formats follow the UX specification for consistency across the app.
/// ISO 8601 date-only format is used for Firestore document IDs.
extension DateTimeExtensions on DateTime {
  // ==========================================================================
  // DISPLAY FORMATTING
  // ==========================================================================

  /// Returns a formatted date string in "EEEE, MMMM d" format.
  ///
  /// Example: "Monday, January 5"
  ///
  /// Used for:
  /// - Dashboard day headers
  /// - Plan detail screens
  /// - Date pickers
  String get displayDate => DateFormat('EEEE, MMMM d').format(this);

  /// Returns a formatted date string in "MMM d" format.
  ///
  /// Example: "Jan 5"
  ///
  /// Used for:
  /// - Compact date displays
  /// - List items
  /// - Date chips
  String get shortDate => DateFormat('MMM d').format(this);

  /// Returns a formatted date string in "MMMM d, yyyy" format.
  ///
  /// Example: "January 5, 2026"
  ///
  /// Used for:
  /// - Full date displays
  /// - Historical data
  /// - Reports
  String get fullDate => DateFormat('MMMM d, yyyy').format(this);

  /// Returns the day of week name.
  ///
  /// Example: "Monday"
  ///
  /// Used for:
  /// - Weekly plan navigation
  /// - Day selection
  String get dayName => DateFormat('EEEE').format(this);

  /// Returns the abbreviated day of week name.
  ///
  /// Example: "Mon"
  ///
  /// Used for:
  /// - Compact weekly views
  /// - Calendar grids
  String get shortDayName => DateFormat('EEE').format(this);

  /// Returns the month name.
  ///
  /// Example: "January"
  String get monthName => DateFormat('MMMM').format(this);

  /// Returns the abbreviated month name.
  ///
  /// Example: "Jan"
  String get shortMonthName => DateFormat('MMM').format(this);

  // ==========================================================================
  // FIRESTORE FORMATTING
  // ==========================================================================

  /// Returns ISO 8601 date-only string in "yyyy-MM-dd" format.
  ///
  /// Example: "2026-01-05"
  ///
  /// This format is used for Firestore document IDs in the completions
  /// collection, ensuring lexicographical sorting and consistent key format.
  ///
  /// Critical: This format must match exactly across all date-based
  /// Firestore operations to ensure proper document retrieval.
  String get toIso8601DateOnly {
    final year = this.year.toString().padLeft(4, '0');
    final month = this.month.toString().padLeft(2, '0');
    final day = this.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  // ==========================================================================
  // DATE COMPARISON
  // ==========================================================================

  /// Returns true if this date represents today.
  ///
  /// Compares only the date portion, ignoring time.
  ///
  /// Example:
  /// ```dart
  /// final now = DateTime.now();
  /// print(now.isToday); // true
  /// ```
  bool get isToday {
    final now = DateTime.now();
    return isSameDay(now);
  }

  /// Returns true if this date represents yesterday.
  ///
  /// Compares only the date portion, ignoring time.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(yesterday);
  }

  /// Returns true if this date represents tomorrow.
  ///
  /// Compares only the date portion, ignoring time.
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return isSameDay(tomorrow);
  }

  /// Returns true if this date is the same day as [other].
  ///
  /// Compares only the date portion (year, month, day), ignoring time.
  ///
  /// Example:
  /// ```dart
  /// final date1 = DateTime(2026, 1, 5, 10, 30);
  /// final date2 = DateTime(2026, 1, 5, 15, 45);
  /// print(date1.isSameDay(date2)); // true
  /// ```
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Returns true if this date is in the same week as [other].
  ///
  /// Week starts on Monday. Two dates are in the same week if they fall
  /// between the same Monday-Sunday period.
  bool isSameWeek(DateTime other) {
    final thisWeekStart = startOfWeek;
    final otherWeekStart = other.startOfWeek;
    return thisWeekStart.isSameDay(otherWeekStart);
  }

  /// Returns true if this date is in the same month as [other].
  bool isSameMonth(DateTime other) {
    return year == other.year && month == other.month;
  }

  /// Returns true if this date is in the same year as [other].
  bool isSameYear(DateTime other) {
    return year == other.year;
  }

  /// Returns true if this date is in the past.
  ///
  /// Compares only the date portion, so today returns false.
  bool get isPast {
    final today = DateTime.now().startOfDay;
    final thisDate = startOfDay;
    return thisDate.isBefore(today);
  }

  /// Returns true if this date is in the future.
  ///
  /// Compares only the date portion, so today returns false.
  bool get isFuture {
    final today = DateTime.now().startOfDay;
    final thisDate = startOfDay;
    return thisDate.isAfter(today);
  }

  // ==========================================================================
  // DATE MANIPULATION
  // ==========================================================================

  /// Returns a DateTime representing the start of this day (midnight).
  ///
  /// Example:
  /// ```dart
  /// final now = DateTime(2026, 1, 5, 14, 30, 45);
  /// final midnight = now.startOfDay; // 2026-01-05 00:00:00
  /// ```
  ///
  /// Used for date comparisons and Firestore queries where time should be ignored.
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  /// Returns a DateTime representing the end of this day (23:59:59.999).
  ///
  /// Example:
  /// ```dart
  /// final now = DateTime(2026, 1, 5, 14, 30);
  /// final endOfDay = now.endOfDay; // 2026-01-05 23:59:59.999
  /// ```
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59, 999);
  }

  /// Returns a DateTime representing the start of the week (Monday at midnight).
  ///
  /// Week starts on Monday following ISO 8601 standard.
  DateTime get startOfWeek {
    final daysFromMonday = (weekday - DateTime.monday) % 7;
    return subtract(Duration(days: daysFromMonday)).startOfDay;
  }

  /// Returns a DateTime representing the end of the week (Sunday at 23:59:59.999).
  DateTime get endOfWeek {
    final daysToSunday = (DateTime.sunday - weekday) % 7;
    return add(Duration(days: daysToSunday)).endOfDay;
  }

  /// Returns a DateTime representing the start of the month (1st at midnight).
  DateTime get startOfMonth {
    return DateTime(year, month, 1);
  }

  /// Returns a DateTime representing the end of the month (last day at 23:59:59.999).
  DateTime get endOfMonth {
    final nextMonth = month == 12
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    return nextMonth.subtract(const Duration(microseconds: 1));
  }

  /// Returns a new DateTime with the specified number of days added.
  ///
  /// Preserves the time portion.
  ///
  /// Example:
  /// ```dart
  /// final today = DateTime.now();
  /// final nextWeek = today.addDays(7);
  /// ```
  DateTime addDays(int days) {
    return add(Duration(days: days));
  }

  /// Returns a new DateTime with the specified number of days subtracted.
  ///
  /// Preserves the time portion.
  DateTime subtractDays(int days) {
    return subtract(Duration(days: days));
  }

  // ==========================================================================
  // RELATIVE DATE FORMATTING
  // ==========================================================================

  /// Returns a relative date string ("Today", "Yesterday", "Tomorrow", or formatted date).
  ///
  /// Example:
  /// - Today's date: "Today"
  /// - Yesterday's date: "Yesterday"
  /// - Tomorrow's date: "Tomorrow"
  /// - Other dates: "Jan 5" (shortDate format)
  ///
  /// Used for dashboard date headers and plan navigation.
  String get relativeDateString {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    if (isTomorrow) return 'Tomorrow';
    return shortDate;
  }

  /// Returns the number of days between this date and [other].
  ///
  /// Positive if [other] is in the future, negative if in the past.
  /// Compares only the date portion, ignoring time.
  int daysBetween(DateTime other) {
    final thisDate = startOfDay;
    final otherDate = other.startOfDay;
    final difference = otherDate.difference(thisDate);
    return difference.inDays;
  }

  /// Returns the number of days since this date.
  ///
  /// Negative if the date is in the future.
  int get daysSince {
    return DateTime.now().startOfDay.daysBetween(this);
  }

  /// Returns the number of days until this date.
  ///
  /// Negative if the date is in the past.
  int get daysUntil {
    return daysBetween(DateTime.now().startOfDay);
  }
}
