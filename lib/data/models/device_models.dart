import 'package:equatable/equatable.dart';

/// Response payload from POST /ondemand/device/pair
class DevicePairResponse extends Equatable {
  const DevicePairResponse({required this.deviceToken});

  final String deviceToken;

  factory DevicePairResponse.fromJson(Map<String, dynamic> json) {
    return DevicePairResponse(
      deviceToken: json['device_token'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'device_token': deviceToken};

  @override
  List<Object?> get props => [deviceToken];
}

/// Response payload from GET /ondemand/device/session
class DeviceSession extends Equatable {
  const DeviceSession({
    required this.sessionId,
    required this.roomId,
    required this.startedAt,
  });

  final String sessionId;
  final String roomId;
  final String startedAt;

  factory DeviceSession.fromJson(Map<String, dynamic> json) {
    return DeviceSession(
      sessionId: json['session_id'] as String? ?? '',
      roomId: json['room_id'] as String? ?? '',
      startedAt: json['started_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'room_id': roomId,
    'started_at': startedAt,
  };

  @override
  List<Object?> get props => [sessionId, roomId, startedAt];
}

/// Config language entry from GET /ondemand/device/config
class DeviceLanguage extends Equatable {
  const DeviceLanguage({required this.code, required this.name});

  final String code;
  final String name;

  factory DeviceLanguage.fromJson(Map<String, dynamic> json) {
    return DeviceLanguage(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'code': code, 'name': name};

  @override
  List<Object?> get props => [code, name];
}

/// Response payload from GET /ondemand/device/config
class DeviceConfig extends Equatable {
  const DeviceConfig({
    required this.languages,
    required this.ageGroups,
    this.defaultLanguage,
  });

  final List<DeviceLanguage> languages;
  final List<String> ageGroups;
  final String? defaultLanguage;

  factory DeviceConfig.fromJson(Map<String, dynamic> json) {
    final rawLanguages = (json['languages'] as List<dynamic>?) ?? [];
    final rawAgeGroups = (json['age_groups'] as List<dynamic>?) ?? [];

    return DeviceConfig(
      languages: rawLanguages
          .whereType<Map<String, dynamic>>()
          .map(DeviceLanguage.fromJson)
          .toList(),
      ageGroups: rawAgeGroups.map((e) => e.toString()).toList(),
      defaultLanguage: json['default_language'] as String?,
    );
  }

  @override
  List<Object?> get props => [languages, ageGroups, defaultLanguage];
}

/// Story item in catalogue from GET /ondemand/device/content
class DeviceStoryItem extends Equatable {
  const DeviceStoryItem({
    required this.id,
    required this.title,
    this.description,
    this.artworkUrl,
    this.duration,
    this.language,
    this.ageGroup,
    this.mediaUrl,
  });

  final String id;
  final String title;
  final String? description;
  final String? artworkUrl;
  final String? duration;
  final String? language;
  final String? ageGroup;
  final String? mediaUrl;

  factory DeviceStoryItem.fromJson(Map<String, dynamic> json) {
    return DeviceStoryItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Story',
      description: json['description'] as String?,
      artworkUrl: json['artwork_url'] as String?,
      duration: json['duration'] as String?,
      language: json['language'] as String?,
      ageGroup: json['age_group'] as String?,
      mediaUrl: json['media_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'artwork_url': artworkUrl,
    'duration': duration,
    'language': language,
    'age_group': ageGroup,
    if (mediaUrl != null) 'media_url': mediaUrl,
  };

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    artworkUrl,
    duration,
    language,
    ageGroup,
    mediaUrl,
  ];
}
