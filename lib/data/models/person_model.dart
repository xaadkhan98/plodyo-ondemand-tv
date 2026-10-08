import 'package:equatable/equatable.dart';
import 'roles.dart';

/// Represents a user / person in the Plodyo TV console.
class PersonModel extends Equatable {
  const PersonModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
    this.lastLoginAt,
    this.isCurrentUser = false,
    this.partnerId,
    this.partnerName,
    this.propertyId,
    this.propertyName,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String email;
  final String role;
  final String status; // 'ACTIVE', 'INVITED', 'DISABLED'
  final String? lastLoginAt;
  final bool isCurrentUser;
  final String? partnerId;
  final String? partnerName;
  final String? propertyId;
  final String? propertyName;
  final String? createdAt;

  bool get isActive => status.toUpperCase() == 'ACTIVE';
  bool get isInvited => status.toUpperCase() == 'INVITED';
  bool get isDisabled => status.toUpperCase() == 'DISABLED';

  bool get isSuperAdmin => role.toUpperCase() == 'SUPER_ADMIN' || role.toUpperCase() == 'SUPER ADMIN';
  bool get isPartnerAdmin => role.toUpperCase() == 'PARTNER_ADMIN' || role.toUpperCase() == 'PARTNER ADMIN';
  bool get isPropertyAdmin => role.toUpperCase() == 'PROPERTY_ADMIN' || role.toUpperCase() == 'PROPERTY ADMIN';

  String get roleDisplayName => roleLabel(role);

  PersonModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? role,
    String? status,
    String? lastLoginAt,
    bool? isCurrentUser,
    String? partnerId,
    String? partnerName,
    String? propertyId,
    String? propertyName,
    String? createdAt,
  }) {
    return PersonModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      partnerId: partnerId ?? this.partnerId,
      partnerName: partnerName ?? this.partnerName,
      propertyId: propertyId ?? this.propertyId,
      propertyName: propertyName ?? this.propertyName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory PersonModel.fromJson(Map<String, dynamic> json) {
    final memberships = (json['memberships'] as List<dynamic>?) ?? [];
    Map<String, dynamic>? primaryMembership;
    if (memberships.isNotEmpty && memberships.first is Map<String, dynamic>) {
      primaryMembership = memberships.first as Map<String, dynamic>;
    }

    final role = json['role'] as String? ??
        json['role_name'] as String? ??
        primaryMembership?['role'] as String? ??
        'PARTNER_ADMIN';
    final partnerId = json['partner_id'] as String? ??
        json['partnerId'] as String? ??
        primaryMembership?['partner_id'] as String?;
    final propertyId = json['property_id'] as String? ??
        json['propertyId'] as String? ??
        primaryMembership?['property_id'] as String?;

    return PersonModel(
      id: json['id'] as String? ?? json['user_id'] as String? ?? json['_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? json['fullName'] as String? ?? json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: role,
      status: json['status'] as String? ?? 'ACTIVE',
      lastLoginAt: json['last_login_at'] as String? ?? json['lastLoginAt'] as String?,
      isCurrentUser: json['is_current_user'] as bool? ?? json['isCurrentUser'] as bool? ?? false,
      partnerId: partnerId,
      partnerName: json['partner_name'] as String? ?? json['partnerName'] as String?,
      propertyId: propertyId,
      propertyName: json['property_name'] as String? ?? json['propertyName'] as String?,
      createdAt: json['created_at'] as String? ?? json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'role': role,
      'status': status,
      'last_login_at': lastLoginAt,
      'is_current_user': isCurrentUser,
      'partner_id': partnerId,
      'partner_name': partnerName,
      'property_id': propertyId,
      'property_name': propertyName,
      'created_at': createdAt,
    };
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        email,
        role,
        status,
        lastLoginAt,
        isCurrentUser,
        partnerId,
        partnerName,
        propertyId,
        propertyName,
        createdAt,
      ];
}
