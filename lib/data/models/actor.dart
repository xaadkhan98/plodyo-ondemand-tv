import 'package:equatable/equatable.dart';

/// Actor represents the authenticated user and their organization scope.
class Actor extends Equatable {
  const Actor({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.role,
    this.partnerId,
    this.propertyId,
  });

  final String userId;
  final String email;
  final String fullName;
  final String role;
  final String? partnerId;
  final String? propertyId;

  /// Convenience getters for role-based logic.
  bool get isSuperAdmin => role == 'SUPER_ADMIN';
  bool get isPartnerAdmin => role == 'PARTNER_ADMIN';
  bool get isPropertyAdmin => role == 'PROPERTY_ADMIN';

  factory Actor.fromJson(Map<String, dynamic> json) {
    return Actor(
      userId: json['user_id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      partnerId: json['partner_id'] as String?,
      propertyId: json['property_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'full_name': fullName,
      'role': role,
      'partner_id': partnerId,
      'property_id': propertyId,
    };
  }

  @override
  List<Object?> get props => [
        userId,
        email,
        fullName,
        role,
        partnerId,
        propertyId,
      ];
}
