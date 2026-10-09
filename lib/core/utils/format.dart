// Dates as the reference shows them (medium date style), in the TV's local time.

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

DateTime? _parse(String? iso) =>
    iso == null ? null : DateTime.tryParse(iso)?.toLocal();

/// "Sep 10, 2026"; an unparseable value is shown as sent rather than hidden.
String formatDate(String? iso) {
  final date = _parse(iso);
  if (date == null) return iso ?? '';
  return '${_months[date.month - 1]} ${date.day}, ${date.year}';
}

/// "Sep 10, 2026, 9:33 PM".
String formatDateTime(String? iso) {
  final date = _parse(iso);
  if (date == null) return iso ?? '';
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  return '${formatDate(iso)}, $hour:$minute ${date.hour < 12 ? 'AM' : 'PM'}';
}

/// "12 minutes ago", "yesterday", "now". Truncated, so it never claims something is fresher than it is.
String timeAgo(String iso, DateTime now) {
  final then = DateTime.tryParse(iso);
  if (then == null) return iso;
  final elapsed = now.difference(then);
  final (count, unit) = switch (elapsed) {
    final e when e.inDays >= 1 => (e.inDays, 'day'),
    final e when e.inHours >= 1 => (e.inHours, 'hour'),
    final e when e.inMinutes >= 1 => (e.inMinutes, 'minute'),
    final e => (e.inSeconds < 0 ? 0 : e.inSeconds, 'second'),
  };
  if (count == 0) return 'now';
  if (count == 1 && unit == 'day') return 'yesterday';
  return '$count $unit${count == 1 ? '' : 's'} ago';
}
