/// API configuration and route endpoints for the OnDemand Plodyo service.
class ApiConstants {
  ApiConstants._();

  /// Base URL for the OnDemand backend.
  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    return 'https://plodyo-backend-nestjs-staging.up.railway.app';
  }

  /// Custom override base URL if set at runtime.
  static String? customBaseUrl;

  /// Effective base URL.
  static String get effectiveBaseUrl => customBaseUrl ?? baseUrl;

  /// Global secret key header if connecting from non-browser clients (e.g. Flutter TV / macOS / Windows desktop).
  static String clientSecret = '';

  /// Default Origin header for CORS/origin-checked backend endpoints.
  static String defaultOrigin = 'http://localhost:3000';

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
  static const String adminRoomsBulkEndpoint = '/ondemand/admin/rooms/bulk';

  // Admin People / Users Routes
  static const String adminPeopleEndpoint = '/ondemand/admin/users';
  static const String adminUsersEndpoint = '/ondemand/admin/users';

  // Device TV Routes (Room TV Flow)
  static const String devicePairEndpoint = '/ondemand/device/pair';
  static const String deviceSessionEndpoint = '/ondemand/device/session';
  static const String deviceConfigEndpoint = '/ondemand/device/config';
  static const String deviceContentEndpoint = '/ondemand/device/content';

  // Request Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
