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
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    final accessToken = data['access_token'] as String? ??
        data['accessToken'] as String? ??
        data['token'] as String? ??
        '';

    final refreshToken = data['refresh_token'] as String? ??
        data['refreshToken'] as String? ??
        '';

    final tokenType = data['token_type'] as String? ??
        data['tokenType'] as String? ??
        'Bearer';

    final expiresIn = (data['expires_in'] ?? data['expiresIn']) as int? ?? 0;

    final actorMap = (data['actor'] is Map<String, dynamic>)
        ? data['actor'] as Map<String, dynamic>
        : (data['user'] is Map<String, dynamic>)
            ? data['user'] as Map<String, dynamic>
            : (data['profile'] is Map<String, dynamic>)
                ? data['profile'] as Map<String, dynamic>
                : <String, dynamic>{};

    return AuthResponse(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: tokenType,
      expiresIn: expiresIn,
      actor: Actor.fromJson(actorMap),
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
