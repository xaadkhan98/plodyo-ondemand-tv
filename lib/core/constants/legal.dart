/// The Terms the TV notice asks grown-ups to accept, named by their effective date.
const termsVersion = '2026-10-25';

/// What the notice's QR code opens (`assets/images/legal_qr.svg` encodes exactly this).
const legalUrl = 'https://ondemand.plodyo.com/legal?src=tv';

/// The short address to type instead.
const legalAddress = 'ondemand.plodyo.com';

/// Shown again once the TV has sat this long untouched: hotel TVs rarely restart between guests.
const noticeIdleLimit = Duration(hours: 4);
