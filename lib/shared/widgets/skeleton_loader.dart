import 'package:fitgenie_app/core/constants/app_colors.dart';
import 'package:fitgenie_app/core/constants/app_sizes.dart';
import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer-effect placeholder widgets for content loading states.
///
/// This file provides a collection of skeleton loader widgets that display
/// animated shimmer effects while content is being loaded. The skeleton shapes
/// match actual content layouts to maintain visual consistency and reduce
/// perceived loading time per UX specification.
///
/// Features:
/// - Smooth shimmer animation effect
/// - Preset shapes matching common content types
/// - Customizable dimensions and border radius
/// - Composed loaders for complex layouts (e.g., plan cards)
/// - Theme-aware colors (light/dark mode support)
///
/// Usage:
/// ```dart
/// // During loading state
/// if (isLoading) {
///   return PlanSkeletonLoader();
/// } else {
///   return PlanCard(data: plan);
/// }
/// ```
///
/// Best Practices:
/// - Match skeleton dimensions to actual content for seamless transition
/// - Use for loading states >500ms (faster loads can use simple spinner)
/// - Combine multiple skeleton elements for complex layouts
/// - Ensure skeleton count matches expected content items

/// Base skeleton loader widget with shimmer animation.
///
/// This is the foundational widget that other skeleton components build upon.
/// It provides the shimmer effect and basic container styling.
///
/// Usage:
/// ```dart
/// SkeletonLoader(
///   width: 200,
///   height: 24,
///   borderRadius: 8,
/// )
/// ```
class SkeletonLoader extends StatelessWidget {
  /// Width of the skeleton container.
  ///
  /// If null, container expands to available width.
  final double? width;

  /// Height of the skeleton container.
  final double height;

  /// Border radius for rounded corners.
  ///
  /// Defaults to [AppSizes.radiusSm] (8dp).
  final double borderRadius;

  /// Creates a base [SkeletonLoader] with shimmer animation.
  const SkeletonLoader({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = AppSizes.radiusSm,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;

    // Theme-appropriate shimmer colors
    final baseColor = isDark
        ? AppColors.shimmerBaseDark
        : AppColors.shimmerBaseLight;
    final highlightColor = isDark
        ? AppColors.shimmerHighlightDark
        : AppColors.shimmerHighlightLight;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Card-shaped skeleton placeholder.
///
/// Mimics the shape and size of a typical card component.
/// Use for loading card-based content like plan cards, exercise cards, etc.
///
/// Usage:
/// ```dart
/// ListView.builder(
///   itemCount: 3,
///   itemBuilder: (context, index) => SkeletonCard(),
/// )
/// ```
class SkeletonCard extends StatelessWidget {
  /// Height of the skeleton card.
  ///
  /// Defaults to 120dp.
  final double height;

  /// Creates a card-shaped [SkeletonLoader].
  const SkeletonCard({super.key, this.height = 120});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: double.infinity,
      height: height,
      borderRadius: AppSizes.radiusMd,
    );
  }
}

/// Text line skeleton placeholder with width variants.
///
/// Mimics text lines with various widths to represent different content lengths.
///
/// Width variants:
/// - [SkeletonTextWidth.full]: 100% width (default)
/// - [SkeletonTextWidth.threeFourths]: 75% width
/// - [SkeletonTextWidth.half]: 50% width
/// - [SkeletonTextWidth.quarter]: 25% width
///
/// Usage:
/// ```dart
/// Column(
///   children: [
///     SkeletonText(width: SkeletonTextWidth.full),
///     SkeletonText(width: SkeletonTextWidth.threeFourths),
///     SkeletonText(width: SkeletonTextWidth.half),
///   ],
/// )
/// ```
class SkeletonText extends StatelessWidget {
  /// Width variant for the text line.
  ///
  /// Defaults to [SkeletonTextWidth.full].
  final SkeletonTextWidth width;

  /// Height of the text line.
  ///
  /// Defaults to 16dp (typical body text height).
  final double height;

