import 'package:equatable/equatable.dart';

/// Room representation matching the OnDemand Plodyo API specification.
class RoomModel extends Equatable {
  const RoomModel({
    required this.id,
    required this.propertyId,
    required this.roomLabel,
    required this.status,
    this.defaultLanguage,
    this.provisionedAt,
    this.lastSeenAt,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String propertyId;
  final String roomLabel;
  final String status; // "UNPROVISIONED" | "ACTIVE" | "REVOKED"
  final String? defaultLanguage;
  final String? provisionedAt;
  final String? lastSeenAt;
  final String createdAt;
  final String? updatedAt;

  bool get isUnprovisioned => status == 'UNPROVISIONED';
  bool get isActive => status == 'ACTIVE';
  bool get isRevoked => status == 'REVOKED';

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String? ?? '',
      propertyId: json['property_id'] as String? ?? '',
      roomLabel: json['room_label'] as String? ?? '',
      status: json['status'] as String? ?? 'UNPROVISIONED',
      defaultLanguage: json['default_language'] as String?,
      provisionedAt: json['provisioned_at'] as String?,
      lastSeenAt: json['last_seen_at'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'room_label': roomLabel,
      'status': status,
      'default_language': defaultLanguage,
      'provisioned_at': provisionedAt,
      'last_seen_at': lastSeenAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  RoomModel copyWith({
    String? id,
    String? propertyId,
    String? roomLabel,
    String? status,
    String? defaultLanguage,
    String? provisionedAt,
    String? lastSeenAt,
    String? createdAt,
    String? updatedAt,
  }) {
    return RoomModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      roomLabel: roomLabel ?? this.roomLabel,
      status: status ?? this.status,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      provisionedAt: provisionedAt ?? this.provisionedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        propertyId,
        roomLabel,
        status,
        defaultLanguage,
        provisionedAt,
        lastSeenAt,
        createdAt,
        updatedAt,
      ];
}
