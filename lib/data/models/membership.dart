import 'package:equatable/equatable.dart';

/// Membership represents a role scope associated with an account.
class Membership extends Equatable {
  const Membership({
    required this.id,
    required this.role,
    this.partnerId,
    this.propertyId,
    required this.createdAt,
  });

  final String id;
  final String role;
  final String? partnerId;
  final String? propertyId;
  final String createdAt;

  factory Membership.fromJson(Map<String, dynamic> json) {
    return Membership(
      id: json['id'] as String? ?? '',
      role: json['role'] as String? ?? '',
      partnerId: json['partner_id'] as String?,
      propertyId: json['property_id'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'partner_id': partnerId,
      'property_id': propertyId,
      'created_at': createdAt,
    };
  }

  @override
  List<Object?> get props => [id, role, partnerId, propertyId, createdAt];
}
