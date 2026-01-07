/// Dietary restriction options for FitGenie app.
///
/// This file defines the available dietary restrictions that users can select
/// during onboarding. These options are used throughout the app for:
/// - Onboarding dietary preference selection
/// - User profile data model
/// - Meal card dietary badges
/// - AI prompt generation (Gemini constraints)
///
/// CRITICAL: These enum values must stay synchronized with:
/// - Gemini API prompt constraints
/// - Firestore schema validation
/// - User profile data model
enum DietaryRestriction {
  /// No dietary restrictions
  none,

  /// Vegetarian diet (no meat, fish, or poultry)
  vegetarian,

  /// Vegan diet (no animal products)
  vegan,

  /// Gluten-free diet
  glutenFree,

  /// Lactose-free / dairy-free diet
  lactoseFree,

  /// Halal dietary requirements
  halal,

  /// Kosher dietary requirements
  kosher,

  /// Pescatarian diet (vegetarian + fish)
  pescatarian,

  /// Nut-free diet (no tree nuts or peanuts)
  nutFree,

  /// Shellfish-free diet
  shellfishFree,

  /// Soy-free diet
  soyFree,

  /// Egg-free diet
  eggFree,
}

/// Extension methods for DietaryRestriction enum.
///
/// Provides display names and icon representations for UI display.
extension DietaryRestrictionExtension on DietaryRestriction {
  /// User-friendly display name for the dietary restriction.
  ///
  /// Used in onboarding selection UI and profile display.
  String get displayName {
    switch (this) {
      case DietaryRestriction.none:
        return 'No Restrictions';
      case DietaryRestriction.vegetarian:
        return 'Vegetarian';
      case DietaryRestriction.vegan:
        return 'Vegan';
      case DietaryRestriction.glutenFree:
        return 'Gluten-Free';
      case DietaryRestriction.lactoseFree:
        return 'Lactose-Free';
      case DietaryRestriction.halal:
        return 'Halal';
      case DietaryRestriction.kosher:
        return 'Kosher';
      case DietaryRestriction.pescatarian:
        return 'Pescatarian';
      case DietaryRestriction.nutFree:
        return 'Nut-Free';
      case DietaryRestriction.shellfishFree:
        return 'Shellfish-Free';
      case DietaryRestriction.soyFree:
        return 'Soy-Free';
      case DietaryRestriction.eggFree:
        return 'Egg-Free';
    }
  }

  /// Icon emoji representing the dietary restriction.
  ///
  /// Used in meal cards as dietary compliance badges.
  String get icon {
    switch (this) {
      case DietaryRestriction.none:
        return '🍽️';
      case DietaryRestriction.vegetarian:
        return '🥬';
      case DietaryRestriction.vegan:
        return '🌱';
      case DietaryRestriction.glutenFree:
        return '🌾';
      case DietaryRestriction.lactoseFree:
        return '🥛';
      case DietaryRestriction.halal:
        return '☪️';
      case DietaryRestriction.kosher:
        return '✡️';
      case DietaryRestriction.pescatarian:
        return '🐟';
      case DietaryRestriction.nutFree:
        return '🥜';
      case DietaryRestriction.shellfishFree:
        return '🦐';
      case DietaryRestriction.soyFree:
        return '🫘';
      case DietaryRestriction.eggFree:
        return '🥚';
    }
  }

  /// Short description explaining the dietary restriction.
  ///
  /// Used in onboarding to help users understand each option.
  String get description {
    switch (this) {
      case DietaryRestriction.none:
        return 'No dietary restrictions';
      case DietaryRestriction.vegetarian:
        return 'No meat, fish, or poultry';
      case DietaryRestriction.vegan:
        return 'No animal products';
      case DietaryRestriction.glutenFree:
        return 'No gluten-containing grains';
      case DietaryRestriction.lactoseFree:
        return 'No dairy or lactose';
      case DietaryRestriction.halal:
        return 'Islamic dietary laws';
      case DietaryRestriction.kosher:
        return 'Jewish dietary laws';
      case DietaryRestriction.pescatarian:
        return 'Vegetarian plus fish/seafood';
      case DietaryRestriction.nutFree:
        return 'No tree nuts or peanuts';
      case DietaryRestriction.shellfishFree:
        return 'No shrimp, crab, lobster, etc.';
      case DietaryRestriction.soyFree:
        return 'No soy products';
      case DietaryRestriction.eggFree:
        return 'No eggs or egg products';
    }
  }

  /// Firestore-compatible string value.
  ///
  /// Used for database storage and retrieval.
  /// CRITICAL: This format must match Firestore schema.
  String get firestoreValue {
    switch (this) {
      case DietaryRestriction.none:
        return 'none';
      case DietaryRestriction.vegetarian:
        return 'vegetarian';
      case DietaryRestriction.vegan:
        return 'vegan';
      case DietaryRestriction.glutenFree:
        return 'gluten_free';
      case DietaryRestriction.lactoseFree:
        return 'lactose_free';
      case DietaryRestriction.halal:
        return 'halal';
      case DietaryRestriction.kosher:
        return 'kosher';
      case DietaryRestriction.pescatarian:
        return 'pescatarian';
      case DietaryRestriction.nutFree:
        return 'nut_free';
      case DietaryRestriction.shellfishFree:
        return 'shellfish_free';
      case DietaryRestriction.soyFree:
        return 'soy_free';
      case DietaryRestriction.eggFree:
        return 'egg_free';
    }
  }

