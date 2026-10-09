import 'package:equatable/equatable.dart';

/// Room representation matching the OnDemand Plodyo API specification.
class RoomModel extends Equatable {
  const RoomModel({
    required this.id,
    required this.propertyId,
    this.propertyName,
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
  final String? propertyName;
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

  /// Refused once provisioned: the session history cascades with the row. Revoke instead.
  bool get canDelete => isUnprovisioned;

  /// Needs a live credential; a room never set up, or already revoked, has none.
  bool get canRevoke => isActive;

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String? ?? '',
      propertyId: json['property_id'] as String? ?? '',
      propertyName: json['property_name'] as String?,
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
      'property_name': propertyName,
      'room_label': roomLabel,
      'status': status,
      'default_language': defaultLanguage,
      'provisioned_at': provisionedAt,
      'last_seen_at': lastSeenAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  List<Object?> get props => [
    id,
    propertyId,
    propertyName,
    roomLabel,
    status,
    defaultLanguage,
    provisionedAt,
    lastSeenAt,
    createdAt,
    updatedAt,
  ];
}

/// Response payload from POST /ondemand/admin/rooms/:id/provision
class ProvisionRoomResponse extends Equatable {
  const ProvisionRoomResponse({
    required this.pairingCode,
    required this.expiresAt,
  });

  final String pairingCode;
  final String expiresAt;

  factory ProvisionRoomResponse.fromJson(Map<String, dynamic> json) {
    return ProvisionRoomResponse(
      pairingCode: json['pairing_code'] as String? ?? '',
      expiresAt: json['expires_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'pairing_code': pairingCode,
    'expires_at': expiresAt,
  };

  @override
  List<Object?> get props => [pairingCode, expiresAt];
}

/// Response payload from POST /ondemand/admin/rooms/bulk
class BulkCreateRoomsResponse extends Equatable {
  const BulkCreateRoomsResponse({required this.created, required this.rooms});

  final int created;
  final List<RoomModel> rooms;

  factory BulkCreateRoomsResponse.fromJson(Map<String, dynamic> json) {
    final rawRooms = (json['rooms'] as List<dynamic>?) ?? [];
    return BulkCreateRoomsResponse(
      created: json['created'] as int? ?? rawRooms.length,
      rooms: rawRooms
          .whereType<Map<String, dynamic>>()
          .map(RoomModel.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [created, rooms];
}
