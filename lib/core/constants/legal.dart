/// What the notice's QR code opens (`assets/images/legal_qr.svg` encodes exactly this).
const legalUrl = 'https://plodyo.com/tos';

/// The short address to type instead.
const legalAddress = 'plodyo.com/tos';

/// Shown again once the TV has sat this long untouched: hotel TVs rarely restart between guests.
const noticeIdleLimit = Duration(hours: 4);

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// The backend's effective date, `2026-10-25`, as "Terms effective 25 October 2026".
String termsEffectiveLine(String date) {
  final [year, month, day] = date.split('-').map(int.parse).toList();
  return 'Terms effective $day ${_months[month - 1]} $year';
}
