import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/actor.dart';
import '../models/auth_exception.dart';
import '../models/auth_response.dart';

/// API Client communicating with the OnDemand Plodyo authentication endpoints.
class AuthApiService {
  AuthApiService({
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Map<String, String> _buildHeaders({String? clientSecret, String? accessToken}) {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };

    final secret = clientSecret ?? ApiConstants.clientSecret;
    if (secret.isNotEmpty) {
      headers['x-client-secret'] = secret;
    }

    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    return headers;
  }

  /// POST /ondemand/auth/login
  Future<AuthResponse> login({
    required String email,
    required String password,
    String? clientSecret,
  }) async {
    final uri = Uri.parse('${ApiConstants.effectiveBaseUrl}${ApiConstants.loginEndpoint}');
    final headers = _buildHeaders(clientSecret: clientSecret);
    final body = jsonEncode({
      'email': email,
      'password': password,
    });

    try {
      final response = await _httpClient
          .post(uri, headers: headers, body: body)
          .timeout(ApiConstants.connectTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthResponse.fromJson(data);
      } else {
        throw AuthException.fromResponseBody(response.body, response.statusCode);
      }
    } on SocketException catch (_) {
      throw AuthException.network('Cannot reach Plodyo. Check the network connection.');
    } on TimeoutException catch (_) {
      throw AuthException.network('Connection timed out. Plodyo server took too long to respond.');
    } on http.ClientException catch (e) {
      throw AuthException.network('Network request failed: ${e.message}');
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(
        message: 'An unexpected error occurred during sign in.',
        error: e.toString(),
      );
    }
  }

  /// POST /ondemand/auth/refresh
  Future<AuthResponse> refreshToken({
    required String refreshToken,
    String? clientSecret,
  }) async {
    final uri = Uri.parse('${ApiConstants.effectiveBaseUrl}${ApiConstants.refreshEndpoint}');
    final headers = _buildHeaders(clientSecret: clientSecret);
    final body = jsonEncode({'refresh_token': refreshToken});

    try {
      final response = await _httpClient
          .post(uri, headers: headers, body: body)
          .timeout(ApiConstants.connectTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthResponse.fromJson(data);
      } else {
        throw AuthException.fromResponseBody(response.body, response.statusCode);
      }
    } on SocketException {
      throw AuthException.network();
    } on TimeoutException {
      throw AuthException.network('Connection timed out.');
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(message: 'Failed to refresh token.', error: e.toString());
    }
  }

  /// POST /ondemand/auth/logout
  Future<String> logout({
    required String refreshToken,
    String? clientSecret,
  }) async {
    final uri = Uri.parse('${ApiConstants.effectiveBaseUrl}${ApiConstants.logoutEndpoint}');
    final headers = _buildHeaders(clientSecret: clientSecret);
    final body = jsonEncode({'refresh_token': refreshToken});

    try {
      final response = await _httpClient
          .post(uri, headers: headers, body: body)
          .timeout(ApiConstants.connectTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['message'] as String? ?? 'Signed out.';
      } else {
        throw AuthException.fromResponseBody(response.body, response.statusCode);
      }
    } catch (_) {
      // Logout always succeeds from client perspective
      return 'Signed out.';
    }
  }

  /// GET /ondemand/auth/me
  Future<Actor> getMe({
    required String accessToken,
    String? clientSecret,
  }) async {
    final uri = Uri.parse('${ApiConstants.effectiveBaseUrl}${ApiConstants.meEndpoint}');
    final headers = _buildHeaders(clientSecret: clientSecret, accessToken: accessToken);

    try {
      final response = await _httpClient
          .get(uri, headers: headers)
          .timeout(ApiConstants.connectTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Actor.fromJson((data['actor'] as Map<String, dynamic>?) ?? {});
      } else {
        throw AuthException.fromResponseBody(response.body, response.statusCode);
      }
    } on SocketException {
      throw AuthException.network();
    } on TimeoutException {
      throw AuthException.network('Connection timed out.');
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(message: 'Failed to fetch user profile.', error: e.toString());
    }
  }
}
