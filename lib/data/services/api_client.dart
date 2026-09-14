import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/auth_exception.dart';

/// Central HTTP API Client handling headers, bearer tokens, client-secrets, and standard error handling.
class ApiClient {
  ApiClient({
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Map<String, String> buildHeaders({
    String? accessToken,
    String? deviceToken,
    String? clientSecret,
    String? origin,
  }) {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };

    if (deviceToken != null && deviceToken.isNotEmpty) {
      // Room TVs authenticate with X-Device-Token and never require x-client-secret
      headers['X-Device-Token'] = deviceToken;
      return headers;
    }

    final secret = clientSecret ?? ApiConstants.clientSecret;
    if (secret.isNotEmpty) {
      headers['x-client-secret'] = secret;
    } else {
      headers['Origin'] = origin ?? ApiConstants.defaultOrigin;
    }

    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    return headers;
  }

  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParameters,
    String? accessToken,
    String? deviceToken,
    String? clientSecret,
  }) async {
    var uri = Uri.parse('${ApiConstants.effectiveBaseUrl}$endpoint');
    if (queryParameters != null && queryParameters.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParameters);
    }

    final headers = buildHeaders(
      accessToken: accessToken,
      deviceToken: deviceToken,
      clientSecret: clientSecret,
    );

    try {
      final response = await _httpClient
          .get(uri, headers: headers)
          .timeout(ApiConstants.connectTimeout);
      return _handleResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    String? accessToken,
    String? deviceToken,
    String? clientSecret,
  }) async {
    final uri = Uri.parse('${ApiConstants.effectiveBaseUrl}$endpoint');
    final headers = buildHeaders(
      accessToken: accessToken,
      deviceToken: deviceToken,
      clientSecret: clientSecret,
    );
    final encodedBody = body != null ? jsonEncode(body) : null;

    try {
      final response = await _httpClient
          .post(uri, headers: headers, body: encodedBody)
          .timeout(ApiConstants.connectTimeout);
      return _handleResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> patch(
    String endpoint, {
    dynamic body,
    String? accessToken,
    String? deviceToken,
    String? clientSecret,
  }) async {
    final uri = Uri.parse('${ApiConstants.effectiveBaseUrl}$endpoint');
    final headers = buildHeaders(
      accessToken: accessToken,
      deviceToken: deviceToken,
      clientSecret: clientSecret,
    );
    final encodedBody = body != null ? jsonEncode(body) : null;

    try {
      final response = await _httpClient
          .patch(uri, headers: headers, body: encodedBody)
          .timeout(ApiConstants.connectTimeout);
      return _handleResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> delete(
    String endpoint, {
    dynamic body,
    String? accessToken,
    String? deviceToken,
    String? clientSecret,
  }) async {
    final uri = Uri.parse('${ApiConstants.effectiveBaseUrl}$endpoint');
    final headers = buildHeaders(
      accessToken: accessToken,
      deviceToken: deviceToken,
      clientSecret: clientSecret,
    );
    final encodedBody = body != null ? jsonEncode(body) : null;

    try {
      final response = await _httpClient
          .delete(uri, headers: headers, body: encodedBody)
          .timeout(ApiConstants.connectTimeout);
      return _handleResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      throw AuthException.fromResponseBody(response.body, response.statusCode);
    }
  }

  Never _handleError(Object error) {
    if (error is AuthException) {
      throw error;
    } else if (error is SocketException) {
      throw AuthException.network('Cannot reach Plodyo TV. Check your network or local server.');
    } else if (error is TimeoutException) {
      throw AuthException.network('Request timed out. Plodyo TV server took too long to respond.');
    } else if (error is http.ClientException) {
      throw AuthException.network('Network request failed: ${error.message}');
    } else {
      throw AuthException(
        message: 'An unexpected error occurred.',
        error: error.toString(),
      );
    }
  }
}
