/// Centralized sizing and spacing constants for FitGenie app.
///
/// This class provides consistent spacing, sizing, and dimension values based
/// on a 4dp base unit. All values are multiples of 4 for visual harmony and
/// grid alignment.
///
/// Spacing Philosophy:
/// - Base unit: 4dp
/// - Scale increases by powers of 2 (xs=4, sm=8, md=16, lg=24, xl=32, xxl=48)
/// - Consistent application creates visual rhythm
///
/// All touch targets meet minimum 44dp accessibility requirement.
class AppSizes {
  AppSizes._(); // Private constructor to prevent instantiation

  // ============================================================================
  // BASE UNIT
  // ============================================================================

  /// Base spacing unit (4dp)
  ///
  /// All other spacing values are multiples of this base unit.
  static const double baseUnit = 4.0;

  // ============================================================================
  // SPACING SCALE
  // ============================================================================

  /// Extra extra small spacing (2dp)
  ///
  /// Used for very tight spacing like icon-to-text gaps.
  static const double spacing2xs = 2.0;

  /// Extra small spacing (4dp)
  ///
  /// Used for compact internal padding in dense UI elements.
  static const double spacingXs = 4.0;

  /// Small spacing (8dp)
  ///
  /// Used for standard internal padding, small gaps between elements.
  static const double spacingSm = 8.0;

  /// Medium spacing (16dp)
  ///
  /// Used for card padding, list item gaps, standard margins.
  /// This is the most commonly used spacing value.
  static const double spacingMd = 16.0;

  /// Large spacing (24dp)
  ///
  /// Used for section spacing, larger gaps between groups.
  static const double spacingLg = 24.0;

  /// Extra large spacing (32dp)
  ///
  /// Used for major section breaks, screen padding on tablets.
  static const double spacingXl = 32.0;

  /// Extra extra large spacing (48dp)
  ///
  /// Used for prominent section breaks, hero element spacing.
  static const double spacingXxl = 48.0;

  // ============================================================================
  // BORDER RADIUS
  // ============================================================================

  /// Small border radius (8dp)
  ///
  /// Used for chips, small buttons, and compact elements.
  static const double radiusSm = 8.0;

  /// Medium border radius (16dp)
  ///
  /// Used for cards, buttons, and most rounded corners.
  /// This is the standard radius for FitGenie.
  static const double radiusMd = 16.0;

  /// Large border radius (24dp)
  ///
  /// Used for modals, bottom sheets, and large surfaces.
  static const double radiusLg = 24.0;

  /// Full border radius (999dp)
  ///
  /// Creates perfect circles and pill shapes.
  static const double radiusFull = 999.0;

  // ============================================================================
  // TOUCH TARGETS
  // ============================================================================

  /// Minimum touch target size (44dp)
  ///
  /// Ensures all interactive elements are easily tappable.
  /// Based on iOS Human Interface Guidelines and Material Design standards.
  static const double touchTargetMin = 44.0;

  /// Standard touch target size (48dp)
  ///
  /// Preferred size for most interactive elements.
  static const double touchTargetStandard = 48.0;

  /// Large touch target size (56dp)
  ///
  /// Used for primary actions and floating action buttons.
  static const double touchTargetLarge = 56.0;

  // ============================================================================
  // ICON SIZES
  // ============================================================================

  /// Small icon size (16dp)
  ///
  /// Used for inline icons in text or compact UI elements.
  static const double iconSm = 16.0;

  /// Medium icon size (24dp)
  ///
  /// Standard icon size for most use cases.
  static const double iconMd = 24.0;

  /// Large icon size (32dp)
  ///
  /// Used for prominent icons or header elements.
  static const double iconLg = 32.0;

  /// Extra large icon size (48dp)
  ///
  /// Used for feature illustrations or empty states.
  static const double iconXl = 48.0;

  /// Extra extra large icon size (64dp)
  ///
  /// Used for hero icons or splash screens.
  static const double iconXxl = 64.0;

  // ============================================================================
  // CARD DIMENSIONS
  // ============================================================================

  /// Standard card padding (16dp)
  ///
  /// Used for internal padding in cards and containers.
  static const double cardPadding = 16.0;

  /// Card gap (12dp)
  ///
  /// Vertical spacing between cards in lists.
  static const double cardGap = 12.0;

  /// Card elevation (2dp)
  ///
  /// Subtle elevation for cards using Material 3 tonal elevation.
  static const double cardElevation = 2.0;

  // ============================================================================
  // LAYOUT CONSTRAINTS
  // ============================================================================

  /// Maximum content width (600dp)
  ///
  /// Prevents content from becoming too wide on tablets and desktops.
  /// Ensures optimal reading line length and visual balance.
  static const double maxContentWidth = 600.0;

  /// Screen edge margin - mobile (16dp)
  ///
  /// Standard horizontal margin on mobile devices.
  static const double screenMarginMobile = 16.0;

  /// Screen edge margin - tablet (24dp)
  ///
  /// Increased horizontal margin on tablet devices.
  static const double screenMarginTablet = 24.0;

  /// Screen edge margin - desktop (32dp)
  ///
  /// Maximum horizontal margin on desktop displays.
  static const double screenMarginDesktop = 32.0;

  // ============================================================================
  // COMPONENT SIZES
  // ============================================================================

  /// Button height - small (36dp)
  ///
  /// Compact button size for secondary actions.
  static const double buttonHeightSm = 36.0;

  /// Button height - medium (48dp)
  ///
  /// Standard button height for most actions.
  static const double buttonHeightMd = 48.0;

