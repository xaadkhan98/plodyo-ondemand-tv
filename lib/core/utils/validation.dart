// Client-side checks only, so a remote user hears what is wrong before a round trip. The API's validators are the real gate.

/// Loose by design: the API's @IsEmail() is the real check.
String? validateEmail(String email, {String label = 'email address'}) {
  final trimmed = email.trim();
  if (trimmed.isEmpty) return 'Enter the $label for this account.';
  if (!trimmed.contains('@') ||
      trimmed.startsWith('@') ||
      trimmed.endsWith('@')) {
    return 'Enter a valid $label.';
  }
  return null;
}

/// A required field, optionally capped at the API's column length.
String? validateRequired(String value, String label, {int? maxLength}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'Enter the $label.';
  if (maxLength != null && trimmed.length > maxLength) {
    return '${label[0].toUpperCase()}${label.substring(1)} must be $maxLength characters or fewer.';
  }
  return null;
}

/// An optional field has no "required" message, only a ceiling.
String? validateMaxLength(String value, String label, int maxLength) =>
    value.trim().length > maxLength
    ? 'The $label must be $maxLength characters or fewer.'
    : null;
