import 'package:fitgenie_app/core/constants/app_sizes.dart';
import 'package:fitgenie_app/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Subtle persistent banner indicating offline mode.
///
/// This widget displays a non-intrusive banner at the top of screens when
/// the app is offline, following the UX "offline equality" principle. It
/// informs users about their connectivity state without blocking interactions
/// or creating alarm.
///
/// Features:
/// - Auto-shows when connectivity lost
/// - Auto-hides when connectivity restored
/// - Smooth fade animation on show/hide
/// - Subtle styling (informative, not alarming)
/// - Non-blocking (doesn't prevent interactions)
/// - Reads connectivity state from provider
///
/// Usage:
/// ```dart
/// Scaffold(
///   body: Column(
///     children: [
///       OfflineBanner(),
///       Expanded(child: YourContent()),
///     ],
///   ),
/// )
/// ```
///
/// Design Philosophy:
/// Per UX spec, offline users are first-class citizens. The banner provides
/// awareness without panic. Message tone: "You're offline — showing saved plan"
/// rather than "ERROR: No connection!"
///
/// Note: This widget requires [connectivityProvider] to be available in the
/// Riverpod provider scope. It will be implemented in the providers file.
class OfflineBanner extends ConsumerWidget {
  /// Optional custom message to display when offline.
  ///
  /// Defaults to "You're offline — showing saved plan".
  final String? customMessage;

  /// Creates an [OfflineBanner] that automatically shows/hides based on
  /// connectivity state.
  const OfflineBanner({super.key, this.customMessage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Note: The actual provider implementation will be in connectivity_provider.dart
    // For now, we'll define the interface this widget expects

    // This would be: final isOnline = ref.watch(isOnlineProvider);
    // We'll add a comment for now since the provider file comes next

    // TODO: Uncomment when connectivity_provider.dart is created
    // final isOnline = ref.watch(isOnlineProvider);

    // Temporary fallback - always show for demonstration
    // This will be replaced when provider is available
    final isOnline = true; // Change to ref.watch(isOnlineProvider) later

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: isOnline
          ? const SizedBox.shrink() // Hidden when online
          : _OfflineBannerContent(
              key: const ValueKey('offline_banner'),
              message: customMessage,
            ),
    );
  }
}

/// Internal widget containing the banner visual elements.
///
/// Separated for better organization and to provide a unique key
/// for [AnimatedSwitcher] to properly animate transitions.
class _OfflineBannerContent extends StatelessWidget {
  final String? message;

  const _OfflineBannerContent({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final displayMessage = message ?? "You're offline — showing saved plan";

    return Material(
      color: context.colorScheme.surfaceContainerHighest,
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacingMd,
          vertical: AppSizes.spacingSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 16,
              color: context.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSizes.spacingSm),
            Flexible(
              child: Text(
                displayMessage,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
