import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../api/api_client.dart';
import '../api/api_mappers.dart';

/// [AuthRepository] backed by the beautyhub-api service. Login/register
/// hand their token to the [ApiClient] so every later call acts as the
/// new identity.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._client);

  final ApiClient _client;

  @override
  Future<UserProfile> getCurrentUser() async {
    // Authenticated: provisions the guest identity on first use.
    final json = await _client.get('/auth/me', authenticated: true)
        as Map<String, dynamic>;
    return ApiMappers.userProfile(json);
  }

  @override
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) =>
      _adopt('/auth/login', {'email': email, 'password': password});

  @override
  Future<UserProfile> signUp({
    required String name,
    required String email,
    required String password,
  }) =>
      _adopt('/auth/register',
          {'name': name, 'email': email, 'password': password});

  Future<UserProfile> _adopt(String path, Map<String, String> body) async {
    final json =
        await _client.post(path, body: body, authenticated: false)
            as Map<String, dynamic>;
    await _client.adoptToken(json['token'] as String);
    return ApiMappers.userProfile(json['user'] as Map<String, dynamic>);
  }

  @override
  Future<void> signOut() => _client.clearToken();

  @override
  Future<void> requestPasswordReset(String email) async {
    await _client.post('/auth/forgot-password',
        body: {'email': email}, authenticated: false);
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _client.post('/auth/reset-password',
        body: {'email': email, 'code': code, 'password': newPassword},
        authenticated: false);
  }
}