  /// Creates a text line [SkeletonLoader].
  const SkeletonText({
    super.key,
    this.width = SkeletonTextWidth.full,
    this.height = 16,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double? containerWidth;

        switch (width) {
          case SkeletonTextWidth.full:
            containerWidth = double.infinity;
            break;
          case SkeletonTextWidth.threeFourths:
            containerWidth = constraints.maxWidth * 0.75;
            break;
          case SkeletonTextWidth.half:
            containerWidth = constraints.maxWidth * 0.5;
            break;
          case SkeletonTextWidth.quarter:
            containerWidth = constraints.maxWidth * 0.25;
            break;
        }

        return SkeletonLoader(
          width: containerWidth,
          height: height,
          borderRadius: AppSizes.radiusSm / 2, // Slightly rounded for text
        );
      },
    );
  }
}

/// Circular skeleton placeholder for avatars and icons.
///
/// Use for loading states of profile pictures, user avatars, or circular icons.
///
/// Usage:
/// ```dart
/// SkeletonAvatar(size: 48)
/// ```
class SkeletonAvatar extends StatelessWidget {
  /// Diameter of the circular skeleton.
  ///
  /// Defaults to 40dp.
  final double size;

  /// Creates a circular avatar [SkeletonLoader].
  const SkeletonAvatar({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: size,
      height: size,
      borderRadius: size / 2, // Makes it circular
    );
  }
}

/// Composed skeleton loader matching plan card layout.
///
/// This widget combines multiple skeleton elements to create a placeholder
/// that closely matches the structure of an actual plan card, including:
/// - Title bar with icon
/// - Exercise count indicator
/// - Exercise list items
/// - Meal indicators
///
/// Usage:
/// ```dart
/// if (isLoadingPlan) {
///   return ListView.builder(
///     itemCount: 3,
///     itemBuilder: (context, index) => PlanSkeletonLoader(),
///   );
/// }
/// ```
class PlanSkeletonLoader extends StatelessWidget {
  /// Creates a composed skeleton loader for plan cards.
  const PlanSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.symmetric(
        horizontal: AppSizes.spacingMd,
        vertical: AppSizes.spacingSm,
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSizes.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row (icon + title)
            Row(
              children: [
                SkeletonAvatar(size: 24),
                SizedBox(width: AppSizes.spacingSm),
                Expanded(
                  child: SkeletonText(
                    width: SkeletonTextWidth.threeFourths,
                    height: 20,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSizes.spacingMd),

            // Exercise count indicator
            SkeletonText(width: SkeletonTextWidth.quarter, height: 14),
            SizedBox(height: AppSizes.spacingSm),

            // Exercise items (3 lines)
            SkeletonText(width: SkeletonTextWidth.full),
            SizedBox(height: AppSizes.spacingSm),
            SkeletonText(width: SkeletonTextWidth.full),
            SizedBox(height: AppSizes.spacingSm),
            SkeletonText(width: SkeletonTextWidth.threeFourths),
            SizedBox(height: AppSizes.spacingMd),

            // Meal section divider
            SkeletonLoader(width: double.infinity, height: 1, borderRadius: 0),
            SizedBox(height: AppSizes.spacingMd),

            // Meal indicators
            Row(
              children: [
                Expanded(
                  child: SkeletonLoader(
                    width: double.infinity,
                    height: 60,
                    borderRadius: AppSizes.radiusSm,
                  ),
                ),
                SizedBox(width: AppSizes.spacingSm),
                Expanded(
                  child: SkeletonLoader(
                    width: double.infinity,
                    height: 60,
                    borderRadius: AppSizes.radiusSm,
                  ),
                ),
                SizedBox(width: AppSizes.spacingSm),
                Expanded(
                  child: SkeletonLoader(
                    width: double.infinity,
                    height: 60,
                    borderRadius: AppSizes.radiusSm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Width variants for [SkeletonText].
///
/// Defines preset width percentages for text line skeletons to simulate
/// varying text lengths naturally.
enum SkeletonTextWidth {
  /// Full width (100%) - for long text lines or headings.
  full,

  /// Three-fourths width (75%) - for medium-length text.
  threeFourths,

  /// Half width (50%) - for shorter text or labels.
  half,

  /// Quarter width (25%) - for very short labels or indicators.
  quarter,
}
