import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/auth_exception.dart';
import '../../../../data/repositories/auth_repository.dart';
import 'sign_in_state.dart';

/// Cubit managing the authentication state machine for the Sign In view.
class SignInCubit extends Cubit<SignInState> {
  /// [notice] opens the form on why the last session ended.
  SignInCubit({AuthRepository? authRepository, String? notice})
    : _authRepository = authRepository ?? AuthRepositoryImpl(),
      super(
        notice == null
            ? const SignInInitial()
            : SignInFailure(errorMessage: notice),
      );

  final AuthRepository _authRepository;

  /// Execute user sign-in request against the OnDemand Plodyo API.
  Future<void> signIn({required String email, required String password}) async {
    final trimmedEmail = email.trim();

    if (trimmedEmail.isEmpty || password.trim().isEmpty) {
      emit(
        const SignInFailure(
          errorMessage: 'Enter both an email address and a password.',
        ),
      );
      return;
    }

    emit(const SignInLoading());

    try {
      // Only the email is trimmed: a space can be part of a password.
      final response = await _authRepository.signIn(
        email: trimmedEmail,
        password: password,
      );

      final welcomeMsg = response.actor.fullName.isNotEmpty
          ? 'Welcome back, ${response.actor.fullName}!'
          : 'Signed in successfully.';

      emit(SignInSuccess(authResponse: response, message: welcomeMsg));
    } on AuthException catch (e) {
      emit(SignInFailure(errorMessage: e.message, statusCode: e.statusCode));
    } catch (e) {
      emit(SignInFailure(errorMessage: e.toString()));
    }
  }

  /// Reset state back to initial resting state.
  void reset() {
    emit(const SignInInitial());
  }

  /// Clear any active error banner.
  void clearError() {
    if (state is SignInFailure) {
      emit(const SignInInitial());
    }
  }
}
