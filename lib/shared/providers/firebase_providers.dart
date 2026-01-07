import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_providers.g.dart';

/// Riverpod providers exposing Firebase service instances for dependency injection.
///
/// This file provides singleton instances of Firebase services (Auth, Firestore)
/// through Riverpod providers, enabling clean dependency injection throughout
/// the app. It also provides derived providers for auth state and current user.
///
/// Features:
/// - Singleton Firebase service instances
/// - Reactive auth state streaming
/// - Current user and user ID providers
/// - Type-safe dependency injection
/// - Automatic stream management and disposal
///
/// Usage in repositories:
/// ```dart
/// @riverpod
/// class AuthRepository {
///   AuthRepository(this.ref);
///   final Ref ref;
///
///   FirebaseAuth get _auth => ref.read(firebaseAuthProvider);
///
///   Future<void> signIn(String email, String password) async {
///     await _auth.signInWithEmailAndPassword(email: email, password: password);
///   }
/// }
/// ```
///
/// Usage in UI for auth state:
/// ```dart
/// final user = ref.watch(currentUserProvider);
/// user.when(
///   data: (user) => user != null ? HomeScreen() : LoginScreen(),
///   loading: () => LoadingScreen(),
///   error: (e, st) => ErrorScreen(),
/// );
/// ```
///
/// Architecture Notes:
/// - Providers must be initialized after Firebase.initializeApp() in main()
/// - FirebaseAuth and Firestore use singleton pattern internally
/// - StreamProviders auto-dispose when no longer watched
/// - Used by all feature repositories for Firebase access

/// Provides the [FirebaseAuth] singleton instance.
///
/// This provider exposes the Firebase Authentication service for dependency
/// injection into repositories and other providers. It should be used via
/// `ref.read()` in repositories to access auth methods.
///
/// Usage:
/// ```dart
/// final auth = ref.read(firebaseAuthProvider);
/// await auth.signInWithEmailAndPassword(email: email, password: password);
/// ```
///
/// All authentication operations should go through this provider rather than
/// directly accessing FirebaseAuth.instance to enable testability and
/// proper dependency management.
@Riverpod(keepAlive: true)
FirebaseAuth firebaseAuth(FirebaseAuthRef ref) {
  return FirebaseAuth.instance;
}

/// Provides the [FirebaseFirestore] singleton instance.
///
/// This provider exposes the Cloud Firestore database service for dependency
/// injection into repositories. It should be used via `ref.read()` to access
/// Firestore collections and documents.
///
/// Usage:
/// ```dart
/// final firestore = ref.read(firestoreProvider);
/// final docRef = firestore.collection('users').doc(userId);
/// await docRef.set(data);
/// ```
///
/// All Firestore operations should go through this provider for proper
/// dependency injection and testability.
@Riverpod(keepAlive: true)
FirebaseFirestore firestore(FirestoreRef ref) {
  return FirebaseFirestore.instance;
}

/// Streams the current authenticated user.
///
/// This provider listens to [FirebaseAuth.authStateChanges] and emits the
/// current [User] object whenever authentication state changes. It returns
/// null when no user is signed in.
///
/// Auth state changes include:
/// - User signs in
/// - User signs out
/// - User's token is refreshed
/// - User's profile is updated
///
/// Usage:
/// ```dart
/// final userAsync = ref.watch(currentUserProvider);
/// userAsync.when(
///   data: (user) {
///     if (user != null) {
///       return Text('Welcome ${user.email}');
///     } else {
///       return Text('Please sign in');
///     }
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (e, st) => Text('Auth error'),
/// );
/// ```
///
/// This provider is essential for:
/// - Route guards (redirect if not authenticated)
/// - Conditional UI rendering based on auth state
/// - Triggering side effects on auth changes
/// - Repository operations requiring user ID
@riverpod
Stream<User?> currentUser(CurrentUserRef ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
}

/// Provides the current user's ID as a nullable string.
///
/// This is a derived provider that extracts the user ID from [currentUserProvider].
/// It returns null if no user is signed in or if the auth state is loading.
///
/// Usage:
/// ```dart
/// final userId = ref.watch(currentUserIdProvider);
/// if (userId != null) {
///   final userDoc = firestore.collection('users').doc(userId);
///   // ... perform user-specific operations
/// }
/// ```
///
/// This provider is useful for:
/// - Quick user ID access in repositories
/// - Firestore document path construction
/// - User-scoped data operations
/// - Conditional logic based on authentication
@riverpod
String? currentUserId(CurrentUserIdRef ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.valueOrNull?.uid;
}

/// Provides a boolean indicating whether a user is currently authenticated.
///
/// This is a convenience provider that returns true if a user is signed in,
/// false otherwise. During loading or error states, it returns false.
///
/// Usage:
/// ```dart
/// final isAuthenticated = ref.watch(isAuthenticatedProvider);
///
/// if (isAuthenticated) {
///   // Show authenticated content
/// } else {
///   // Show login screen
/// }
/// ```
///
/// This provider is useful for:
/// - Simple authentication checks
/// - Conditional UI rendering
/// - Route guard logic
/// - Feature flag based on auth status
@riverpod
bool isAuthenticated(IsAuthenticatedRef ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.maybeWhen(data: (user) => user != null, orElse: () => false);
}

/// Provides the current user's email address.
///
/// Returns null if no user is signed in or if the user doesn't have an email.
///
/// Usage:
/// ```dart
/// final email = ref.watch(currentUserEmailProvider);
/// if (email != null) {
///   Text('Logged in as: $email');
/// }
/// ```
@riverpod
String? currentUserEmail(CurrentUserEmailRef ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.valueOrNull?.email;
}
