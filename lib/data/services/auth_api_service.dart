import '../../core/constants/api_constants.dart';
import '../models/actor.dart';
import '../models/auth_response.dart';
import '../models/invite_model.dart';
import '../models/membership.dart';
import 'api_client.dart';

class AuthMeResponse {
  const AuthMeResponse({required this.actor, required this.memberships});

  final Actor actor;
  final List<Membership> memberships;

  factory AuthMeResponse.fromJson(Map<String, dynamic> json) {
    final rawMemberships = (json['memberships'] as List<dynamic>?) ?? [];
    return AuthMeResponse(
      actor: Actor.fromJson((json['actor'] as Map<String, dynamic>?) ?? {}),
      memberships: rawMemberships
          .whereType<Map<String, dynamic>>()
          .map((m) => Membership.fromJson(m))
          .toList(),
    );
  }
}

/// Service communicating with OnDemand Plodyo Authentication & Public Registration/Invite endpoints.
class AuthApiService {
  AuthApiService({ApiClient? apiClient}) : _client = apiClient ?? ApiClient();

  final ApiClient _client;

  /// POST /ondemand/auth/login
  Future<AuthResponse> login({
    required String email,
    required String password,
    String? clientSecret,
  }) async {
    final res = await _client.post(
      ApiConstants.loginEndpoint,
      body: {'email': email.trim(), 'password': password},
      clientSecret: clientSecret,
    );
    return AuthResponse.fromJson(res as Map<String, dynamic>);
  }

  /// POST /ondemand/auth/refresh
  Future<AuthResponse> refreshToken({
    required String refreshToken,
    String? clientSecret,
  }) async {
    final res = await _client.post(
      ApiConstants.refreshEndpoint,
      body: {'refresh_token': refreshToken},
      clientSecret: clientSecret,
    );
    return AuthResponse.fromJson(res as Map<String, dynamic>);
  }

  /// POST /ondemand/auth/logout
  Future<String> logout({
    required String refreshToken,
    String? clientSecret,
  }) async {
    try {
      final res = await _client.post(
        ApiConstants.logoutEndpoint,
        body: {'refresh_token': refreshToken},
        clientSecret: clientSecret,
      );
      if (res is Map<String, dynamic>) {
        return res['message'] as String? ?? 'Signed out.';
      }
      return 'Signed out.';
    } catch (_) {
      return 'Signed out.';
    }
  }

  /// POST /ondemand/auth/forgot-password
  Future<String> forgotPassword({
    required String email,
    String? clientSecret,
  }) async {
    final res = await _client.post(
      ApiConstants.forgotPasswordEndpoint,
      body: {'email': email},
      clientSecret: clientSecret,
    );
    final map = res as Map<String, dynamic>?;
    return map?['message'] as String? ??
        'If that email is registered, a reset link has been sent.';
  }

  /// POST /ondemand/auth/reset-password
  Future<String> resetPassword({
    required String token,
    required String password,
    String? clientSecret,
  }) async {
    final res = await _client.post(
      ApiConstants.resetPasswordEndpoint,
      body: {'token': token, 'password': password},
      clientSecret: clientSecret,
    );
    final map = res as Map<String, dynamic>?;
    return map?['message'] as String? ?? 'Password updated.';
  }

  /// GET /ondemand/auth/me
  Future<AuthMeResponse> getMe({
    required String accessToken,
    String? clientSecret,
  }) async {
    final res = await _client.get(
      ApiConstants.meEndpoint,
      accessToken: accessToken,
      clientSecret: clientSecret,
    );
    return AuthMeResponse.fromJson(res as Map<String, dynamic>);
  }

  /// GET /ondemand/public/invites/:token
  Future<InviteModel> previewInvite({
    required String token,
    String? clientSecret,
  }) async {
    final res = await _client.get(
      '${ApiConstants.publicInvitePreviewEndpoint}/$token',
      clientSecret: clientSecret,
    );
    return InviteModel.fromJson(res as Map<String, dynamic>);
  }

  /// POST /ondemand/public/invites/:token/accept
  Future<String> acceptInvite({
    required String token,
    required String password,
    String? fullName,
    String? clientSecret,
  }) async {
    final body = <String, dynamic>{
      'password': password,
      if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
    };

    final res = await _client.post(
      '${ApiConstants.publicInvitePreviewEndpoint}/$token/accept',
      body: body,
      clientSecret: clientSecret,
    );
    final map = res as Map<String, dynamic>?;
    return map?['message'] as String? ??
        'Invite accepted. You can now sign in.';
  }

  /// POST /ondemand/public/registrations
  Future<Map<String, dynamic>> registerVenue({
    required String name,
    required String partnerType, // "INDEPENDENT" | "HOST"
    required String contactEmail,
    String? contactName,
    String? phone,
    String? clientSecret,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'partner_type': partnerType,
      'contact_email': contactEmail,
      if (contactName != null && contactName.isNotEmpty)
        'contact_name': contactName,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    };

    final res = await _client.post(
      ApiConstants.publicRegistrationsEndpoint,
      body: body,
      clientSecret: clientSecret,
    );
    return (res as Map<String, dynamic>?) ?? {};
  }
}
