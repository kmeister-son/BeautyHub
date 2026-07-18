import '../entities/user_profile.dart';

/// Identity for the current install. There is always a user: a guest is
/// provisioned on first use, and [signIn]/[signUp] replace it with a real
/// account. Bookings always belong to whoever is current.
abstract class AuthRepository {
  Future<UserProfile> getCurrentUser();

  Future<UserProfile> signIn({required String email, required String password});

  Future<UserProfile> signUp({
    required String name,
    required String email,
    required String password,
  });

  /// Drops the stored credentials; the next use provisions a fresh guest.
  Future<void> signOut();

  /// Requests a one-time reset code for [email]. Always succeeds, whether
  /// or not an account exists (no account probing).
  Future<void> requestPasswordReset(String email);

  /// Sets a new password using the emailed one-time [code].
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });
}