  /// AI prompt-friendly string value.
  ///
  /// Used when building Gemini API prompts to ensure consistent
  /// constraint communication with the AI.
  String get promptValue {
    switch (this) {
      case DietaryRestriction.none:
        return 'no restrictions';
      case DietaryRestriction.vegetarian:
        return 'vegetarian (no meat, fish, or poultry)';
      case DietaryRestriction.vegan:
        return 'vegan (no animal products)';
      case DietaryRestriction.glutenFree:
        return 'gluten-free';
      case DietaryRestriction.lactoseFree:
        return 'lactose-free / dairy-free';
      case DietaryRestriction.halal:
        return 'halal';
      case DietaryRestriction.kosher:
        return 'kosher';
      case DietaryRestriction.pescatarian:
        return 'pescatarian (vegetarian plus fish/seafood)';
      case DietaryRestriction.nutFree:
        return 'nut-free (no tree nuts or peanuts)';
      case DietaryRestriction.shellfishFree:
        return 'shellfish-free';
      case DietaryRestriction.soyFree:
        return 'soy-free';
      case DietaryRestriction.eggFree:
        return 'egg-free';
    }
  }

  /// Whether this is the "none" option (no restrictions).
  ///
  /// Useful for conditional logic in UI and data validation.
  bool get isNone => this == DietaryRestriction.none;

  /// Whether this restriction conflicts with another restriction.
  ///
  /// Used for validation during multi-select to prevent contradictory choices.
  /// For example: vegan conflicts with pescatarian.
  bool conflictsWith(DietaryRestriction other) {
    // Vegan conflicts with pescatarian (vegan is stricter)
    if (this == DietaryRestriction.vegan &&
        other == DietaryRestriction.pescatarian) {
      return true;
    }
    if (this == DietaryRestriction.pescatarian &&
        other == DietaryRestriction.vegan) {
      return true;
    }

    // Vegan includes vegetarian (vegan is stricter), so they don't conflict
    // but selecting vegan should auto-imply vegetarian constraints

    // None conflicts with everything (it means no restrictions)
    if (this == DietaryRestriction.none || other == DietaryRestriction.none) {
      return this != other; // Conflicts with any specific restriction
    }

    return false;
  }
}

/// Helper functions for working with dietary restrictions.
class DietaryRestrictionHelper {
  DietaryRestrictionHelper._(); // Private constructor

  /// Parse a Firestore string value to DietaryRestriction enum.
  ///
  /// Returns null if the string doesn't match any known restriction.
  static DietaryRestriction? fromFirestoreValue(String value) {
    for (final restriction in DietaryRestriction.values) {
      if (restriction.firestoreValue == value) {
        return restriction;
      }
    }
    return null;
  }

  /// Convert a list of Firestore string values to DietaryRestriction list.
  ///
  /// Skips any unrecognized values.
  static List<DietaryRestriction> fromFirestoreList(List<String> values) {
    return values
        .map((value) => fromFirestoreValue(value))
        .whereType<DietaryRestriction>()
        .toList();
  }

  /// Convert a list of DietaryRestriction to Firestore string values.
  static List<String> toFirestoreList(List<DietaryRestriction> restrictions) {
    return restrictions.map((r) => r.firestoreValue).toList();
  }

  /// Get all selectable dietary restrictions (excludes 'none').
  ///
  /// Used in onboarding multi-select UI.
  static List<DietaryRestriction> get selectableOptions {
    return DietaryRestriction.values
        .where((r) => r != DietaryRestriction.none)
        .toList();
  }

  /// Get default selection (no restrictions).
  static List<DietaryRestriction> get defaultSelection {
    return [DietaryRestriction.none];
  }

  /// Validate a list of dietary restrictions for conflicts.
  ///
  /// Returns true if the selection is valid (no conflicts).
  static bool validateSelection(List<DietaryRestriction> selected) {
    // Empty selection is invalid
    if (selected.isEmpty) {
      return false;
    }

    // If 'none' is selected, it must be the only selection
    if (selected.contains(DietaryRestriction.none) && selected.length > 1) {
      return false;
    }

    // Check for conflicts between selected restrictions
    for (int i = 0; i < selected.length; i++) {
      for (int j = i + 1; j < selected.length; j++) {
        if (selected[i].conflictsWith(selected[j])) {
          return false;
        }
      }
    }

    return true;
  }

  /// Build a comma-separated display string from multiple restrictions.
  ///
  /// Example: "Vegetarian, Nut-Free, Gluten-Free"
  static String formatMultiple(List<DietaryRestriction> restrictions) {
    if (restrictions.isEmpty || restrictions.first.isNone) {
      return 'No Restrictions';
    }
    return restrictions.map((r) => r.displayName).join(', ');
  }

  /// Build an AI prompt string from multiple restrictions.
  ///
  /// Example: "vegetarian (no meat, fish, or poultry), nut-free (no tree nuts or peanuts)"
  static String formatForPrompt(List<DietaryRestriction> restrictions) {
    if (restrictions.isEmpty || restrictions.first.isNone) {
      return 'no dietary restrictions';
    }
    return restrictions.map((r) => r.promptValue).join(', ');
  }
}
