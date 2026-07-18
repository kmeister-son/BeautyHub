import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../api/api_client.dart';

/// In-memory identity store. Starts as a guest; accepts any credentials
/// whose shapes are valid so widget tests can drive both flows offline.
/// The password-reset code is always [resetCode].
class MockAuthRepository implements AuthRepository {
  static const resetCode = '123456';
  static const _latency = Duration(milliseconds: 350);

  UserProfile _current = const UserProfile(
    id: 'user-guest',
    email: 'guest@guest.beautyhub.app',
    name: 'Guest',
    isGuest: true,
  );

  @override
  Future<UserProfile> getCurrentUser() async {
    await Future<void>.delayed(_latency);
    return _current;
  }

  @override
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(_latency);
    return _current = UserProfile(
      id: 'user-1',
      email: email,
      name: email.split('@').first,
      isGuest: false,
    );
  }

  @override
  Future<UserProfile> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(_latency);
    return _current = UserProfile(
      id: 'user-1',
      email: email,
      name: name,
      isGuest: false,
    );
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(_latency);
    _current = const UserProfile(
      id: 'user-guest',
      email: 'guest@guest.beautyhub.app',
      name: 'Guest',
      isGuest: true,
    );
  }

  @override
  Future<void> requestPasswordReset(String email) =>
      Future<void>.delayed(_latency);

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await Future<void>.delayed(_latency);
    if (code != resetCode) {
      throw ApiException(400, 'Invalid or expired code');
    }
  }
}
