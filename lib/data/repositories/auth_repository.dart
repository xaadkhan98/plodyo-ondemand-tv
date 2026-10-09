import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/actor.dart';
import '../models/auth_exception.dart';
import '../models/auth_response.dart';
import '../models/invite_model.dart';
import '../services/auth_api_service.dart';

/// Global shared instance of [AuthRepository] for the TV application session.
final AuthRepositoryImpl sharedAuthRepository = AuthRepositoryImpl();

/// Shown when an account's role and scope disagree; every screen would 403 for it.
const incoherentScopeMessage =
    'This account is not set up correctly. Contact your Plodyo administrator.';

/// The bearer for admin calls, or empty when signed out (the API then answers 401).
extension AccessToken on AuthRepository {
  String get accessToken => currentAuth?.accessToken ?? '';
}

/// Abstract repository defining authentication and user identity operations.
abstract class AuthRepository {
  /// Sign in with user email and password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  });

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

  /// Checks a session restored from storage against /auth/me, so a role change or a disabled account
  /// applies on the next boot. Ends the session if the API refuses it; a network fault leaves it intact.
  Future<void> resume();

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

/// The console's session: a 15-minute access token and a single-use, rotating refresh token. The pair is
/// kept encrypted (Android Keystore), so a console survives a power cut without its password; the actor is
/// not, and comes back from /auth/me on boot. Notifies when a session starts or ends, never on a renewal.
class AuthRepositoryImpl extends ChangeNotifier implements AuthRepository {
  AuthRepositoryImpl({
    AuthApiService? apiService,
    FlutterSecureStorage? storage,
  }) : _apiService = apiService ?? AuthApiService(),
       _storage = storage ?? const FlutterSecureStorage();

  static const _accessKey = 'plodyo.ondemand.access-token';
  static const _refreshKey = 'plodyo.ondemand.refresh-token';

  final AuthApiService _apiService;
  final FlutterSecureStorage _storage;
  String? _access;
  String? _refresh;
  Actor? _actor;
  Future<String>? _renewal;
  String? _notice;

  @override
  AuthResponse? get currentAuth => _actor == null
      ? null
      : AuthResponse(
          accessToken: _access!,
          refreshToken: _refresh!,
          tokenType: 'Bearer',
          expiresIn: 0,
          actor: _actor!,
        );

  /// Null while a restored session waits for [resume].
  @override
  Actor? get currentUser => _actor;

  @override
  bool get isAuthenticated => _access != null;

  /// Reads the pair a previous run stored. Called once, before the first frame.
  Future<void> restore() async {
    try {
      final access = await _storage.read(key: _accessKey);
      final refresh = await _storage.read(key: _refreshKey);
      // Half a pair is unusable, so it reads as signed out.
      if (access != null && refresh != null) {
        _access = access;
        _refresh = refresh;
      }
    } on Exception {
      // Unreadable storage reads as signed out; signing in again is the remedy.
    }
  }

  Future<void> _keep(String? access, String? refresh) async {
    _access = access;
    _refresh = refresh;
    try {
      if (access == null || refresh == null) {
        await _storage.delete(key: _accessKey);
        await _storage.delete(key: _refreshKey);
      } else {
        await _storage.write(key: _accessKey, value: access);
        await _storage.write(key: _refreshKey, value: refresh);
      }
    } on Exception {
      // The session continues in memory; it just will not survive a restart.
    }
  }

  /// Why the last session ended, when the person must be told; the sign-in screen shows it once.
  String? takeNotice() {
    final notice = _notice;
    _notice = null;
    return notice;
  }

  // Forgets the session at once, then revokes its refresh token where the API still accepts it.
  Future<void> _end({String? notice}) async {
    final refresh = _refresh;
    if (refresh == null) return;
    _notice = notice;
    _actor = null;
    await _keep(null, null);
    notifyListeners();
    try {
      await _apiService.logout(refreshToken: refresh);
    } on Exception {
      // Already refused, or unreachable: the token expires on its own.
    }
  }

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.login(email: email, password: password);
    await _keep(response.accessToken, response.refreshToken);
    // Refused like a wrong password, before any screen 403s on it.
    if (!response.actor.hasCoherentScope) {
      await _end();
      throw const AuthException(
        message: incoherentScopeMessage,
        statusCode: 403,
      );
    }
    _actor = response.actor;
    notifyListeners();
    return response;
  }

  /// A new access token for one the API refused, shared by every caller: a refresh token is single use, and
  /// replaying one revokes the whole session. Only a refusal ends the session; a timeout or a 5xx does not.
  Future<String> renew() =>
      _renewal ??= _renew().whenComplete(() => _renewal = null);

  Future<String> _renew() async {
    final refresh = _refresh;
    if (refresh == null) {
      throw const AuthException(
        message: 'Your session has ended. Sign in again.',
        statusCode: 401,
      );
    }
    try {
      final response = await _apiService.refreshToken(refreshToken: refresh);
      await _keep(response.accessToken, response.refreshToken);
      return response.accessToken;
    } on AuthException catch (error) {
      if (error.statusCode == 400 || error.statusCode == 401) await _end();
      rethrow;
    }
  }

  @override
  Future<void> signOut() => _end();

  @override
  Future<void> resume() async {
    try {
      await getMe();
    } on AuthException catch (error) {
      // A refused session ends; a network fault keeps it, so trying again needs no password.
      if (error.statusCode == 401) await _end();
      rethrow;
    }
    if (!_actor!.hasCoherentScope) {
      await _end(notice: incoherentScopeMessage);
    }
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
    final token = accessToken ?? _access ?? '';
    if (token.isEmpty) {
      throw const AuthException(
        message: 'Unauthenticated. Please sign in.',
        statusCode: 401,
      );
    }
    final res = await _apiService.getMe(accessToken: token);
    if (isAuthenticated) _actor = res.actor;
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
