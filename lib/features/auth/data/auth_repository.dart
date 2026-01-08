import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitgenie_app/features/auth/domain/user_model.dart';
import 'package:fitgenie_app/core/exceptions/auth_exception.dart';

/// Repository handling all Firebase Auth operations with typed exception handling.
///
/// This repository encapsulates Firebase Authentication operations and provides
/// a clean interface for authentication-related business logic. All Firebase errors
/// are transformed into typed [AuthException] instances with user-friendly messages.
///
/// The repository also manages the creation and deletion of associated Firestore
/// user documents to maintain consistency between Auth and Firestore data.
///
/// Usage:
/// ```dart
/// final authRepo = AuthRepository(
///   firebaseAuth: FirebaseAuth.instance,
///   firestore: FirebaseFirestore.instance,
/// );
///
/// try {
///   final user = await authRepo.signInWithEmail(
///     email: 'user@example.com',
///     password: 'password123',
///   );
///   print('Logged in: ${user.email}');
/// } on AuthException catch (e) {
///   print('Auth failed: ${e.message}');
/// }
/// ```
class AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  /// Users collection reference in Firestore
  static const String _usersCollection = 'users';

  AuthRepository({
    required firebase_auth.FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore;

  /// Stream of authentication state changes.
  ///
  /// Emits [UserModel] when user is authenticated, null when not authenticated.
  /// This stream is the single source of truth for auth state throughout the app.
  ///
  /// The stream automatically fetches the user's onboarding status from Firestore
  /// when a user signs in.
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      // Fetch additional user data from Firestore
      try {
        final userDoc = await _firestore
            .collection(_usersCollection)
            .doc(firebaseUser.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data()!;
          return UserModel.fromFirebaseUser(
            firebaseUser,
            isOnboardingComplete:
                data['isOnboardingComplete'] as bool? ?? false,
          );
        }
      } catch (e) {
        // If Firestore fetch fails, return basic user model
        // This prevents auth stream from breaking due to Firestore issues
      }

      return UserModel.fromFirebaseUser(firebaseUser);
    });
  }

  /// Signs in a user with email and password.
  ///
  /// Parameters:
  /// - [email]: User's email address
  /// - [password]: User's password
  ///
  /// Returns [UserModel] on successful authentication.
  ///
  /// Throws [AuthException] with specific error codes:
  /// - [AuthErrorCode.invalidEmail] - Email format is invalid
  /// - [AuthErrorCode.userNotFound] - No user exists with this email
  /// - [AuthErrorCode.wrongPassword] - Password is incorrect
  /// - [AuthErrorCode.userDisabled] - User account has been disabled
  /// - [AuthErrorCode.tooManyRequests] - Too many failed login attempts
  /// - [AuthErrorCode.networkError] - Network connection issue
  /// - [AuthErrorCode.unknown] - Other errors
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthException(
          AuthErrorType.unknown,
          'Sign in failed. Please try again.',
        );
      }

      // Fetch user document from Firestore
      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(firebaseUser.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        return UserModel.fromFirebaseUser(
          firebaseUser,
          isOnboardingComplete: data['isOnboardingComplete'] as bool? ?? false,
        );
      }

      // User document doesn't exist, return basic model
      return UserModel.fromFirebaseUser(firebaseUser);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseError(e);
    } catch (e) {
      throw AuthException(
        AuthErrorType.unknown,
        'An unexpected error occurred during sign in: ${e.toString()}',
      );
    }
  }

  /// Creates a new user account with email and password.
  ///
  /// This method creates both the Firebase Auth user and a corresponding
  /// Firestore user document with initial profile data.
  ///
  /// Parameters:
  /// - [email]: User's email address
  /// - [password]: User's password (minimum 8 characters)
  ///
  /// Returns [UserModel] representing the newly created user.
  ///
  /// Throws [AuthException] with specific error codes:
  /// - [AuthErrorCode.emailAlreadyInUse] - Email is already registered
  /// - [AuthErrorCode.invalidEmail] - Email format is invalid
  /// - [AuthErrorCode.weakPassword] - Password is too weak
  /// - [AuthErrorCode.networkError] - Network connection issue
  /// - [AuthErrorCode.unknown] - Other errors
  Future<UserModel> createAccount({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthException(
          AuthErrorType.unknown,
          'Account creation failed. Please try again.',
        );
      }

      // Create user model
      final userModel = UserModel.fromFirebaseUser(
        firebaseUser,
        isOnboardingComplete: false,
      );

      // Create Firestore user document
      await _firestore
          .collection(_usersCollection)
          .doc(firebaseUser.uid)
          .set(userModel.toFirestore());

      return userModel;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseError(e);
    } catch (e) {
      throw AuthException(
        AuthErrorType.unknown,
        'An unexpected error occurred during account creation: ${e.toString()}',
      );
    }
  }

  /// Signs out the currently authenticated user.
  ///
  /// This method clears the Firebase Auth session. Local data cleanup
  /// (Hive cache, etc.) should be handled by the calling code.
  ///
  /// Throws [AuthException] if sign out fails.
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw AuthException(
        AuthErrorType.unknown,
        'Failed to sign out. Please try again: ${e.toString()}',
      );
    }
  }

  /// Sends a password reset email to the specified email address.
  ///
  /// Firebase will send an email with a link to reset the password.
  /// This method succeeds even if the email is not registered (for security).
  ///
  /// Parameters:
  /// - [email]: Email address to send the reset link to
  ///
  /// Throws [AuthException] with specific error codes:
  /// - [AuthErrorCode.invalidEmail] - Email format is invalid
  /// - [AuthErrorCode.userNotFound] - No user exists with this email
  /// - [AuthErrorCode.networkError] - Network connection issue
  /// - [AuthErrorCode.unknown] - Other errors
  Future<void> resetPassword({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseError(e);
    } catch (e) {
      throw AuthException(
        AuthErrorType.unknown,
        'Failed to send password reset email: ${e.toString()}',
      );
    }
  }

  /// Deletes the currently authenticated user's account.
  ///
  /// This permanently deletes the Firebase Auth user and their Firestore
  /// user document. This action cannot be undone.
  ///
  /// Note: This operation requires recent authentication. If the user's
  /// session is too old, re-authentication will be required.
  ///
  /// Throws [AuthException] with specific error codes:
  /// - [AuthErrorCode.requiresRecentLogin] - User must re-authenticate first
  /// - [AuthErrorCode.noUser] - No user is currently signed in
  /// - [AuthErrorCode.unknown] - Other errors
  Future<void> deleteAccount() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw const AuthException(
          AuthErrorType.unknown,
          'No user is currently signed in.',
        );
      }

      final userId = currentUser.uid;

      // Delete Firestore user document first
      await _firestore.collection(_usersCollection).doc(userId).delete();

      // Delete Firebase Auth user
      await currentUser.delete();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseError(e);
    } catch (e) {
      throw AuthException(
        AuthErrorType.unknown,
        'Failed to delete account. Please try again: ${e.toString()}',
      );
    }
  }

  /// Returns the currently authenticated user, if any.
  ///
  /// Returns null if no user is signed in.
  /// Note: This does not include Firestore user data. Use [authStateChanges]
  /// stream for complete user data.
  UserModel? get currentUser {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    return UserModel.fromFirebaseUser(firebaseUser);
  }
}
