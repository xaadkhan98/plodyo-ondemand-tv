import 'package:flutter/foundation.dart';

/// API configuration and route endpoints for the OnDemand Plodyo service.
class ApiConstants {
  ApiConstants._();

  /// Base URL for the OnDemand backend.
  /// Defaults to `http://localhost:5001` or `http://10.0.2.2:5001` for Android emulator.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5001';
    }
    // If running on Android emulator, localhost is mapped to 10.0.2.2
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5001';
    }
    return 'http://localhost:5001';
  }

  /// Custom override base URL if set at runtime.
  static String? customBaseUrl;

  /// Effective base URL.
  static String get effectiveBaseUrl => customBaseUrl ?? baseUrl;

  /// Global secret key header if connecting from non-browser clients (e.g., Flutter TV).
  static String clientSecret = '';

  // Auth Routes (All OnDemand routes sit under /ondemand)
  static const String loginEndpoint = '/ondemand/auth/login';
  static const String refreshEndpoint = '/ondemand/auth/refresh';
  static const String logoutEndpoint = '/ondemand/auth/logout';
  static const String forgotPasswordEndpoint = '/ondemand/auth/forgot-password';
  static const String resetPasswordEndpoint = '/ondemand/auth/reset-password';
  static const String meEndpoint = '/ondemand/auth/me';

  // Request Timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
