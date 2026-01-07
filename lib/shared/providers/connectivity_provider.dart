import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

/// Riverpod provider monitoring network connectivity state for offline-first architecture.
///
/// This provider uses the connectivity_plus package to monitor real-time network
/// connectivity changes and expose them as a reactive stream. It enables the app
/// to make intelligent decisions about when to sync data, show offline indicators,
/// and queue operations for later execution.
///
/// Features:
/// - Real-time connectivity state streaming
/// - Derived boolean provider for simple online/offline checks
/// - Automatic updates when network state changes
/// - Works across iOS, Android, and Web platforms
/// - Initial connectivity check on provider initialization
///
/// Usage:
/// ```dart
/// // Watch connectivity state
/// final connectivity = ref.watch(connectivityProvider);
/// connectivity.when(
///   data: (result) => Text('Connected: ${result != ConnectivityResult.none}'),
///   loading: () => CircularProgressIndicator(),
///   error: (e, st) => Text('Error checking connectivity'),
/// );
///
/// // Simple boolean check
/// final isOnline = ref.watch(isOnlineProvider);
/// if (isOnline) {
///   // Perform network operation
/// }
/// ```
///
/// Architecture Integration:
/// - Used by repositories to decide local vs remote operations
/// - Triggers sync service when transitioning to online state
/// - Powers [OfflineBanner] widget visibility
/// - Informs error handling (network vs other errors)
///
/// Implementation Notes:
/// - Uses Riverpod code generation (@riverpod annotation)
/// - Generates connectivity_provider.g.dart via build_runner
/// - StreamProvider automatically disposes stream subscription
/// - Provider is auto-dispose to clean up when not in use

/// Streams the current connectivity state.
///
/// Returns a [Stream<ConnectivityResult>] that emits whenever the device's
/// network connectivity changes. Possible values:
/// - [ConnectivityResult.wifi]: Connected via WiFi
/// - [ConnectivityResult.mobile]: Connected via cellular data
/// - [ConnectivityResult.ethernet]: Connected via Ethernet (rare on mobile)
/// - [ConnectivityResult.bluetooth]: Connected via Bluetooth
/// - [ConnectivityResult.vpn]: Connected via VPN
/// - [ConnectivityResult.none]: No connectivity
///
/// The stream is kept alive as long as there are active listeners.
@riverpod
Stream<ConnectivityResult> connectivity(ConnectivityRef ref) {
  // Create instance of Connectivity
  final connectivity = Connectivity();

  // Return the stream of connectivity changes
  // This will automatically dispose the stream subscription when provider is disposed
  return connectivity.onConnectivityChanged;
}

/// Provides a simple boolean indicating whether the device is online.
///
/// This is a derived provider that watches [connectivityProvider] and returns
/// true if there is any active network connection, false otherwise.
///
/// Usage:
/// ```dart
/// final isOnline = ref.watch(isOnlineProvider);
///
/// if (isOnline) {
///   await syncData();
/// } else {
///   showOfflineMessage();
/// }
/// ```
///
/// This provider is useful for:
/// - Showing/hiding offline banners
/// - Enabling/disabling sync operations
/// - Conditional UI rendering based on connectivity
/// - Quick connectivity checks without pattern matching
@riverpod
bool isOnline(IsOnlineRef ref) {
  // Watch the connectivity stream
  final connectivityAsync = ref.watch(connectivityProvider);

  // Return true if connected, false if no connection or loading/error
  return connectivityAsync.maybeWhen(
    data: (result) => result != ConnectivityResult.none,
    orElse: () => false, // Assume offline during loading or error states
  );
}

/// Provides the current connectivity result synchronously.
///
/// Returns null if connectivity state is still loading or if there was an error.
/// This is useful when you need immediate access to the connectivity state
/// without watching for updates.
///
/// Usage:
/// ```dart
/// final connectivity = ref.read(currentConnectivityProvider);
/// if (connectivity == ConnectivityResult.wifi) {
///   // Perform WiFi-specific operation
/// }
/// ```
@riverpod
ConnectivityResult? currentConnectivity(CurrentConnectivityRef ref) {
  final connectivityAsync = ref.watch(connectivityProvider);
  return connectivityAsync.valueOrNull;
}
