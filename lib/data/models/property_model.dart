import 'package:equatable/equatable.dart';

/// Property representation matching the OnDemand Plodyo API specification.
class PropertyModel extends Equatable {
  const PropertyModel({
    required this.id,
    required this.partnerId,
    this.partnerName,
    required this.name,
    required this.status,
    this.country,
    this.city,
    this.timezone,
    this.defaultLanguage,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String partnerId;
  final String? partnerName;
  final String name;
  final String status; // "ACTIVE" | "SUSPENDED"
  final String? country;
  final String? city;
  final String? timezone;
  final String? defaultLanguage;
  final String createdAt;
  final String? updatedAt;

  bool get isActive => status == 'ACTIVE';
  bool get isSuspended => status == 'SUSPENDED';

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'] as String? ?? '',
      partnerId: json['partner_id'] as String? ?? '',
      partnerName: json['partner_name'] as String?,
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      country: json['country'] as String?,
      city: json['city'] as String?,
      timezone: json['timezone'] as String?,
      defaultLanguage: json['default_language'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partner_id': partnerId,
      'partner_name': partnerName,
      'name': name,
      'status': status,
      'country': country,
      'city': city,
      'timezone': timezone,
      'default_language': defaultLanguage,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  PropertyModel copyWith({
    String? id,
    String? partnerId,
    String? partnerName,
    String? name,
    String? status,
    String? country,
    String? city,
    String? timezone,
    String? defaultLanguage,
    String? createdAt,
    String? updatedAt,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      partnerId: partnerId ?? this.partnerId,
      partnerName: partnerName ?? this.partnerName,
      name: name ?? this.name,
      status: status ?? this.status,
      country: country ?? this.country,
      city: city ?? this.city,
      timezone: timezone ?? this.timezone,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    partnerId,
    partnerName,
    name,
    status,
    country,
    city,
    timezone,
    defaultLanguage,
    createdAt,
    updatedAt,
  ];
}
