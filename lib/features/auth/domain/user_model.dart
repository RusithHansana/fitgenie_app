import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// Immutable data class representing an authenticated user.
///
/// This model wraps Firebase Auth user data with additional application-specific
/// fields. It provides type-safe access to user information and supports
/// serialization for caching and API communication.
///
/// Generated files:
/// - `user_model.freezed.dart` - Freezed generated code (copyWith, equality, etc.)
/// - `user_model.g.dart` - JSON serialization code
///
/// Run `flutter pub run build_runner build` to generate these files after changes.
///
/// Usage:
/// ```dart
/// // From Firebase User
/// final user = UserModel.fromFirebaseUser(firebaseUser);
///
/// // From JSON (Firestore document)
/// final user = UserModel.fromJson(firestoreDoc.data()!);
///
/// // Copy with changes
/// final updated = user.copyWith(isOnboardingComplete: true);
/// ```
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    /// Firebase Authentication user ID (UID)
    required String uid,

    /// User's email address
    required String email,

    /// Timestamp when the account was created
    required DateTime createdAt,

    /// Whether the user has completed the onboarding flow
    @Default(false) bool isOnboardingComplete,

    /// Optional display name (for future use)
    String? displayName,

    /// Optional profile photo URL (for future use)
    String? photoUrl,
  }) = _UserModel;

  /// Creates a UserModel from a Firebase User object.
  ///
  /// This factory converts the Firebase Auth user to our domain model,
  /// extracting relevant fields. Note that [isOnboardingComplete] defaults
  /// to false and must be loaded from Firestore separately.
  ///
  /// Parameters:
  /// - [user]: Firebase User object from authentication
  /// - [isOnboardingComplete]: Optional override for onboarding status
  factory UserModel.fromFirebaseUser(
    firebase_auth.User user, {
    bool? isOnboardingComplete,
  }) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      isOnboardingComplete: isOnboardingComplete ?? false,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  /// Creates a UserModel from a JSON map (Firestore document).
  ///
  /// Used for deserializing user data from Firestore or local cache.
  /// The JSON map should contain all required fields.
  ///
  /// Throws [CheckedFromJsonException] if required fields are missing
  /// or have incorrect types.
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

/// Extension methods for UserModel providing additional utilities.
extension UserModelExtensions on UserModel {
  /// Converts UserModel to a Firestore-compatible map.
  ///
  /// This includes all fields needed for the user document in Firestore.
  /// Timestamps are converted to ISO 8601 strings for Firestore compatibility.
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'isOnboardingComplete': isOnboardingComplete,
      if (displayName != null) 'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }

  /// Returns the user's display name or email if display name is not set.
  String get displayNameOrEmail => displayName ?? email;

  /// Returns the first part of the email (before @) as a fallback username.
  String get username => email.split('@').first;

  /// Returns true if the user has a custom display name set.
  bool get hasDisplayName => displayName != null && displayName!.isNotEmpty;

  /// Returns true if the user has a profile photo.
  bool get hasProfilePhoto => photoUrl != null && photoUrl!.isNotEmpty;
}
