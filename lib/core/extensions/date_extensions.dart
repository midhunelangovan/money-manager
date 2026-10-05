extension DateTimeExtensions on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  DateTime get startOfWeek {
    final diff = weekday - DateTime.monday;
    final monday = subtract(Duration(days: diff));
    return DateTime(monday.year, monday.month, monday.day);
  }

  DateTime get endOfWeek {
    final diff = DateTime.sunday - weekday;
    final sunday = add(Duration(days: diff));
    return DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59, 999);
  }

  DateTime get startOfMonth => DateTime(year, month, 1);
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59, 999);

  DateTime get startOfYear => DateTime(year, 1, 1);
  DateTime get endOfYear => DateTime(year, 12, 31, 23, 59, 59, 999);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  bool isSameMonth(DateTime other) =>
      year == other.year && month == other.month;
}