  /// Button height - large (56dp)
  ///
  /// Prominent button height for primary actions.
  static const double buttonHeightLg = 56.0;

  /// Text field height (56dp)
  ///
  /// Standard height for text input fields.
  static const double textFieldHeight = 56.0;

  /// App bar height (56dp)
  ///
  /// Standard height for app bars and toolbars.
  static const double appBarHeight = 56.0;

  /// Bottom navigation bar height (56dp)
  ///
  /// Standard height for bottom navigation.
  static const double bottomNavHeight = 56.0;

  /// Tab bar height (48dp)
  ///
  /// Standard height for tab bars.
  static const double tabBarHeight = 48.0;

  // ============================================================================
  // DIVIDERS & BORDERS
  // ============================================================================

  /// Border width - thin (1dp)
  ///
  /// Used for subtle borders and dividers.
  static const double borderThin = 1.0;

  /// Border width - medium (2dp)
  ///
  /// Used for prominent borders and focus indicators.
  static const double borderMedium = 2.0;

  /// Border width - thick (4dp)
  ///
  /// Used for strong visual separation.
  static const double borderThick = 4.0;

  /// Divider thickness (1dp)
  ///
  /// Standard thickness for divider lines.
  static const double dividerThickness = 1.0;

  // ============================================================================
  // LIST ITEMS
  // ============================================================================

  /// List item height - single line (56dp)
  ///
  /// Standard height for single-line list items.
  static const double listItemHeightSingle = 56.0;

  /// List item height - two line (72dp)
  ///
  /// Standard height for two-line list items.
  static const double listItemHeightDouble = 72.0;

  /// List item height - three line (88dp)
  ///
  /// Standard height for three-line list items.
  static const double listItemHeightTriple = 88.0;

  /// List item padding (16dp)
  ///
  /// Horizontal padding for list items.
  static const double listItemPadding = 16.0;

  // ============================================================================
  // WORKOUT & MEAL CARDS
  // ============================================================================

  /// Exercise card height (80dp)
  ///
  /// Collapsed height for exercise cards in workout list.
  static const double exerciseCardHeight = 80.0;

  /// Meal card height (120dp)
  ///
  /// Collapsed height for meal cards in daily plan.
  static const double mealCardHeight = 120.0;

  /// Workout card minimum height (100dp)
  ///
  /// Minimum collapsed height for workout summary cards.
  static const double workoutCardMinHeight = 100.0;

  // ============================================================================
  // BADGES & CHIPS
  // ============================================================================

  /// Chip height (32dp)
  ///
  /// Standard height for filter chips and action chips.
  static const double chipHeight = 32.0;

  /// Badge size (20dp)
  ///
  /// Size for small badge indicators (dietary, equipment tags).
  static const double badgeSize = 20.0;

  /// Streak badge size (48dp)
  ///
  /// Size for streak fire emoji badge in header.
  static const double streakBadgeSize = 48.0;

  // ============================================================================
  // AVATARS
  // ============================================================================

  /// Avatar size - small (32dp)
  ///
  /// Used for compact user avatars in lists.
  static const double avatarSm = 32.0;

  /// Avatar size - medium (48dp)
  ///
  /// Standard avatar size for most contexts.
  static const double avatarMd = 48.0;

  /// Avatar size - large (64dp)
  ///
  /// Used for profile screens and prominent displays.
  static const double avatarLg = 64.0;

  /// Avatar size - extra large (96dp)
  ///
  /// Used for profile headers and hero sections.
  static const double avatarXl = 96.0;

  // ============================================================================
  // ANIMATIONS & TRANSITIONS
  // ============================================================================

  /// Animation duration - fast (100ms)
  ///
  /// Used for micro-interactions like button presses.
  static const int animationFast = 100;

  /// Animation duration - normal (200ms)
  ///
  /// Standard duration for most UI transitions.
  static const int animationNormal = 200;

  /// Animation duration - slow (300ms)
  ///
  /// Used for screen transitions and complex animations.
  static const int animationSlow = 300;

  /// Animation duration - emphasis (500ms)
  ///
  /// Used for celebration animations and emphasis effects.
  static const int animationEmphasis = 500;

  // ============================================================================
  // SHADOWS & ELEVATION
  // ============================================================================

  /// Elevation level 0 (0dp)
  ///
  /// No elevation - flat surface.
  static const double elevation0 = 0.0;

  /// Elevation level 1 (1dp)
  ///
  /// Subtle elevation for cards.
  static const double elevation1 = 1.0;

  /// Elevation level 2 (2dp)
  ///
  /// Standard elevation for raised elements.
  static const double elevation2 = 2.0;

  /// Elevation level 3 (4dp)
  ///
  /// Prominent elevation for floating elements.
  static const double elevation3 = 4.0;

  /// Elevation level 4 (8dp)
  ///
  /// High elevation for modals and overlays.
  static const double elevation4 = 8.0;

  // ============================================================================
  // OPACITY VALUES
  // ============================================================================

  /// Disabled opacity (38%)
  ///
  /// Used for disabled interactive elements.
  static const double opacityDisabled = 0.38;

  /// Medium emphasis opacity (60%)
  ///
  /// Used for secondary text and icons.
  static const double opacityMedium = 0.60;

  /// High emphasis opacity (87%)
  ///
  /// Used for primary text.
  static const double opacityHigh = 0.87;

  /// Overlay opacity - light (60%)
  ///
  /// Background overlay opacity for light mode.
  static const double overlayOpacityLight = 0.60;

  /// Overlay opacity - dark (90%)
  ///
  /// Background overlay opacity for dark mode.
  static const double overlayOpacityDark = 0.90;
}
