import 'package:fitgenie_app/core/constants/app_strings.dart';
import 'package:fitgenie_app/core/extensions/string_extensions.dart';

/// Form field validation functions for use with TextFormField.
///
/// This class provides static validation methods that match Flutter's
/// FormFieldValidator`<String>` signature, returning null for valid input
/// or an error message string for invalid input.
///
/// Usage:
/// ```dart
/// TextFormField(
///   validator: Validators.email,
///   decoration: InputDecoration(labelText: 'Email'),
/// );
///
/// // Combining validators
/// TextFormField(
///   validator: (value) =>
///       Validators.required(value) ?? Validators.email(value),
/// );
/// ```
///
/// All error messages are sourced from AppStrings for consistency and
/// future localization support.
class Validators {
  Validators._(); // Private constructor to prevent instantiation

  // ==========================================================================
  // AUTHENTICATION VALIDATORS
  // ==========================================================================

  /// Validates email address format.
  ///
  /// Returns null if valid, error message if invalid.
  ///
  /// Rules:
  /// - Must not be empty
  /// - Must match standard email format (user@domain.tld)
  ///
  /// Example:
  /// ```dart
  /// Validators.email('user@example.com');  // null (valid)
  /// Validators.email('invalid.email');     // error message
  /// Validators.email('');                  // error message
  /// ```
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.errorRequiredField;
    }

    if (!value.isValidEmail) {
      return AppStrings.errorInvalidEmail;
    }

    return null;
  }

  /// Validates password strength.
  ///
  /// Returns null if valid, error message if invalid.
  ///
  /// Rules:
  /// - Must not be empty
  /// - Minimum 8 characters
  ///
  /// Example:
  /// ```dart
  /// Validators.password('MyPass123');      // null (valid)
  /// Validators.password('short');          // error message
  /// Validators.password('');               // error message
  /// ```
  static String? password(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.errorRequiredField;
    }

    if (value.length < 8) {
      return AppStrings.errorWeakPassword;
    }

    return null;
  }

  /// Validates password confirmation matches original password.
  ///
  /// Returns null if valid, error message if invalid.
  ///
  /// Rules:
  /// - Must not be empty
  /// - Must exactly match the original password
  ///
  /// Example:
  /// ```dart
  /// final validator = Validators.confirmPassword('MyPass123');
  /// validator('MyPass123');  // null (valid)
  /// validator('different');  // error message
  /// ```
  static String? Function(String?) confirmPassword(String originalPassword) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return AppStrings.errorRequiredField;
      }

      if (value != originalPassword) {
        return AppStrings.errorPasswordMismatch;
      }

      return null;
    };
  }

  // ==========================================================================
  // GENERAL VALIDATORS
  // ==========================================================================

  /// Validates that a field is not empty.
  ///
  /// Returns null if valid, error message if invalid.
  ///
  /// Rules:
  /// - Must not be null
  /// - Must not be empty after trimming whitespace
  ///
  /// Example:
  /// ```dart
  /// Validators.required('value');    // null (valid)
  /// Validators.required('   ');      // error message
  /// Validators.required('');         // error message
  /// ```
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null
          ? '$fieldName is required'
          : AppStrings.errorRequiredField;
    }
    return null;
  }

  /// Validates that a field contains only alphabetic characters.
  ///
  /// Returns null if valid, error message if invalid.
  ///
  /// Rules:
  /// - Can be empty (use with required() if needed)
  /// - If not empty, must contain only letters
  ///
  /// Example:
  /// ```dart
  /// Validators.alpha('John');        // null (valid)
  /// Validators.alpha('John123');     // error message
  /// ```
  static String? alpha(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Empty is valid, combine with required() if needed
    }

    if (!value.isAlpha) {
      return AppStrings.errorAlphabeticOnly;
    }

    return null;
  }

  // ==========================================================================
  // NUMERIC VALIDATORS
  // ==========================================================================

  /// Validates age input.
  ///
  /// Returns null if valid, error message if invalid.
  ///
  /// Rules:
  /// - Must not be empty
  /// - Must be a valid number
  /// - Must be between 13 and 100 (inclusive)
  ///
  /// Example:
  /// ```dart
  /// Validators.age('25');      // null (valid)
  /// Validators.age('12');      // error message (too young)
  /// Validators.age('150');     // error message (too old)
  /// Validators.age('abc');     // error message (not a number)
  /// ```
  static String? age(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.errorRequiredField;
    }

    final age = int.tryParse(value);
    if (age == null || age < 13 || age > 100) {
      return AppStrings.errorInvalidAge;
    }

    return null;
  }

  /// Validates weight input.
  ///
  /// Returns null if valid, error message if invalid.
  ///
  /// Rules:
  /// - Must not be empty
  /// - Must be a valid positive number
  /// - Must be greater than 0
  /// - Must be less than 500 (reasonable upper limit in kg)
  ///
  /// Example:
  /// ```dart
  /// Validators.weight('75');       // null (valid)
  /// Validators.weight('0');        // error message
  /// Validators.weight('-10');      // error message
  /// Validators.weight('abc');      // error message
  /// ```
  static String? weight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.errorRequiredField;
    }

    final weight = double.tryParse(value);
    if (weight == null || weight <= 0 || weight > 500) {
      return AppStrings.errorInvalidWeight;
    }

    return null;
  }

  /// Validates height input.
  ///
  /// Returns null if valid, error message if invalid.
  ///
  /// Rules:
  /// - Must not be empty
  /// - Must be a valid positive number
  /// - Must be greater than 0
  /// - Must be less than 300 (reasonable upper limit in cm)
  ///
  /// Example:
  /// ```dart
  /// Validators.height('180');      // null (valid)
  /// Validators.height('0');        // error message
  /// Validators.height('-10');      // error message
  /// Validators.height('abc');      // error message
  /// ```
  static String? height(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.errorRequiredField;
    }

    final height = double.tryParse(value);
    if (height == null || height <= 0 || height > 300) {
      return AppStrings.errorInvalidHeight;
    }

    return null;
  }

  /// Validates that a string is a valid number.
  ///
  /// Returns null if valid, error message if invalid.
  ///
  /// Rules:
  /// - Can be empty (use with required() if needed)
  /// - If not empty, must be a valid number (integer or decimal)
  ///
  /// Example:
  /// ```dart
  /// Validators.numeric('123');       // null (valid)
  /// Validators.numeric('12.5');      // null (valid)
  /// Validators.numeric('abc');       // error message
  /// ```
  static String? numeric(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Empty is valid, combine with required() if needed
    }

    if (!value.isValidNumber) {
      return AppStrings.errorNumericOnly;
    }

    return null;
  }

  /// Validates that a number is within a specified range.
  ///
  /// Returns null if valid, error message if invalid.
  ///
  /// Rules:
  /// - Must be a valid number
  /// - Must be >= min and <= max
  ///
  /// Example:
  /// ```dart
  /// final validator = Validators.range(1, 10);
  /// validator('5');      // null (valid)
  /// validator('0');      // error message
  /// validator('11');     // error message
  /// ```
  static String? Function(String?) range(double min, double max) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return null; // Empty is valid, combine with required() if needed
      }

      final number = double.tryParse(value);
      if (number == null) {
        return AppStrings.errorNumericOnly;
      }

      if (number < min || number > max) {
        return 'Value must be between $min and $max';
      }

      return null;
    };
  }

  // ==========================================================================
  // LENGTH VALIDATORS
  // ==========================================================================

  /// Validates minimum string length.
  ///
  /// Returns null if valid, error message if invalid.
  ///
  /// Example:
  /// ```dart
  /// final validator = Validators.minLength(3);
  /// validator('abcd');     // null (valid)
  /// validator('ab');       // error message
  /// ```
  static String? Function(String?) minLength(int min) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return null; // Empty is valid, combine with required() if needed
      }

      if (value.length < min) {
        return 'Must be at least $min characters';
      }

      return null;
    };
  }

  /// Validates maximum string length.
  ///
  /// Returns null if valid, error message if invalid.
  ///
  /// Example:
  /// ```dart
  /// final validator = Validators.maxLength(10);
  /// validator('short');          // null (valid)
  /// validator('verylongtext');   // error message
  /// ```
  static String? Function(String?) maxLength(int max) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return null; // Empty is valid, combine with required() if needed
      }

      if (value.length > max) {
        return 'Must be at most $max characters';
      }

      return null;
    };
  }

  // ==========================================================================
  // COMPOSITE VALIDATORS
  // ==========================================================================

  /// Combines multiple validators into one.
  ///
  /// Returns the first error message encountered, or null if all pass.
  ///
  /// Example:
  /// ```dart
  /// TextFormField(
  ///   validator: Validators.compose([
  ///     Validators.required,
  ///     Validators.email,
  ///   ]),
  /// );
  /// ```
  static String? Function(String?) compose(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) {
          return error;
        }
      }
      return null;
    };
  }

  // ==========================================================================
  // PATTERN VALIDATORS
  // ==========================================================================

  /// Validates that a string matches a regular expression pattern.
  ///
  /// Returns null if valid, error message if invalid.
  ///
  /// Example:
  /// ```dart
  /// final validator = Validators.pattern(
  ///   r'^[A-Z]',
  ///   'Must start with uppercase letter',
  /// );
  /// validator('Hello');    // null (valid)
  /// validator('hello');    // error message
  /// ```
  static String? Function(String?) pattern(String pattern, String message) {
    final regex = RegExp(pattern);
    return (String? value) {
      if (value == null || value.isEmpty) {
        return null; // Empty is valid, combine with required() if needed
      }

      if (!regex.hasMatch(value)) {
        return message;
      }

      return null;
    };
  }
}
