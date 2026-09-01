import 'package:equatable/equatable.dart';
import 'actor.dart';

/// Response payload from successful login or token refresh.
class AuthResponse extends Equatable {
  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.actor,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final Actor actor;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? 'Bearer',
      expiresIn: json['expires_in'] as int? ?? 0,
      actor: Actor.fromJson(
        (json['actor'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
      'actor': actor.toJson(),
    };
  }

  AuthResponse copyWith({
    String? accessToken,
    String? refreshToken,
    String? tokenType,
    int? expiresIn,
    Actor? actor,
  }) {
    return AuthResponse(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenType: tokenType ?? this.tokenType,
      expiresIn: expiresIn ?? this.expiresIn,
      actor: actor ?? this.actor,
    );
  }

  @override
  List<Object?> get props => [
        accessToken,
        refreshToken,
        tokenType,
        expiresIn,
        actor,
      ];
}
