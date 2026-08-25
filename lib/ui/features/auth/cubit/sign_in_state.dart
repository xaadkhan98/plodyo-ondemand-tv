import 'package:equatable/equatable.dart';
import '../../../../data/models/auth_response.dart';

/// Base state for the Sign In feature.
abstract class SignInState extends Equatable {
  const SignInState();

  @override
  List<Object?> get props => [];
}

/// Initial resting state before user initiates sign in.
class SignInInitial extends SignInState {
  const SignInInitial();
}

/// State emitted while sign in network request is in-flight.
class SignInLoading extends SignInState {
  const SignInLoading();
}

/// State emitted on successful authentication.
class SignInSuccess extends SignInState {
  const SignInSuccess({
    required this.authResponse,
    this.message = 'Sign in successful',
  });

  final AuthResponse authResponse;
  final String message;

  @override
  List<Object?> get props => [authResponse, message];
}

/// State emitted when authentication fails (credentials, network, validation).
class SignInFailure extends SignInState {
  const SignInFailure({
    required this.errorMessage,
    this.statusCode,
  });

  final String errorMessage;
  final int? statusCode;

  @override
  List<Object?> get props => [errorMessage, statusCode];
}
