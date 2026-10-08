import '../models/actor.dart';
import '../models/auth_exception.dart';
import '../models/auth_response.dart';
import '../models/invite_model.dart';
import '../services/auth_api_service.dart';

/// Global shared instance of [AuthRepository] for the TV application session.
final AuthRepository sharedAuthRepository = AuthRepositoryImpl();

/// Abstract repository defining authentication and user identity operations.
abstract class AuthRepository {
  /// Sign in with user email and password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  });

  /// Refresh token session.
  Future<AuthResponse> refreshToken();

  /// Sign out the current user and invalidate the session.
  Future<void> signOut();

  /// Send password reset email.
  Future<String> forgotPassword({required String email});

  /// Reset password with token.
  Future<String> resetPassword({
    required String token,
    required String newPassword,
  });

  /// Fetch user profile and memberships.
  Future<AuthMeResponse> getMe({String? accessToken});

  /// Preview public invite.
  Future<InviteModel> previewInvite(String token);

  /// Accept public invite.
  Future<String> acceptInvite({
    required String token,
    required String password,
    String? fullName,
  });

  /// Public venue registration.
  Future<Map<String, dynamic>> registerVenue({
    required String name,
    required String partnerType,
    required String contactEmail,
    String? contactName,
    String? phone,
  });

  /// Currently authenticated session information.
  AuthResponse? get currentAuth;

  /// Currently logged in user actor.
  Actor? get currentUser;

  /// Check whether user is currently authenticated.
  bool get isAuthenticated;
}

/// Concrete implementation of [AuthRepository] interacting with [AuthApiService].
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({AuthApiService? apiService})
    : _apiService = apiService ?? AuthApiService();

  final AuthApiService _apiService;

  AuthResponse? _currentAuth;

  @override
  AuthResponse? get currentAuth => _currentAuth;

  @override
  Actor? get currentUser => _currentAuth?.actor;

  @override
  bool get isAuthenticated => _currentAuth != null;

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.login(email: email, password: password);
    _currentAuth = response;
    return response;
  }

  @override
  Future<AuthResponse> refreshToken() async {
    final token = _currentAuth?.refreshToken;
    if (token == null || token.isEmpty) {
      throw const AuthException(
        message: 'No active refresh token available.',
        statusCode: 401,
      );
    }
    final response = await _apiService.refreshToken(refreshToken: token);
    _currentAuth = response;
    return response;
  }

  @override
  Future<void> signOut() async {
    final refreshToken = _currentAuth?.refreshToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _apiService.logout(refreshToken: refreshToken);
      } catch (_) {}
    }
    _currentAuth = null;
  }

  @override
  Future<String> forgotPassword({required String email}) {
    return _apiService.forgotPassword(email: email);
  }

  @override
  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) {
    return _apiService.resetPassword(token: token, password: newPassword);
  }

  @override
  Future<AuthMeResponse> getMe({String? accessToken}) async {
    final token = accessToken ?? _currentAuth?.accessToken ?? '';
    if (token.isEmpty) {
      throw const AuthException(
        message: 'Unauthenticated. Please sign in.',
        statusCode: 401,
      );
    }
    final res = await _apiService.getMe(accessToken: token);
    _currentAuth = _currentAuth?.copyWith(actor: res.actor);
    return res;
  }

  @override
  Future<InviteModel> previewInvite(String token) {
    return _apiService.previewInvite(token: token);
  }

  @override
  Future<String> acceptInvite({
    required String token,
    required String password,
    String? fullName,
  }) {
    return _apiService.acceptInvite(
      token: token,
      password: password,
      fullName: fullName,
    );
  }

  @override
  Future<Map<String, dynamic>> registerVenue({
    required String name,
    required String partnerType,
    required String contactEmail,
    String? contactName,
    String? phone,
  }) {
    return _apiService.registerVenue(
      name: name,
      partnerType: partnerType,
      contactEmail: contactEmail,
      contactName: contactName,
      phone: phone,
    );
  }
}
