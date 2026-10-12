import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/database/providers.dart';
import '../../core/database/user_db.dart';
import '../../l10n/app_localizations.dart';
import 'reminder_plan.dart';

/// Local notifications for the daily reminder (PRD F9). Reminders are
/// scheduled a week ahead with inexact alarms and re-planned whenever the app
/// goes to the background, so the first one carries current numbers. Does
/// nothing off Android/iOS (tests, desktop).
class ReminderService {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<bool>? _ready;

  static bool get supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<bool> _init() => _ready ??= () async {
    if (!supported) return false;
    try {
      tzdata.initializeTimeZones();
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_reminder'),
          // Asked for when reminders are switched on, not at launch.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      return true;
    } catch (e) {
      debugPrint('reminders unavailable: $e');
      return false;
    }
  }();

  /// Asks for permission to notify (Android 13+, iOS). True when allowed.
  Future<bool> requestPermission() async {
    if (!await _init()) return false;
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  /// The phone's notification settings for this app, for after a refusal.
  Future<void> openSettings() async {
    if (!await _init()) return;
    try {
      await _plugin.openAppNotificationSettings();
    } catch (e) {
      debugPrint('notification settings not opened: $e');
    }
  }

  /// Replaces every pending reminder with [plan].
  Future<void> schedule(List<PlannedReminder> plan, AppLocalizations l10n) async {
    if (!await _init()) return;
    await _plugin.cancelAllPendingNotifications();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_reminder',
        l10n.reminderChannel,
        channelDescription: l10n.reminderChannelNote,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(),
    );
    for (final (i, r) in plan.indexed) {
      await _plugin.zonedSchedule(
        id: i + 1,
        title: l10n.appTitle,
        body: r.body,
        scheduledDate: tz.TZDateTime.from(r.at, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> cancel() async {
    if (!await _init()) return;
    await _plugin.cancelAllPendingNotifications();
  }

  Future<void> _last = Future.value();

  /// Re-plans the reminders from the saved time and today's progress, or
  /// cancels them when reminders are off. Calls run one after another.
  /// Errors are logged: a missed re-plan only leaves the previous plan.
  Future<void> refresh(Future<UserDb> userDb, Locale locale) {
    if (!supported) return Future.value();
    return _last = _last.then((_) async {
      try {
        final db = await userDb;
        final time = ReminderTime.parse(await db.setting(ReminderTime.settingKey));
        if (time == null) return await cancel();
        final l10n = await AppLocalizations.delegate.load(locale);
        final context = await loadReminderContext(db);
        await schedule(planReminders(now: DateTime.now(), time: time, context: context, l10n: l10n), l10n);
      } catch (e) {
        debugPrint('reminders not re-planned: $e');
      }
    });
  }
}

final reminderServiceProvider = Provider<ReminderService>((ref) => ReminderService());

final reminderTimeProvider = StreamProvider<ReminderTime?>((ref) async* {
  final db = await ref.watch(userDbProvider.future);
  yield* db.watchSetting(ReminderTime.settingKey).map(ReminderTime.parse);
});

/// Keeps the scheduled reminders current: re-plans when the reminder time or
/// language changes and whenever the app is opened or left, so the next
/// reminder knows today's progress.
class ReminderScheduler extends ConsumerStatefulWidget {
  const ReminderScheduler({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<ReminderScheduler> createState() => _ReminderSchedulerState();
}

class _ReminderSchedulerState extends ConsumerState<ReminderScheduler> {
  late final AppLifecycleListener _lifecycle;
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _refresh, onHide: _refresh);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (locale != _locale) {
      _locale = locale;
      _refresh();
    }
  }

  void _refresh() {
    final locale = _locale;
    if (locale == null) return;
    ref.read(reminderServiceProvider).refresh(ref.read(userDbProvider.future), locale);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(reminderTimeProvider, (prev, next) {
      if (prev?.value != next.value && next.hasValue) _refresh();
    });
    return widget.child;
  }
}
