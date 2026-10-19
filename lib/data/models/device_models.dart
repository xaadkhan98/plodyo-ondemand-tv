import '../../core/constants/languages.dart';

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

/// The three buckets the catalogue filters on, each with a face so a parent reads the age before the words.
enum AgeGroup {
  toddler('0-2', 'Toddler', '🍼'),
  preschool('2-4', 'Preschool', '🧸'),
  earlySchool('5-7', 'Early school', '🎒');

  const AgeGroup(this.code, this.label, this.emoji);

  final String code;
  final String label;
  final String emoji;

  static AgeGroup? parse(String? code) {
    for (final group in values) {
      if (group.code == code) return group;
    }
    return null;
  }
}

/// What this room's pickers are built from.
class DeviceConfig {
  const DeviceConfig({
    required this.languages,
    required this.ageGroups,
    this.defaultLanguage,
    this.roomId,
    this.termsEffectiveDate,
  });

  factory DeviceConfig.fromJson(Map<String, dynamic> json) => DeviceConfig(
    languages: [
      for (final language
          in (json['languages'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>())
        Language(language['code'] as String, language['name'] as String),
    ],
    // Filtered, not cast: an unknown bucket would render a chip that /content answers 400 for.
    ageGroups: [
      for (final code in json['age_groups'] as List<dynamic>? ?? const [])
        ?AgeGroup.parse('$code'),
    ],
    defaultLanguage: json['default_language'] as String?,
    roomId: json['room_id'] as String?,
    termsEffectiveDate: json['terms_effective_date'] as String?,
  );

  final List<Language> languages;
  final List<AgeGroup> ageGroups;

  /// The room's setting, falling back to its property's; null when neither has one.
  final String? defaultLanguage;

  /// The room this TV is paired to, which support asks for. Null in the console, which has no room.
  final String? roomId;

  /// The Terms of Service's effective date, e.g. `2026-10-25`: their only identifier. Null in the console.
  final String? termsEffectiveDate;
}
