import 'package:flutter/foundation.dart';

/// API configuration and route endpoints for the OnDemand Plodyo service.
class ApiConstants {
  ApiConstants._();

  /// Base URL for the OnDemand backend.
  /// Defaults to `http://localhost:3000` or `http://10.0.2.2:3000` for Android emulator.
  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    // If running on Android emulator, localhost is mapped to 10.0.2.2
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  /// Custom override base URL if set at runtime.
  static String? customBaseUrl;

  /// Effective base URL.
  static String get effectiveBaseUrl => customBaseUrl ?? baseUrl;

  /// Global secret key header if connecting from non-browser clients (e.g. Flutter TV / macOS / Windows desktop).
  static String clientSecret = '';

  // Auth Routes
  static const String loginEndpoint = '/ondemand/auth/login';
  static const String refreshEndpoint = '/ondemand/auth/refresh';
  static const String logoutEndpoint = '/ondemand/auth/logout';
  static const String forgotPasswordEndpoint = '/ondemand/auth/forgot-password';
  static const String resetPasswordEndpoint = '/ondemand/auth/reset-password';
  static const String meEndpoint = '/ondemand/auth/me';

  // Public Routes
  static const String publicInvitePreviewEndpoint = '/ondemand/public/invites'; // /:token
  static const String publicRegistrationsEndpoint = '/ondemand/public/registrations';

  // Admin Invites Routes
  static const String adminInvitesEndpoint = '/ondemand/admin/invites';

  // Admin Partners Routes
  static const String adminPartnersEndpoint = '/ondemand/admin/partners';

  // Admin Properties Routes
  static const String adminPropertiesEndpoint = '/ondemand/admin/properties';

  // Admin Rooms Routes
  static const String adminRoomsEndpoint = '/ondemand/admin/rooms';

  // Request Timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
