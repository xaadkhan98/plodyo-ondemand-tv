import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/auth_exception.dart';

/// Central HTTP API Client handling headers, bearer tokens, client-secrets, and standard error handling.
class ApiClient {
  ApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

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

  /// Renews the console's access token after a 401, or throws once the session is over. Wired by main to the
  /// auth repository, and shared by every client: a refresh token is single use.
  static Future<String> Function()? renewBearer;

  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParameters,
    String? accessToken,
    String? deviceToken,
    String? clientSecret,
  }) {
    var uri = _uri(endpoint);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParameters);
    }
    return _send(
      (headers) => _httpClient.get(uri, headers: headers),
      accessToken: accessToken,
      deviceToken: deviceToken,
      clientSecret: clientSecret,
    );
  }

  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    String? accessToken,
    String? deviceToken,
    String? clientSecret,
  }) => _send(
    (headers) =>
        _httpClient.post(_uri(endpoint), headers: headers, body: _encode(body)),
    accessToken: accessToken,
    deviceToken: deviceToken,
    clientSecret: clientSecret,
  );

  Future<dynamic> patch(
    String endpoint, {
    dynamic body,
    String? accessToken,
    String? deviceToken,
    String? clientSecret,
  }) => _send(
    (headers) => _httpClient.patch(
      _uri(endpoint),
      headers: headers,
      body: _encode(body),
    ),
    accessToken: accessToken,
    deviceToken: deviceToken,
    clientSecret: clientSecret,
  );

  Future<dynamic> delete(
    String endpoint, {
    dynamic body,
    String? accessToken,
    String? deviceToken,
    String? clientSecret,
  }) => _send(
    (headers) => _httpClient.delete(
      _uri(endpoint),
      headers: headers,
      body: _encode(body),
    ),
    accessToken: accessToken,
    deviceToken: deviceToken,
    clientSecret: clientSecret,
  );

  Uri _uri(String endpoint) =>
      Uri.parse('${ApiConstants.effectiveBaseUrl}$endpoint');

  String? _encode(dynamic body) => body != null ? jsonEncode(body) : null;

  Future<dynamic> _send(
    Future<http.Response> Function(Map<String, String> headers) request, {
    String? accessToken,
    String? deviceToken,
    String? clientSecret,
  }) async {
    Future<http.Response> attempt(String? bearer) => request(
      buildHeaders(
        accessToken: bearer,
        deviceToken: deviceToken,
        clientSecret: clientSecret,
      ),
    ).timeout(ApiConstants.connectTimeout);

    try {
      var response = await attempt(accessToken);
      // Once, and only for a bearer: a 403 is a role refusal, and a device token neither expires nor renews.
      final renew = renewBearer;
      if (response.statusCode == 401 &&
          renew != null &&
          (accessToken?.isNotEmpty ?? false)) {
        response = await attempt(await renew());
      }
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
      throw AuthException.network(
        'Cannot reach Plodyo TV. Check your network or local server.',
      );
    } else if (error is TimeoutException) {
      throw AuthException.network(
        'Request timed out. Plodyo TV server took too long to respond.',
      );
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
