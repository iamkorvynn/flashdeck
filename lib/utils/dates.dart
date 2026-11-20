// Small date helpers used by scheduling and stats. No intl dependency.

const List<String> _months = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Midnight at the start of [date]'s day, local time.
DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

/// Midnight [days] days after today (or after [from] when given).
DateTime daysFromNow(int days, {DateTime? from}) {
  final base = startOfDay(from ?? DateTime.now());
  return base.add(Duration(days: days));
}

/// True when both instants fall on the same calendar day.
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Short human date, e.g. "20 Nov 2026".
String formatShortDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

/// Short human date and time, e.g. "20 Nov, 09:31".
String formatShortDateTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.day} ${_months[date.month - 1]}, $hour:$minute';
}

/// Whole days from today until [date] (negative when overdue).
int daysUntil(DateTime date) =>
    startOfDay(date).difference(startOfDay(DateTime.now())).inDays;
