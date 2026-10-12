import '../../core/database/user_db.dart';
import '../../core/study_day.dart';
import '../../l10n/app_localizations.dart';
import '../progress/progress_providers.dart';
import '../progress/streak.dart';
import '../srs/srs_providers.dart';

/// Daily reminder time (PRD F9), stored as `HH:mm` under [settingKey]; no
/// value means reminders are off. Stays on this device: reminders are per
/// phone.
class ReminderTime {
  const ReminderTime(this.hour, this.minute);

  final int hour;
  final int minute;

  static const settingKey = 'device.reminder';

  /// Offered when reminders are first switched on.
  static const suggested = ReminderTime(19, 0);

  static ReminderTime? parse(String? v) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(v ?? '');
    if (m == null) return null;
    final h = int.parse(m[1]!), min = int.parse(m[2]!);
    return h < 24 && min < 60 ? ReminderTime(h, min) : null;
  }

  String get value => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) => other is ReminderTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}

/// What the reminders are worded from, read when they are scheduled.
typedef ReminderContext = ({String today, bool activeToday, bool goalReached, int streak, int dueCards});

class PlannedReminder {
  const PlannedReminder(this.at, this.body);

  /// Local time.
  final DateTime at;
  final String body;
}

/// The next [days] reminders from [now]. Today's is skipped once the daily
/// goal is reached. Only today's knows the numbers (streak, cards due); later
/// ones are a plain nudge until the app re-plans them. Wording never blames
/// (ui-design §11).
List<PlannedReminder> planReminders({
  required DateTime now,
  required ReminderTime time,
  required ReminderContext context,
  required AppLocalizations l10n,
  int days = 7,
}) {
  final out = <PlannedReminder>[];
  for (var d = 0; out.length < days && d <= days; d++) {
    final at = DateTime(now.year, now.month, now.day + d, time.hour, time.minute);
    if (!at.isAfter(now)) continue;
    final forToday = studyDate(at) == context.today;
    if (forToday && context.goalReached) continue;
    final String body;
    if (forToday && context.streak > 0 && !context.activeToday) {
      body = l10n.reminderStreak(context.streak);
    } else if (forToday && context.dueCards > 0) {
      body = l10n.reminderCards(context.dueCards, (context.dueCards / 2).ceil().clamp(1, 60));
    } else {
      body = l10n.reminderPlain;
    }
    out.add(PlannedReminder(at, body));
  }
  return out;
}

/// Reads [ReminderContext] straight from user.db, so it works when no screen
/// is watching the progress providers.
Future<ReminderContext> loadReminderContext(UserDb db) async {
  final today = todayStudyDate();
  final days = await db.watchDayTotals().first;
  final frozen = await db.watchFreezeDates().first;
  final goal = int.tryParse(await db.setting(DailyGoal.settingKey) ?? '') ?? DailyGoal.fallback;
  final todayTotals = days.where((d) => d.date == today).firstOrNull;
  final streak = Streak.compute(
    {
      for (final d in days)
        if (d.active) d.date,
    },
    frozen,
    today,
  );
  final counts = await db.watchCardCounts(nowUtc()).first;
  final newLeft = await newLeftToday(db);
  return (
    today: today,
    activeToday: todayTotals?.active ?? false,
    goalReached: (todayTotals?.cards ?? 0) >= goal,
    streak: streak.current,
    dueCards: counts.due + (counts.fresh < newLeft ? counts.fresh : newLeft),
  );
}
