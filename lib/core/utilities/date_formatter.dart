import 'package:intl/intl.dart';

class DateFormatter {
  static final _dayMonthYear = DateFormat('dd MMM yyyy');
  static final _dayMonth = DateFormat('dd MMM');
  static final _monthYear = DateFormat('MMMM yyyy');
  static final _isoDate = DateFormat('yyyy-MM-dd');
  static final _isoDateTime = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final _backupStamp = DateFormat('yyyy-MM-dd_HHmmss');

  static String format(DateTime date) => _dayMonthYear.format(date);
  static String formatDate(DateTime date) => _dayMonthYear.format(date);
  static String formatTime(DateTime date) => DateFormat('h:mm a').format(date);
  static String formatShort(DateTime date) => _dayMonth.format(date);
  static String formatMonthYear(DateTime date) => _monthYear.format(date);
  static String formatFullWithDay(DateTime date) => DateFormat('MMMM d, yyyy (E)').format(date);
  static String formatIso(DateTime date) => _isoDate.format(date);
  static String formatIsoDateTime(DateTime date) => _isoDateTime.format(date);
  static String formatBackupStamp(DateTime date) => _backupStamp.format(date);

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(itemDate).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference == -1) return 'Tomorrow';
    if (difference > 1 && difference < 7) {
      return DateFormat('EEEE').format(date); // Day of week
    }
    if (date.year == now.year) {
      return _dayMonth.format(date);
    }
    return _dayMonthYear.format(date);
  }
}
