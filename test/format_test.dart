import 'package:flutter_test/flutter_test.dart';
import 'package:plodyo_ondemand_tv/core/utils/format.dart';

void main() {
  final now = DateTime.utc(2026, 10, 9, 12);
  String ago(Duration elapsed) =>
      timeAgo(now.subtract(elapsed).toIso8601String(), now);

  test(
    'timeAgo reads like the reference (Intl.RelativeTimeFormat, numeric: auto)',
    () {
      expect(ago(Duration.zero), 'now');
      expect(ago(const Duration(seconds: 1)), '1 second ago');
      expect(ago(const Duration(seconds: 59)), '59 seconds ago');
      expect(ago(const Duration(minutes: 1, seconds: 59)), '1 minute ago');
      expect(ago(const Duration(minutes: 12)), '12 minutes ago');
      expect(ago(const Duration(hours: 3)), '3 hours ago');
      expect(ago(const Duration(days: 1, hours: 5)), 'yesterday');
      expect(ago(const Duration(days: 4)), '4 days ago');
      // A clock skewed ahead of the server never shows a future time.
      expect(ago(const Duration(minutes: -2)), 'now');
    },
  );

  test(
    'formatDateTime uses the 12-hour clock with midnight and noon as 12',
    () {
      final midnight = DateTime(2026, 9, 10, 0, 5).toIso8601String();
      final noon = DateTime(2026, 9, 10, 12, 30).toIso8601String();
      expect(formatDateTime(midnight), 'Sep 10, 2026, 12:05 AM');
      expect(formatDateTime(noon), 'Sep 10, 2026, 12:30 PM');
      expect(formatDate('not a date'), 'not a date');
    },
  );
}
