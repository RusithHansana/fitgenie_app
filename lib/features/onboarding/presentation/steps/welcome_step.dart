import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:fitgenie_app/core/constants/app_strings.dart';
import 'package:fitgenie_app/core/constants/app_sizes.dart';
import 'package:fitgenie_app/shared/widgets/app_button.dart';

/// First step of the onboarding wizard with welcome message and branding.
///
/// This screen serves as the entry point to the onboarding flow, introducing
/// the user to FitGenie and explaining what data will be collected and why.
/// It sets a positive, welcoming tone for the onboarding experience.
///
/// Features:
/// - App branding and logo
/// - Welcome message and value proposition
/// - Brief explanation of what's ahead
/// - "Get Started" CTA button
/// - Fade-in animations for engaging first impression
///
/// Usage:
/// ```dart
/// WelcomeStep(
///   onNext: () {
///     // Advance to next step
///   },
/// )
/// ```
class WelcomeStep extends StatefulWidget {
  /// Callback invoked when user taps "Get Started" button.
  final VoidCallback onNext;

  const WelcomeStep({super.key, required this.onNext});

  @override
  State<WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends State<WelcomeStep>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _animationController.forward();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenMarginMobile,
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // App Logo / Branding
                            _buildLogo(colorScheme),

                            const SizedBox(height: AppSizes.spacingXl),

                            // Welcome Title
                            Text(
                              AppStrings.onboardingWelcomeTitle,
                              style: context.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: AppSizes.spacingMd),

                            // Tagline
                            Text(
                              AppStrings.appTagline,
                              style: context.textTheme.titleMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: AppSizes.spacingXl),

                            // Description
                            Text(
                              AppStrings.onboardingWelcomeDescription,
                              style: context.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: AppSizes.spacingLg),

                            // Benefits list
                            _buildBenefitsList(context.theme, colorScheme),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Get Started Button
              Padding(
                padding: const EdgeInsets.only(
                  bottom: AppSizes.spacingLg,
                  top: AppSizes.spacingMd,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: AppButton(
                    label: AppStrings.buttonGetStarted,
                    onPressed: widget.onNext,
                    fullWidth: true,
                    icon: Icons.arrow_forward,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the app logo with animated container.
  Widget _buildLogo(ColorScheme colorScheme) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.fitness_center,
          size: 56,
          color: colorScheme.onPrimary,
        ),
      ),
    );
  }

  /// Builds the benefits list showing what FitGenie offers.
  Widget _buildBenefitsList(ThemeData theme, ColorScheme colorScheme) {
    final benefits = [
      const _BenefitItem(
        icon: Icons.psychology,
        title: 'AI-Powered Plans',
        description: 'Personalized workouts and meals',
      ),
      const _BenefitItem(
        icon: Icons.fitness_center,
        title: 'Your Equipment',
        description: 'Workouts using what you have',
      ),
      const _BenefitItem(
        icon: Icons.restaurant,
        title: 'Your Diet',
        description: 'Respects all restrictions',
      ),
      const _BenefitItem(
        icon: Icons.offline_bolt,
        title: 'Offline Access',
        description: 'Works without internet',
      ),
    ];

    return Column(
      children: benefits.map((benefit) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.spacingSm),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Icon(
                  benefit.icon,
                  size: AppSizes.iconMd,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSizes.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      benefit.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      benefit.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Internal data class for benefit items.
class _BenefitItem {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}
