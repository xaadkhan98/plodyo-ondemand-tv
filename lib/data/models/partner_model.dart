import 'package:equatable/equatable.dart';

/// Partner representation matching the OnDemand Plodyo API specification.
class PartnerModel extends Equatable {
  const PartnerModel({
    required this.id,
    required this.name,
    required this.partnerType,
    required this.status,
    required this.contactEmail,
    this.contactName,
    this.phone,
    this.contractReference,
    required this.roomLimit,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String partnerType; // "INDEPENDENT" | "HOST"
  final String status; // "PENDING_APPROVAL" | "ACTIVE" | "SUSPENDED" | "REJECTED"
  final String contactEmail;
  final String? contactName;
  final String? phone;
  final String? contractReference;
  final int roomLimit;
  final String? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;
  final String createdAt;
  final String? updatedAt;

  bool get isPendingApproval => status == 'PENDING_APPROVAL';
  bool get isActive => status == 'ACTIVE';
  bool get isSuspended => status == 'SUSPENDED';
  bool get isRejected => status == 'REJECTED';

  factory PartnerModel.fromJson(Map<String, dynamic> json) {
    return PartnerModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      partnerType: json['partner_type'] as String? ?? 'INDEPENDENT',
      status: json['status'] as String? ?? 'PENDING_APPROVAL',
      contactEmail: json['contact_email'] as String? ?? '',
      contactName: json['contact_name'] as String?,
      phone: json['phone'] as String?,
      contractReference: json['contract_reference'] as String?,
      roomLimit: (json['room_limit'] as num?)?.toInt() ?? 0,
      reviewedAt: json['reviewed_at'] as String?,
      reviewedBy: json['reviewed_by'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'partner_type': partnerType,
      'status': status,
      'contact_email': contactEmail,
      'contact_name': contactName,
      'phone': phone,
      'contract_reference': contractReference,
      'room_limit': roomLimit,
      'reviewed_at': reviewedAt,
      'reviewed_by': reviewedBy,
      'rejection_reason': rejectionReason,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  PartnerModel copyWith({
    String? id,
    String? name,
    String? partnerType,
    String? status,
    String? contactEmail,
    String? contactName,
    String? phone,
    String? contractReference,
    int? roomLimit,
    String? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
    String? createdAt,
    String? updatedAt,
  }) {
    return PartnerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      partnerType: partnerType ?? this.partnerType,
      status: status ?? this.status,
      contactEmail: contactEmail ?? this.contactEmail,
      contactName: contactName ?? this.contactName,
      phone: phone ?? this.phone,
      contractReference: contractReference ?? this.contractReference,
      roomLimit: roomLimit ?? this.roomLimit,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        partnerType,
        status,
        contactEmail,
        contactName,
        phone,
        contractReference,
        roomLimit,
        reviewedAt,
        reviewedBy,
        rejectionReason,
        createdAt,
        updatedAt,
      ];
}
