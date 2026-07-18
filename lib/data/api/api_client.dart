import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/api_config.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thrown when a booking slot was taken between availability and confirm.
class ConflictException extends ApiException {
  ConflictException(String message) : super(409, message);
}

/// Thin JSON client. On the first authenticated call it lazily creates a
/// guest identity via POST /auth/guest and persists the JWT, so every install
/// owns its bookings without any sign-in UI.
class ApiClient {
  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  static const _tokenKey = 'beautyhub_guest_token';

  final http.Client _http;
  String? _token;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);

  Future<String> _ensureToken() async {
    if (_token case final token?) return token;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_tokenKey);
    if (saved != null) return _token = saved;
    return _refreshGuestToken(prefs);
  }

  /// Replaces the current identity with [token] (e.g. after login/register).
  Future<void> adoptToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Forgets the stored identity; the next authenticated call mints a
  /// fresh guest.
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<String> _refreshGuestToken(SharedPreferences prefs) async {
    final res = await _http.post(_uri('/auth/guest'));
    final body = _decode(res) as Map<String, dynamic>;
    final token = body['token'] as String;
    await prefs.setString(_tokenKey, token);
    return _token = token;
  }

  dynamic _decode(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.body.isEmpty ? null : jsonDecode(res.body);
    }
    String message = res.reasonPhrase ?? 'Request failed';
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['message'] != null) {
        final m = body['message'];
        message = m is List ? m.join(', ') : m.toString();
      }
    } on FormatException {
      // Non-JSON error body; keep the reason phrase.
    }
    if (res.statusCode == 409) throw ConflictException(message);
    throw ApiException(res.statusCode, message);
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    bool authenticated = false,
  }) =>
      _send('GET', path, query: query, authenticated: authenticated);

  Future<dynamic> post(
    String path, {
    Object? body,
    bool authenticated = true,
  }) =>
      _send('POST', path, body: body, authenticated: authenticated);

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    bool authenticated = false,
    bool isRetry = false,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authenticated) {
      headers['Authorization'] = 'Bearer ${await _ensureToken()}';
    }
    final uri = _uri(path, query);
    final res = method == 'GET'
        ? await _http.get(uri, headers: headers)
        : await _http.post(uri, headers: headers,
            body: body == null ? null : jsonEncode(body));

    // A stored token can go stale (e.g. dev database reset). Mint a fresh
    // guest identity once and replay the request.
    if (authenticated && res.statusCode == 401 && !isRetry) {
      _token = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      return _send(method, path,
          query: query, body: body, authenticated: true, isRetry: true);
    }
    return _decode(res);
  }
}
