import '../models/actor.dart';
import '../models/auth_response.dart';
import '../services/auth_api_service.dart';

/// Abstract repository defining authentication operations.
abstract class AuthRepository {
  /// Sign in with user email and password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  });

  /// Sign out the current user and invalidate the session.
  Future<void> signOut();

  /// Currently authenticated session information.
  AuthResponse? get currentAuth;

  /// Currently logged in user actor.
  Actor? get currentUser;

  /// Check whether user is currently authenticated.
  bool get isAuthenticated;
}

/// Concrete implementation of [AuthRepository] interacting with [AuthApiService].
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    AuthApiService? apiService,
  }) : _apiService = apiService ?? AuthApiService();

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
    final response = await _apiService.login(
      email: email,
      password: password,
    );
    _currentAuth = response;
    return response;
  }

  @override
  Future<void> signOut() async {
    final refreshToken = _currentAuth?.refreshToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _apiService.logout(refreshToken: refreshToken);
    }
    _currentAuth = null;
  }
}
