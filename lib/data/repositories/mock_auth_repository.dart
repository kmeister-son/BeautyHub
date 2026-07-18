import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

/// In-memory identity store. Starts as a guest; accepts any credentials
/// whose shapes are valid so widget tests can drive both flows offline.
class MockAuthRepository implements AuthRepository {
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
}
