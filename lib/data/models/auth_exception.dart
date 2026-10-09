import 'dart:convert';

/// Represents an API or network error encountered during authentication.
class AuthException implements Exception {
  const AuthException({
    required this.message,
    this.statusCode,
    this.error,
    this.validationErrors = const [],
  });

  final String message;
  final int? statusCode;
  final String? error;
  final List<String> validationErrors;

  /// Check if the exception was caused by a connection or network failure.
  bool get isNetworkError => statusCode == 0 || error == 'NetworkError';

  /// Factory to parse NestJS error responses.
  factory AuthException.fromResponseBody(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final rawMsg = decoded['message'];
        final err = decoded['error'] as String?;
        final code = (decoded['statusCode'] as int?) ?? statusCode;

        if (rawMsg is List) {
          final errors = rawMsg.map((e) => e.toString()).toList();
          return AuthException(
            message: errors.join('\n'),
            statusCode: code,
            error: err,
            validationErrors: errors,
          );
        } else if (rawMsg is String) {
          return AuthException(message: rawMsg, statusCode: code, error: err);
        }
      }
    } catch (_) {
      // If body is not JSON or parsing fails
    }

    return AuthException(
      message: _defaultMessageForStatus(statusCode),
      statusCode: statusCode,
    );
  }

  /// Network or unexpected exception helper.
  factory AuthException.network([String? details]) {
    return AuthException(
      message:
          details ?? 'Cannot reach Plodyo TV. Check the network connection.',
      statusCode: 0,
      error: 'NetworkError',
    );
  }

  static String _defaultMessageForStatus(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request data.';
      case 401:
        return 'Invalid credentials';
      case 403:
        return 'Access denied. Your role is not permitted.';
      case 429:
        return 'Too many attempts. Please wait a moment and try again.';
      case 500:
      case 502:
      case 503:
        return 'Plodyo TV service is temporarily unavailable. Please try again later.';
      default:
        return 'An unexpected error occurred ($statusCode).';
    }
  }

  @override
  String toString() => message;
}

/// The API's own message for [error], or [fallback] for anything that is not an API error.
String messageOf(Object error, String fallback) =>
    error is AuthException ? error.message : fallback;
