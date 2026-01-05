/// String extension methods for validation, formatting, and manipulation.
///
/// This extension provides convenient methods for common string operations used
/// throughout FitGenie, including email validation, text formatting, and
/// string transformations.
///
/// Usage:
/// ```dart
/// final email = 'user@example.com';
/// print(email.isValidEmail);  // true
///
/// final text = '  hello  ';
/// print(text.isNotBlank);     // true
///
/// final name = 'john doe';
/// print(name.capitalize);     // "John doe"
/// ```
extension StringExtensions on String {
  // ==========================================================================
  // VALIDATION
  // ==========================================================================

  /// Returns true if this string is a valid email address.
  ///
  /// Uses a simplified RFC 5322 email validation pattern that covers most
  /// common email formats. Does not validate all edge cases but is sufficient
  /// for practical use.
  ///
  /// Example:
  /// ```dart
  /// 'user@example.com'.isValidEmail;     // true
  /// 'invalid.email'.isValidEmail;        // false
  /// 'user@domain'.isValidEmail;          // false
  /// ```
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Returns true if this string is not empty after trimming whitespace.
  ///
  /// Example:
  /// ```dart
  /// '  hello  '.isNotBlank;   // true
  /// '   '.isNotBlank;          // false
  /// ''.isNotBlank;             // false
  /// ```
  ///
  /// Used for form validation to ensure users provide actual content,
  /// not just whitespace.
  bool get isNotBlank => trim().isNotEmpty;

  /// Returns true if this string is empty or contains only whitespace.
  ///
  /// Example:
  /// ```dart
  /// ''.isBlank;        // true
  /// '   '.isBlank;     // true
  /// 'text'.isBlank;    // false
  /// ```
  bool get isBlank => trim().isEmpty;

  /// Returns true if this string contains only numeric characters.
  ///
  /// Example:
  /// ```dart
  /// '123'.isNumeric;      // true
  /// '12.5'.isNumeric;     // false (contains decimal point)
  /// 'abc'.isNumeric;      // false
  /// ```
  bool get isNumeric {
    return RegExp(r'^[0-9]+$').hasMatch(this);
  }

  /// Returns true if this string is a valid numeric value (integer or decimal).
  ///
  /// Example:
  /// ```dart
  /// '123'.isValidNumber;      // true
  /// '12.5'.isValidNumber;     // true
  /// '-45.67'.isValidNumber;   // true
  /// 'abc'.isValidNumber;      // false
  /// ```
  bool get isValidNumber {
    return double.tryParse(this) != null;
  }

  /// Returns true if this string contains only alphabetic characters.
  ///
  /// Example:
  /// ```dart
  /// 'Hello'.isAlpha;      // true
  /// 'Hello123'.isAlpha;   // false
  /// ```
  bool get isAlpha {
    return RegExp(r'^[a-zA-Z]+$').hasMatch(this);
  }

  /// Returns true if this string contains only alphanumeric characters.
  ///
  /// Example:
  /// ```dart
  /// 'Hello123'.isAlphaNumeric;   // true
  /// 'Hello 123'.isAlphaNumeric;  // false (contains space)
  /// ```
  bool get isAlphaNumeric {
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(this);
  }

  // ==========================================================================
  // FORMATTING
  // ==========================================================================

