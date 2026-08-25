import 'package:flutter_test/flutter_test.dart';
import 'package:plodyo_ondemand_tv/data/models/actor.dart';
import 'package:plodyo_ondemand_tv/data/models/auth_exception.dart';
import 'package:plodyo_ondemand_tv/data/models/auth_response.dart';
import 'package:plodyo_ondemand_tv/data/repositories/auth_repository.dart';
import 'package:plodyo_ondemand_tv/ui/features/auth/cubit/sign_in_cubit.dart';
import 'package:plodyo_ondemand_tv/ui/features/auth/cubit/sign_in_state.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.shouldSucceed = true,
    this.errorToThrow,
    this.responseToReturn,
  });

  final bool shouldSucceed;
  final Exception? errorToThrow;
  final AuthResponse? responseToReturn;

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
    await Future.delayed(const Duration(milliseconds: 10));

    if (shouldSucceed) {
      final res = responseToReturn ??
          const AuthResponse(
            accessToken: 'valid_access_token',
            refreshToken: 'valid_refresh_token',
            tokenType: 'Bearer',
            expiresIn: 900,
            actor: Actor(
              userId: 'u-1',
              email: 'ops@grandhotel.com',
              fullName: 'Dana Okafor',
              role: 'PARTNER_ADMIN',
            ),
          );
      _currentAuth = res;
      return res;
    } else {
      throw errorToThrow ??
          const AuthException(
            message: 'Invalid credentials',
            statusCode: 401,
          );
    }
  }

  @override
  Future<void> signOut() async {
    _currentAuth = null;
  }
}

void main() {
  group('SignInCubit Tests', () {
    test('initial state is SignInInitial', () {
      final cubit = SignInCubit(authRepository: FakeAuthRepository());
      expect(cubit.state, const SignInInitial());
      cubit.close();
    });

    test('validates empty inputs and emits SignInFailure without loading', () async {
      final cubit = SignInCubit(authRepository: FakeAuthRepository());

      await cubit.signIn(email: '', password: '');
      expect(
        cubit.state,
        const SignInFailure(errorMessage: 'Please enter both email and password.'),
      );

      await cubit.signIn(email: 'test@plodyo.com', password: '   ');
      expect(
        cubit.state,
        const SignInFailure(errorMessage: 'Please enter both email and password.'),
      );

      cubit.close();
    });

    test('emits [SignInLoading, SignInSuccess] on valid credentials', () async {
      final cubit = SignInCubit(
        authRepository: FakeAuthRepository(shouldSucceed: true),
      );

      expectLater(
        cubit.stream,
        emitsInOrder([
          const SignInLoading(),
          predicate<SignInSuccess>((state) {
            return state.authResponse.actor.fullName == 'Dana Okafor' &&
                state.message == 'Welcome back, Dana Okafor!';
          }),
        ]),
      );

      await cubit.signIn(
        email: 'ops@grandhotel.com',
        password: 'correct-password',
      );

      cubit.close();
    });

    test('emits [SignInLoading, SignInFailure] on 401 Invalid credentials', () async {
      final cubit = SignInCubit(
        authRepository: FakeAuthRepository(
          shouldSucceed: false,
          errorToThrow: const AuthException(
            message: 'Invalid credentials',
            statusCode: 401,
          ),
        ),
      );

      expectLater(
        cubit.stream,
        emitsInOrder([
          const SignInLoading(),
          const SignInFailure(
            errorMessage: 'Invalid credentials',
            statusCode: 401,
          ),
        ]),
      );

      await cubit.signIn(
        email: 'wrong@plodyo.com',
        password: 'wrongpassword',
      );

      cubit.close();
    });

    test('clearError resets state from SignInFailure to SignInInitial', () async {
      final cubit = SignInCubit(
        authRepository: FakeAuthRepository(shouldSucceed: false),
      );

      await cubit.signIn(email: '', password: '');
      expect(cubit.state, isA<SignInFailure>());

      cubit.clearError();
      expect(cubit.state, const SignInInitial());

      cubit.close();
    });
  });
}
