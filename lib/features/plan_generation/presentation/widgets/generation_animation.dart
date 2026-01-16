import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fitgenie_app/core/constants/app_sizes.dart';

/// Engaging animation widget displayed during AI plan generation.
///
/// This widget provides visual feedback during the 15-30 second plan generation
/// process, keeping users engaged and building anticipation for their
/// personalized plan.
///
/// Key Features:
/// - Animated loading indicator with brand colors
/// - Cycling progress messages that show generation steps
/// - Smooth transitions between messages
/// - Professional, polished appearance
/// - Matches app theme and brand identity
///
/// Messages Cycle:
/// 1. "Analyzing your profile..."
/// 2. "Creating personalized workouts..."
/// 3. "Designing nutrition plan..."
/// 4. "Finalizing your 7-day plan..."
///
/// Usage:
/// ```dart
/// // During generation loading state
/// if (isGenerating) {
///   return const GenerationAnimation();
/// }
/// ```
///
/// Design Notes:
/// - Uses coral primary color from theme
/// - Smooth fade transitions between messages
/// - Centered layout for focus
/// - Large, readable text
/// - Professional animation speed
class GenerationAnimation extends StatefulWidget {
  /// Creates a GenerationAnimation widget.
  const GenerationAnimation({super.key});

  @override
  State<GenerationAnimation> createState() => _GenerationAnimationState();
}

class _GenerationAnimationState extends State<GenerationAnimation> {
  /// Current message index being displayed.
  int _currentMessageIndex = 0;

  /// List of messages to cycle through during generation.
  ///
  /// Each message describes a step in the plan generation process,
  /// helping users understand what's happening and building anticipation.
  final List<String> _messages = [
    'Analyzing your profile...',
    'Creating personalized workouts...',
    'Designing nutrition plan...',
    'Matching exercises to your equipment...',
    'Finalizing your 7-day plan...',
  ];

  @override
  void initState() {
    super.initState();
    _startMessageCycle();
  }

  /// Starts the message cycling timer.
  ///
  /// Changes message every 3 seconds to keep user engaged.
  void _startMessageCycle() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _currentMessageIndex = (_currentMessageIndex + 1) % _messages.length;
        });
        _startMessageCycle();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated loading icon
          _buildLoadingIcon(colorScheme),

          const SizedBox(height: AppSizes.spacingXl),

          // Main title
          Text(
            'Generating Your Plan',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSizes.spacingMd),

          // Animated message
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              _messages[_currentMessageIndex],
              key: ValueKey<int>(_currentMessageIndex),
              style: context.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: AppSizes.spacingXl),

          // Progress indicator
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
          ),

          const SizedBox(height: AppSizes.spacingMd),

          // Time estimate
          Text(
            'This usually takes 15-30 seconds',
            style: context.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds the animated loading icon.
  ///
  /// Features:
  /// - Pulsing animation
  /// - Rotating animation
  /// - Brand color gradient
  /// - Smooth, professional motion
  Widget _buildLoadingIcon(ColorScheme colorScheme) {
    return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary,
                colorScheme.primary.withValues(alpha: 0.7),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(
            Icons.fitness_center,
            size: 60,
            color: colorScheme.onPrimary,
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.0, 1.0),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeInOut,
        )
        .then()
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(0.9, 0.9),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeInOut,
        );
  }
}

/// Alternative generation animation with spinning indicator.
///
/// A simpler version with just a spinning circular progress indicator
/// and single message. Use this for lighter-weight loading states.
///
/// Usage:
/// ```dart
/// const SimpleGenerationAnimation();
/// ```
class SimpleGenerationAnimation extends StatelessWidget {
  /// Creates a SimpleGenerationAnimation widget.
  const SimpleGenerationAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 3, color: colorScheme.primary),
          const SizedBox(height: AppSizes.spacingLg),
          Text(
            'Generating your personalized plan...',
            style: context.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Compact generation indicator for inline use.
///
/// A small, unobtrusive loading indicator suitable for use within
/// other UI elements (e.g., in a card or dialog).
///
/// Usage:
/// ```dart
/// const CompactGenerationIndicator();
/// ```
class CompactGenerationIndicator extends StatelessWidget {
  /// Creates a CompactGenerationIndicator widget.
  const CompactGenerationIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppSizes.spacingSm),
        Text(
          'Generating...',
          style: context.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
