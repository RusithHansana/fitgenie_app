import 'package:fitgenie_app/core/constants/app_sizes.dart';
import 'package:fitgenie_app/core/constants/app_strings.dart';
import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:fitgenie_app/routing/app_router.dart';
import 'package:fitgenie_app/shared/widgets/skeleton_loader.dart';
import 'package:fitgenie_app/features/profile/presentation/widgets/profile_header.dart';
import 'package:fitgenie_app/features/profile/presentation/widgets/stats_card.dart';
import 'package:fitgenie_app/features/profile/presentation/widgets/settings_tile.dart';
import 'package:fitgenie_app/features/profile/profile_providers.dart';
import 'package:fitgenie_app/features/auth/auth_providers.dart' as auth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Main profile screen showing user info, stats, and settings.
///
/// This screen displays:
/// - Profile header with avatar, email, and member since date
/// - Statistics card with streak, workouts, meals, and plans
/// - Settings section with edit profile and regenerate plan options
/// - Account section with logout and delete account options
/// - App version display at bottom
///
/// The screen uses a scrollable layout to accommodate all content and
/// handles loading/error states for profile and stats data.
///
/// Route: `/profile` (accessible from dashboard bottom navigation)
///
/// Usage:
/// ```dart
/// // In router configuration
/// GoRoute(
///   path: '/profile',
///   builder: (context, state) => const ProfileScreen(),
/// )
/// ```
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final statsAsync = ref.watch(userStatsProvider);
    final userAsync = ref.watch(auth.authStateProvider);

    return Scaffold(
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            // Should not happen due to route guards, but handle gracefully
            return const Center(
              child: Text('Please sign in to view your profile'),
            );
          }

          return CustomScrollView(
            slivers: [
              // App bar
              SliverAppBar(
                title: const Text(AppStrings.profileTitle),
                floating: true,
                backgroundColor: context.colorScheme.primaryContainer,
                foregroundColor: context.colorScheme.onPrimaryContainer,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.goToDashboard(),
                ),
              ),

              // Profile content
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Profile header
                    profileAsync.when(
                      data: (profile) => ProfileHeader(
                        user: user,
                        profile: profile,
                        onEditPressed: () {
                          // Navigate to edit profile screen
                          Navigator.of(context).pushNamed('/profile/edit');
                        },
                      ),
                      loading: () => Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSizes.spacingLg),
                        decoration: BoxDecoration(
                          color: context.colorScheme.surfaceContainerHighest,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(AppSizes.radiusLg),
                          ),
                        ),
                        child: const Column(
                          children: [
                            SkeletonAvatar(size: 40),
                            SizedBox(height: AppSizes.spacingMd),
                            SkeletonText(
                              width: SkeletonTextWidth.threeFourths,
                              height: 20,
                            ),
                            SizedBox(height: AppSizes.spacingXs),
                            SkeletonText(
                              width: SkeletonTextWidth.half,
                              height: 16,
                            ),
                          ],
                        ),
                      ),
                      error: (error, stack) => ProfileHeader(
                        user: user,
                        onEditPressed: () {
                          Navigator.of(context).pushNamed('/profile/edit');
                        },
                      ),
                    ),

                    const SizedBox(height: AppSizes.spacingLg),

                    // Stats card
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.screenMarginMobile,
                      ),
                      child: statsAsync.when(
                        data: (stats) => StatsCard(stats: stats),
                        loading: () => Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.spacingLg),
                            child: Column(
                              children: [
                                const SkeletonText(
                                  width: SkeletonTextWidth.half,
                                  height: 20,
                                ),
                                const SizedBox(height: AppSizes.spacingLg),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Expanded(child: _buildStatSkeleton()),
                                    Expanded(child: _buildStatSkeleton()),
                                    Expanded(child: _buildStatSkeleton()),
                                    Expanded(child: _buildStatSkeleton()),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        error: (error, stack) => _buildStatsError(context),
                      ),
                    ),

                    const SizedBox(height: AppSizes.spacingLg),

                    // Settings section
                    _buildSettingsSection(context, ref, profileAsync.value),

                    const SizedBox(height: AppSizes.spacingLg),

                    // Account section
                    _buildAccountSection(context, ref),

                    const SizedBox(height: AppSizes.spacingXl),

                    // App version
                    _buildAppVersion(context),

                    const SizedBox(height: AppSizes.spacingXl),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error loading profile: $error')),
      ),
    );
  }

  /// Builds the settings section with tiles.
  Widget _buildSettingsSection(
    BuildContext context,
    WidgetRef ref,
    dynamic profile,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenMarginMobile,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            const SettingsSectionHeader(
              title: AppStrings.sectionSettings,
              topPadding: AppSizes.spacingMd,
            ),
            SettingsTile(
              title: AppStrings.buttonEditProfile,
              subtitle: 'Update your fitness profile',
              leading: const Icon(Icons.edit_outlined),
              showChevron: true,
              onTap: () {
                Navigator.of(context).pushNamed('/profile/edit');
              },
            ),
            const SettingsDivider(
              indent: AppSizes.spacingMd + 24 + AppSizes.spacingMd,
            ),
            SettingsTile(
              title: 'Regenerate Plan',
              subtitle: 'Create a new 7-day plan',
              leading: const Icon(Icons.refresh),
              showChevron: true,
              onTap: () => _handleRegeneratePlan(context, ref),
            ),
            const SizedBox(height: AppSizes.spacingSm),
          ],
        ),
      ),
    );
  }

  /// Builds the account section with logout and delete options.
  Widget _buildAccountSection(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenMarginMobile,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            const SettingsSectionHeader(
              title: AppStrings.sectionAccount,
              topPadding: AppSizes.spacingMd,
            ),
            SettingsTile(
              title: AppStrings.buttonSignOut,
              leading: Icon(Icons.logout, color: context.colorScheme.error),
              onTap: () => _handleLogout(context, ref),
            ),
            const SettingsDivider(
              indent: AppSizes.spacingMd + 24 + AppSizes.spacingMd,
            ),
            SettingsTile(
              title: AppStrings.buttonDeleteAccount,
              subtitle: 'Permanently delete your account',
              leading: Icon(
                Icons.delete_forever,
                color: context.colorScheme.error,
              ),
              onTap: () => _handleDeleteAccount(context, ref),
            ),
            const SizedBox(height: AppSizes.spacingSm),
          ],
        ),
      ),
    );
  }

  /// Builds the app version display.
  Widget _buildAppVersion(BuildContext context) {
    return Text(
      '${AppStrings.appName} v1.0.0',
      style: context.textTheme.bodySmall?.copyWith(
        color: context.colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Handles regenerate plan action.
  void _handleRegeneratePlan(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate Plan'),
        content: const Text(
          'This will create a new 7-day workout and meal plan based on your current profile. Your existing plan will be replaced.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.buttonCancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.goToPlanGeneration();
            },
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );
  }

  /// Handles logout action with confirmation.
  void _handleLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(AppStrings.confirmSignOut),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.buttonNo),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();

              try {
                await ref.read(logoutProvider.future);
                // Navigation to login will be handled by route guards
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to sign out: $e'),
                      backgroundColor: context.colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text(AppStrings.buttonYes),
          ),
        ],
      ),
    );
  }

  /// Handles delete account action with strong confirmation.
  void _handleDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(AppStrings.confirmDeleteAccount),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.buttonCancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();

              try {
                await ref.read(deleteAccountProvider.future);
                // Navigation to login will be handled by route guards
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete account: $e'),
                      backgroundColor: context.colorScheme.error,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: context.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Builds a single stat skeleton item.
  static Widget _buildStatSkeleton() {
    return const Column(
      children: [
        SkeletonText(width: SkeletonTextWidth.quarter, height: 24),
        SizedBox(height: AppSizes.spacingXs),
        SkeletonText(width: SkeletonTextWidth.quarter, height: 14),
      ],
    );
  }

  /// Builds error state for stats card.
  Widget _buildStatsError(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacingLg),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: context.colorScheme.error,
            ),
            const SizedBox(height: AppSizes.spacingMd),
            Text(
              'Failed to load statistics',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
