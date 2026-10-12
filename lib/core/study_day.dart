/// Hour (local time) at which a new study day begins (PRD F8,
/// `day_start_hour`). Studying at 01:00 still counts for the day before.
const defaultDayStartHour = 4;

/// The hour in use, from Settings ([setDayStartHour]); dates already stored
/// keep the day they were given.
int get dayStartHour => _dayStartHour;
var _dayStartHour = defaultDayStartHour;

/// Hours a study day may start at (Settings).
const dayStartHours = [0, 1, 2, 3, 4, 5, 6];

void setDayStartHour(int hour) => _dayStartHour = dayStartHours.contains(hour) ? hour : defaultDayStartHour;

/// The study date of a local moment, as `yyyy-MM-dd`. It is fixed when the
/// activity happens and never recomputed after a time-zone change.
String studyDate(DateTime local, {int? dayStartHour}) {
  final shifted = local.subtract(Duration(hours: dayStartHour ?? _dayStartHour));
  String two(int n) => n.toString().padLeft(2, '0');
  return '${shifted.year}-${two(shifted.month)}-${two(shifted.day)}';
}

String todayStudyDate() => studyDate(DateTime.now());

/// Calendar day before [date] (`yyyy-MM-dd`).
String previousDate(String date) => addDays(date, -1);

/// [date] (`yyyy-MM-dd`) moved by [days] calendar days.
String addDays(String date, int days) => formatDate(parseDate(date).add(Duration(days: days)));

/// A `yyyy-MM-dd` date as midnight UTC, so day arithmetic ignores DST.
DateTime parseDate(String date) =>
    DateTime.utc(int.parse(date.substring(0, 4)), int.parse(date.substring(5, 7)), int.parse(date.substring(8)));

String formatDate(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}
