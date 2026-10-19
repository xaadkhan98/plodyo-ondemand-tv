import 'dart:ui' show Locale, TextDirection;

import '../../core/constants/languages.dart';
import '../../core/constants/legal.dart';

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

/// The Terms notice, the Terms screen's title and the rail's Terms item, in one language.
class TermsNotice {
  const TermsNotice({
    required this.language,
    required this.locale,
    this.rtl = false,
    required this.notice,
    this.dateLine,
    required this.menuItem,
    required this.continueLabel,
  });

  factory TermsNotice.fromJson(Map<String, dynamic> json) => TermsNotice(
    language: json['language'] as String,
    locale: json['locale'] as String,
    rtl: json['dir'] == 'rtl',
    notice: json['notice'] as String,
    dateLine: json['date_line'] as String?,
    menuItem: json['menu_item'] as String,
    continueLabel: json['continue_label'] as String,
  );

  /// The bundled English, for a backend that serves no notices. The backend's copy wins when it does.
  factory TermsNotice.english(String? effectiveDate) => TermsNotice(
    language: 'ENG',
    locale: 'en-GB',
    notice: termsNoticeText,
    dateLine: effectiveDate == null ? null : termsEffectiveLine(effectiveDate),
    menuItem: 'Terms of Service',
    continueLabel: 'Continue',
  );

  /// The code the notice log records, e.g. `ENG`.
  final String language;

  /// BCP 47, e.g. `zh-Hant`.
  final String locale;
  final bool rtl;
  final String notice;

  /// Null when the backend sent no effective date.
  final String? dateLine;
  final String menuItem;
  final String continueLabel;

  TextDirection get direction => rtl ? TextDirection.rtl : TextDirection.ltr;

  /// For the glyphs that differ by language, such as Japanese and Chinese Han.
  Locale get textLocale {
    final [language, ...rest] = locale.split('-');
    return Locale.fromSubtags(
      languageCode: language,
      scriptCode: rest.where((part) => part.length == 4).firstOrNull,
      countryCode: rest.where((part) => part.length == 2).firstOrNull,
    );
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
    this.termsNotices = const [],
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
    termsNotices: [
      for (final notice
          in (json['terms_notices'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>())
        TermsNotice.fromJson(notice),
    ],
  );

  final List<Language> languages;
  final List<AgeGroup> ageGroups;

  /// The room's setting, falling back to its property's; null when neither has one.
  final String? defaultLanguage;

  /// The room this TV is paired to, which support asks for. Null in the console, which has no room.
  final String? roomId;

  /// The Terms of Service's effective date, e.g. `2026-10-25`: their only identifier. Null in the console.
  final String? termsEffectiveDate;

  /// Approved translations only, English among them; empty from an older backend.
  final List<TermsNotice> termsNotices;

  /// The notice in [language] (null is the room's), else English.
  TermsNotice termsNotice(String? language) {
    for (final code in [language ?? defaultLanguage, 'ENG']) {
      for (final notice in termsNotices) {
        if (notice.language == code) return notice;
      }
    }
    return TermsNotice.english(termsEffectiveDate);
  }
}