  /// Returns this string with the first character capitalized.
  ///
  /// Example:
  /// ```dart
  /// 'hello'.capitalize;           // "Hello"
  /// 'hello world'.capitalize;     // "Hello world"
  /// ''.capitalize;                // ""
  /// ```
  ///
  /// Used for:
  /// - Display names
  /// - Form field labels
  /// - Sentence formatting
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Returns this string with the first character of each word capitalized.
  ///
  /// Example:
  /// ```dart
  /// 'hello world'.capitalizeWords;  // "Hello World"
  /// 'fitness plan'.capitalizeWords; // "Fitness Plan"
  /// ```
  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Converts this camelCase or PascalCase string to snake_case.
  ///
  /// Example:
  /// ```dart
  /// 'userName'.toSnakeCase;         // "user_name"
  /// 'UserName'.toSnakeCase;         // "user_name"
  /// 'userId'.toSnakeCase;           // "user_id"
  /// ```
  ///
  /// Used for:
  /// - Converting Dart property names to API field names
  /// - Database column naming
  String get toSnakeCase {
    return replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    ).replaceFirst(RegExp(r'^_'), '');
  }

  /// Converts this snake_case string to camelCase.
  ///
  /// Example:
  /// ```dart
  /// 'user_name'.toCamelCase;        // "userName"
  /// 'user_id'.toCamelCase;          // "userId"
  /// ```
  String get toCamelCase {
    final parts = split('_');
    if (parts.isEmpty) return this;

    return parts.first + parts.skip(1).map((part) => part.capitalize).join();
  }

  /// Truncates this string to [maxLength] characters and adds an ellipsis if needed.
  ///
  /// Example:
  /// ```dart
  /// 'This is a long text'.truncate(10);      // "This is a..."
  /// 'Short'.truncate(10);                    // "Short"
  /// 'This is a long text'.truncate(10, '…'); // "This is a…"
  /// ```
  ///
  /// Used for:
  /// - Display text in limited space
  /// - List item previews
  /// - Card descriptions
  String truncate(int maxLength, [String ellipsis = '...']) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Removes all whitespace from this string.
  ///
  /// Example:
  /// ```dart
  /// '  hello  world  '.removeWhitespace;  // "helloworld"
  /// ```
  String get removeWhitespace {
    return replaceAll(RegExp(r'\s+'), '');
  }

  /// Removes extra whitespace, leaving single spaces between words.
  ///
  /// Example:
  /// ```dart
  /// '  hello    world  '.collapseWhitespace;  // "hello world"
  /// ```
  String get collapseWhitespace {
    return trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  // ==========================================================================
  // PARSING
  // ==========================================================================

  /// Safely parses this string to an integer.
  ///
  /// Returns null if the string cannot be parsed.
  ///
  /// Example:
  /// ```dart
  /// '123'.toIntOrNull;     // 123
  /// '12.5'.toIntOrNull;    // null
  /// 'abc'.toIntOrNull;     // null
  /// ```
  int? get toIntOrNull => int.tryParse(this);

  /// Safely parses this string to a double.
  ///
  /// Returns null if the string cannot be parsed.
  ///
  /// Example:
  /// ```dart
  /// '123'.toDoubleOrNull;     // 123.0
  /// '12.5'.toDoubleOrNull;    // 12.5
  /// 'abc'.toDoubleOrNull;     // null
  /// ```
  double? get toDoubleOrNull => double.tryParse(this);

  // ==========================================================================
  // STRING QUERIES
  // ==========================================================================

  /// Returns true if this string contains [other], ignoring case.
  ///
  /// Example:
  /// ```dart
  /// 'Hello World'.containsIgnoreCase('hello');  // true
  /// 'Hello World'.containsIgnoreCase('WORLD');  // true
  /// ```
  bool containsIgnoreCase(String other) {
    return toLowerCase().contains(other.toLowerCase());
  }

  /// Returns true if this string equals [other], ignoring case.
  ///
  /// Example:
  /// ```dart
  /// 'Hello'.equalsIgnoreCase('hello');  // true
  /// 'Hello'.equalsIgnoreCase('HELLO');  // true
  /// ```
  bool equalsIgnoreCase(String other) {
    return toLowerCase() == other.toLowerCase();
  }

  /// Returns the number of words in this string.
  ///
  /// Words are defined as sequences of non-whitespace characters.
  ///
  /// Example:
  /// ```dart
  /// 'Hello world'.wordCount;           // 2
  /// '  Hello   world  '.wordCount;     // 2
  /// ''.wordCount;                      // 0
  /// ```
  int get wordCount {
    if (trim().isEmpty) return 0;
    return trim().split(RegExp(r'\s+')).length;
  }

  // ==========================================================================
  // MASKING
  // ==========================================================================

  /// Returns a masked version of this string for sensitive data display.
  ///
  /// Shows only the last [visibleCount] characters, replacing the rest with [mask].
  ///
  /// Example:
  /// ```dart
  /// '1234567890'.mask();              // "******7890"
  /// 'sensitive@email.com'.mask(4);    // "*****************mail.com"
  /// '1234'.mask(2, '#');              // "##34"
  /// ```
  ///
  /// Used for:
  /// - Email display (show last few characters of email)
  /// - Credit card numbers
  /// - Other sensitive data
  String mask([int visibleCount = 4, String mask = '*']) {
    if (length <= visibleCount) return this;
    final visiblePart = substring(length - visibleCount);
    final maskedLength = length - visibleCount;
    return mask * maskedLength + visiblePart;
  }

  // ==========================================================================
  // URL / PATH HELPERS
  // ==========================================================================

  /// Returns true if this string is a valid URL.
  ///
  /// Checks for http:// or https:// protocol.
  ///
  /// Example:
  /// ```dart
  /// 'https://example.com'.isValidUrl;     // true
  /// 'http://example.com'.isValidUrl;      // true
  /// 'example.com'.isValidUrl;             // false
  /// ```
  bool get isValidUrl {
    return RegExp(r'^https?://[^\s]+$').hasMatch(this);
  }

  /// Ensures this string starts with the specified [prefix].
  ///
  /// Returns the original string if it already starts with the prefix.
  ///
  /// Example:
  /// ```dart
  /// 'example.com'.ensurePrefix('https://');  // "https://example.com"
  /// 'https://example.com'.ensurePrefix('https://');  // "https://example.com"
  /// ```
  String ensurePrefix(String prefix) {
    return startsWith(prefix) ? this : prefix + this;
  }

  /// Ensures this string ends with the specified [suffix].
  ///
  /// Returns the original string if it already ends with the suffix.
  ///
  /// Example:
  /// ```dart
  /// 'example.com'.ensureSuffix('/');  // "example.com/"
  /// 'example.com/'.ensureSuffix('/');  // "example.com/"
  /// ```
  String ensureSuffix(String suffix) {
    return endsWith(suffix) ? this : this + suffix;
  }
}
