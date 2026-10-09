/// A pairing code is printed as two groups of four, e.g. 4F7K-92QT.
const pairingCodeLength = 8;

/// Whatever the installer typed, as the API expects it: capitals and digits, the dash as presentation.
String normalisePairingCode(String raw) {
  final cleaned = raw.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
  if (cleaned.length <= 4) return cleaned;
  final end = cleaned.length < pairingCodeLength
      ? cleaned.length
      : pairingCodeLength;
  return '${cleaned.substring(0, 4)}-${cleaned.substring(4, end)}';
}

/// The three buckets the catalogue filters on.
enum AgeGroup {
  toddler('0-2', 'Toddler'),
  preschool('2-4', 'Preschool'),
  earlySchool('5-7', 'Early school');

  const AgeGroup(this.code, this.label);

  final String code;
  final String label;

  static AgeGroup? parse(String code) {
    for (final group in values) {
      if (group.code == code) return group;
    }
    return null;
  }
}

/// The room_sessions row a TV holds; a heartbeat replaces it once a visit idles out.
class DeviceSession {
  const DeviceSession({
    required this.sessionId,
    required this.roomId,
    required this.startedAt,
  });

  factory DeviceSession.fromJson(Map<String, dynamic> json) => DeviceSession(
    sessionId: json['session_id'] as String,
    roomId: json['room_id'] as String,
    startedAt: json['started_at'] as String,
  );

  final String sessionId;
  final String roomId;
  final String startedAt;
}

class LanguageOption {
  const LanguageOption({required this.code, required this.name});

  factory LanguageOption.fromJson(Map<String, dynamic> json) => LanguageOption(
    code: json['code'] as String,
    name: json['name'] as String,
  );

  final String code;
  final String name;
}

/// What this room's pickers are built from.
class DeviceConfig {
  const DeviceConfig({
    required this.languages,
    required this.ageGroups,
    this.defaultLanguage,
  });

  factory DeviceConfig.fromJson(Map<String, dynamic> json) => DeviceConfig(
    languages: [
      for (final language
          in (json['languages'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>())
        LanguageOption.fromJson(language),
    ],
    // Filtered, not cast: an unknown bucket would render a chip that /content answers 400 for.
    ageGroups: [
      for (final code in json['age_groups'] as List<dynamic>? ?? const [])
        ?AgeGroup.parse('$code'),
    ],
    defaultLanguage: json['default_language'] as String?,
  );

  final List<LanguageOption> languages;
  final List<AgeGroup> ageGroups;

  /// The room's setting, falling back to its property's; null when neither has one.
  final String? defaultLanguage;
}
