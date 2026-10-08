import 'package:equatable/equatable.dart';

/// Invite model representing both Admin Invites list and Public Invites preview.
class InviteModel extends Equatable {
  const InviteModel({
    required this.id,
    required this.email,
    required this.role,
    this.partnerId,
    this.propertyId,
    required this.status,
    this.sentAt,
    this.acceptedAt,
    this.expiresAt,
    required this.createdAt,
    this.partnerName,
    this.propertyName,
    this.accountExists,
  });

  final String id;
  final String email;
  final String role; // "PARTNER_ADMIN" | "PROPERTY_ADMIN"
  final String? partnerId;
  final String? propertyId;
  final String status; // "PENDING" | "ACCEPTED" | "EXPIRED" | "REVOKED"
  final String? sentAt;
  final String? acceptedAt;
  final String? expiresAt;
  final String createdAt;

  // Optional fields present in public preview endpoint
  final String? partnerName;
  final String? propertyName;
  final bool? accountExists;

  bool get isPending => status == 'PENDING';
  bool get isAccepted => status == 'ACCEPTED';
  bool get isExpired => status == 'EXPIRED';
  bool get isRevoked => status == 'REVOKED';

  factory InviteModel.fromJson(Map<String, dynamic> json) {
    return InviteModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      partnerId: json['partner_id'] as String?,
      propertyId: json['property_id'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      sentAt: json['sent_at'] as String?,
      acceptedAt: json['accepted_at'] as String?,
      expiresAt: json['expires_at'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      partnerName: json['partner_name'] as String?,
      propertyName: json['property_name'] as String?,
      accountExists: json['account_exists'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'partner_id': partnerId,
      'property_id': propertyId,
      'status': status,
      'sent_at': sentAt,
      'accepted_at': acceptedAt,
      'expires_at': expiresAt,
      'created_at': createdAt,
      'partner_name': partnerName,
      'property_name': propertyName,
      'account_exists': accountExists,
    };
  }

  InviteModel copyWith({
    String? id,
    String? email,
    String? role,
    String? partnerId,
    String? propertyId,
    String? status,
    String? sentAt,
    String? acceptedAt,
    String? expiresAt,
    String? createdAt,
    String? partnerName,
    String? propertyName,
    bool? accountExists,
  }) {
    return InviteModel(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      partnerId: partnerId ?? this.partnerId,
      propertyId: propertyId ?? this.propertyId,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      partnerName: partnerName ?? this.partnerName,
      propertyName: propertyName ?? this.propertyName,
      accountExists: accountExists ?? this.accountExists,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    role,
    partnerId,
    propertyId,
    status,
    sentAt,
    acceptedAt,
    expiresAt,
    createdAt,
    partnerName,
    propertyName,
    accountExists,
  ];
}
