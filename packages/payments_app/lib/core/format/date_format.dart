import 'package:intl/intl.dart';

/// Date labels in the user's local time.
abstract final class DateLabels {
  /// `Today`, `Yesterday`, `21 September`, or `21 September 2025` outside
  /// the current year. Used for grouping lists by day.
  static String day(DateTime date, {required DateTime now}) {
    final local = _dateOnly(date.toLocal());
    final today = _dateOnly(now.toLocal());
    final difference = today.difference(local).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return local.year == today.year
        ? DateFormat('d MMMM', 'en_US').format(local)
        : DateFormat('d MMMM y', 'en_US').format(local);
  }

  /// `Today, 14:32`, `Yesterday, 09:05`, `21 Sep`.
  static String short(DateTime date, {required DateTime now}) {
    final label = day(date, now: now);
    if (label == 'Today' || label == 'Yesterday') {
      return '$label, ${time(date)}';
    }
    final local = date.toLocal();
    return local.year == now.toLocal().year
        ? DateFormat('d MMM', 'en_US').format(local)
        : DateFormat('d MMM y', 'en_US').format(local);
  }

  /// `14:32`.
  static String time(DateTime date) =>
      DateFormat('HH:mm', 'en_US').format(date.toLocal());

  /// `28 Sep 2026, 14:32`.
  static String full(DateTime date) =>
      DateFormat('d MMM y, HH:mm', 'en_US').format(date.toLocal());

  /// `September`.
  static String month(DateTime date) =>
      DateFormat('MMMM', 'en_US').format(date.toLocal());

  /// Whole days/hours/minutes until [expiresAt]: `23 h`, `45 min`.
  static String remaining(DateTime expiresAt, {required DateTime now}) {
    final left = expiresAt.difference(now);
    if (left.inHours >= 1) return '${left.inHours} h';
    if (left.inMinutes >= 1) return '${left.inMinutes} min';
    return 'less than a minute';
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
