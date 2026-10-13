import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/audio/speech.dart';
import '../../core/database/providers.dart';
import '../../core/study_day.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/game_card.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_service.dart';
import '../auth/delete_account_screen.dart';
import '../learn/study_language.dart';
import '../onboarding/learning_level.dart';
import '../progress/about_screen.dart';
import '../progress/progress_providers.dart';
import '../reminders/reminder_plan.dart';
import '../reminders/reminder_service.dart';
import '../srs/srs_providers.dart';
import '../sync/sync_controller.dart';
import 'settings_providers.dart';
import 'theme_sheet.dart';

/// Settings at the bottom of "Saya" (PRD F9): one row per setting showing its
/// value; a tap opens a sheet with the choices. Learning settings sync,
/// appearance stays on this device.
class SettingsSection extends ConsumerWidget {
  const SettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final goal = ref.watch(dailyGoalProvider).value ?? DailyGoal.fallback;
    final direction = ref.watch(cardDirectionProvider).value ?? CardDirection.jpToMeaning;
    final limits = ref.watch(srsLimitsProvider).value ?? const SrsLimits();
    final dayStart = ref.watch(dayStartHourProvider).value ?? defaultDayStartHour;
    final look = ref.watch(appearanceProvider).value ?? defaultAppearance;
    final level = ref.watch(learningLevelProvider).value;
    final studying = ref.watch(studyLanguageProvider).value ?? StudyLanguage.ja;

    String goalName(DailyGoal g) => switch (g) {
      DailyGoal.relaxed => l10n.goalRelaxed,
      DailyGoal.regular => l10n.goalRegular,
      DailyGoal.serious => l10n.goalSerious,
    };
    String directionName(CardDirection d) => switch (d) {
      CardDirection.jpToMeaning => l10n.directionJpToMeaning,
      CardDirection.meaningToJp => l10n.directionMeaningToJp,
      CardDirection.both => l10n.directionBoth,
    };
    String hour(int h) => DateFormat.Hm(l10n.localeName).format(DateTime(2000, 1, 1, h));
    String languageName(LanguageChoice l) => switch (l) {
      LanguageChoice.system => l10n.followSystem,
      // Each language in its own name.
      LanguageChoice.id => 'Bahasa Indonesia',
      LanguageChoice.en => 'English',
    };
    String themeName(ThemeChoice t) => switch (t) {
      ThemeChoice.dark => l10n.themeDark,
      ThemeChoice.light => l10n.themeLight,
      ThemeChoice.system => l10n.followSystem,
    };
    String sizeName(TextSize s) => switch (s) {
      TextSize.normal => l10n.textNormal,
      TextSize.large => l10n.textLarge,
      TextSize.larger => l10n.textLarger,
    };
    final currentGoal = DailyGoal.values.where((g) => g.cards == goal).firstOrNull;

    return GameCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GroupLabel(l10n.settingsLearning),
          _SettingTile(
            title: l10n.studyLanguage,
            value: '${studying.flag} ${studyLanguageName(l10n, studying)}',
            onTap: () => _pick<StudyLanguage>(
              context,
              title: l10n.studyLanguage,
              note: l10n.studyLanguageNote,
              selected: studying,
              options: [
                for (final l in StudyLanguage.values)
                  (
                    l,
                    '${l.flag} ${studyLanguageName(l10n, l)}',
                    l == StudyLanguage.ja ? l10n.languageJapaneseBody : l10n.languageKoreanBody,
                  ),
              ],
              onSelected: (v) => selectStudyLanguage(ref, v),
            ),
          ),
          _SettingTile(
            title: l10n.learningLevel,
            value: level == null ? l10n.levelNotChosen : learningLevelLabel(l10n, level),
            onTap: () => _pick<LearningLevel?>(
              context,
              title: l10n.learningLevel,
              note: l10n.learningLevelNote,
              selected: level,
              options: [for (final l in LearningLevel.values) (l, learningLevelLabel(l10n, l), null)],
              onSelected: (v) {
                if (v != null) applyLearningLevel(ref, v);
              },
            ),
          ),
          _SettingTile(
            title: l10n.dailyGoal,
            value: currentGoal == null ? l10n.cardsCount(goal) : goalName(currentGoal),
            onTap: () => _pick<int>(
              context,
              title: l10n.dailyGoal,
              note: l10n.dailyGoalNote,
              selected: goal,
              options: [
                for (final g in DailyGoal.values)
                  (g.cards, goalName(g), l10n.goalOption(g.minutes, g.cards, g.newCards)),
              ],
              onSelected: (v) {
                if (DailyGoal.values.where((g) => g.cards == v).firstOrNull case final g?) setDailyGoal(ref, g);
              },
            ),
          ),
          _SettingTile(
            title: l10n.newPerDay,
            value: l10n.cardsCount(limits.newPerDay),
            onTap: () => _pick<int>(
              context,
              title: l10n.newPerDay,
              note: l10n.newPerDayNote,
              selected: limits.newPerDay,
              options: [for (final n in SrsLimits.newOptions) (n, l10n.cardsCount(n), null)],
              onSelected: (v) => saveSetting(ref, SrsLimits.newKey, '$v'),
            ),
          ),
          _SettingTile(
            title: l10n.reviewsPerDay,
            value: l10n.cardsCount(limits.reviewsPerDay),
            onTap: () => _pick<int>(
              context,
              title: l10n.reviewsPerDay,
              note: l10n.reviewsPerDayNote,
              selected: limits.reviewsPerDay,
              options: [for (final n in SrsLimits.reviewOptions) (n, l10n.cardsCount(n), null)],
              onSelected: (v) => saveSetting(ref, SrsLimits.reviewsKey, '$v'),
            ),
          ),
          _SettingTile(
            title: l10n.cardDirection,
            value: directionName(direction),
            onTap: () => _pick<CardDirection>(
              context,
              title: l10n.cardDirection,
              note: l10n.directionNote,
              selected: direction,
              options: [for (final d in CardDirection.values) (d, directionName(d), null)],
              onSelected: (v) => setCardDirection(ref, v),
            ),
          ),
          _SettingTile(
            title: l10n.dayStart,
            value: hour(dayStart),
            onTap: () => _pick<int>(
              context,
              title: l10n.dayStart,
              note: l10n.dayStartNote,
              selected: dayStart,
              options: [for (final h in dayStartHours) (h, hour(h), null)],
              onSelected: (v) => saveSetting(ref, dayStartKey, '$v'),
            ),
          ),
          Divider(color: c.line, height: AppSpace.l),
          _GroupLabel(l10n.settingsAppearance),
          _SettingTile(
            title: l10n.language,
            value: languageName(look.language),
            onTap: () => _pick<LanguageChoice>(
              context,
              title: l10n.language,
              selected: look.language,
              options: [for (final l in LanguageChoice.values) (l, languageName(l), null)],
              onSelected: (v) => saveSetting(ref, LanguageChoice.settingKey, v.name),
            ),
          ),
          _SettingTile(
            title: l10n.theme,
            value: '${themeName(look.theme)} · ${paletteName(l10n, look.palette)}',
            onTap: () => ThemeSheet.show(context),
          ),
          _SettingTile(
            title: l10n.textSize,
            value: sizeName(look.textSize),
            onTap: () => _pick<TextSize>(
              context,
              title: l10n.textSize,
              selected: look.textSize,
              options: [for (final s in TextSize.values) (s, sizeName(s), null)],
              onSelected: (v) => saveSetting(ref, TextSize.settingKey, v.name),
            ),
          ),
          Divider(color: c.line, height: AppSpace.l),
          _GroupLabel(l10n.settingsSound),
          SwitchListTile(
            title: Text(l10n.speechAutoplay, style: AppText.body.copyWith(color: c.ink)),
            subtitle: Text(l10n.speechAutoplayNote, style: AppText.bodySmall.copyWith(color: c.inkMuted)),
            value: ref.watch(speechAutoplayProvider).value ?? true,
            onChanged: (on) => saveSetting(ref, speechAutoplayKey, on ? 'on' : 'off'),
          ),
          Divider(color: c.line, height: AppSpace.l),
          _GroupLabel(l10n.settingsNotifications),
          const _ReminderTiles(),
          if (ref.watch(authServiceProvider) != null) ...[
            Divider(color: c.line, height: AppSpace.l),
            _GroupLabel(l10n.settingsAccount),
            const _AccountTiles(),
          ],
          Divider(color: c.line, height: AppSpace.l),
          ListTile(
            leading: Icon(Icons.info_outline_rounded, color: c.inkMuted),
            title: Text(l10n.aboutAttribution, style: AppText.body.copyWith(color: c.ink)),
            trailing: Icon(Icons.chevron_right_rounded, color: c.inkMuted),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AboutScreen())),
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpace.l, AppSpace.m, AppSpace.l, AppSpace.xs),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: AppText.body.copyWith(color: context.colors.ink, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({required this.title, required this.value, required this.onTap});

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListTile(
      title: Text(title, style: AppText.body.copyWith(color: c.ink)),
      subtitle: Text(value, style: AppText.bodySmall.copyWith(color: c.primaryText)),
      trailing: Icon(Icons.chevron_right_rounded, color: c.inkMuted),
      onTap: onTap,
    );
  }
}

/// Signed-in email, sync state, sign out and delete account (PRD F9, UI §6). Signing out
/// first saves what is left to the account, warns if that fails, then clears
/// this phone's copy of the account.
class _AccountTiles extends ConsumerWidget {
  const _AccountTiles();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final auth = ref.watch(authServiceProvider)!;
    final user = ref.watch(authUserProvider).value ?? auth.currentUser;
    final sync = ref.watch(syncProvider);

    Future<bool> confirm(String title, String body, String action) async =>
        await showDialog<bool>(
          context: context,
          useRootNavigator: true,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
              ),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(action)),
            ],
          ),
        ) ==
        true;

    Future<void> signOut() async {
      if (!await confirm(l10n.signOutTitle, l10n.signOutBody, l10n.signOut) || !context.mounted) return;
      final navigator = Navigator.of(context, rootNavigator: true);
      unawaited(
        showDialog<void>(
          context: context,
          useRootNavigator: true,
          barrierDismissible: false,
          builder: (context) => PopScope(
            canPop: false,
            child: AlertDialog(
              content: Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: AppSpace.l),
                  Expanded(child: Text(l10n.savingToAccount)),
                ],
              ),
            ),
          ),
        ),
      );
      final left = await ref.read(syncProvider.notifier).flush();
      navigator.pop();
      if (left > 0 &&
          (!context.mounted ||
              !await confirm(l10n.signOutUnsyncedTitle, l10n.signOutUnsyncedBody(left), l10n.signOutAnyway))) {
        return;
      }
      final db = await ref.read(userDbProvider.future);
      try {
        await auth.signOut();
      } catch (e) {
        // Offline: the local session is gone anyway.
        debugPrint('sign out: $e');
      }
      // The sign-in screen covers the app by now; the next account starts
      // from what the cloud has (owner_user_id stays as a safeguard).
      await db.clearAccountData();
    }

    final String syncText;
    if (sync.phase == SyncPhase.syncing) {
      syncText = l10n.syncRunning;
    } else if (sync.phase == SyncPhase.failed) {
      syncText = sync.offline ? l10n.syncOffline : l10n.syncFailed;
    } else if (sync.pending > 0) {
      syncText = l10n.syncPending(sync.pending);
    } else if (sync.lastSyncedAt case final at?) {
      final locale = Localizations.localeOf(context).toLanguageTag();
      final local = at.toLocal();
      final now = DateTime.now();
      final today = local.year == now.year && local.month == now.month && local.day == now.day;
      syncText = l10n.syncDoneAt((today ? DateFormat.Hm(locale) : DateFormat.MMMd(locale).add_Hm()).format(local));
    } else {
      syncText = l10n.syncDone;
    }

    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.account_circle_outlined, color: c.inkMuted),
          title: Text(l10n.signedInAs, style: AppText.body.copyWith(color: c.ink)),
          subtitle: Text(user?.email ?? '–', style: AppText.bodySmall.copyWith(color: c.primaryText)),
        ),
        Semantics(
          onTapHint: l10n.syncNowHint,
          child: ListTile(
            leading: Icon(
              sync.phase == SyncPhase.failed ? Icons.cloud_off_outlined : Icons.cloud_done_outlined,
              color: sync.phase == SyncPhase.failed && !sync.offline ? c.seal : c.inkMuted,
            ),
            title: Text(l10n.syncLabel, style: AppText.body.copyWith(color: c.ink)),
            subtitle: Semantics(
              liveRegion: true,
              child: Text(syncText, style: AppText.bodySmall.copyWith(color: c.primaryText)),
            ),
            trailing: sync.phase == SyncPhase.syncing
                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.sync_rounded, color: c.inkMuted),
            onTap: sync.phase == SyncPhase.syncing ? null : () => ref.read(syncProvider.notifier).sync(),
          ),
        ),
        ListTile(
          leading: Icon(Icons.logout_rounded, color: c.seal),
          title: Text(l10n.signOut, style: AppText.body.copyWith(color: c.seal)),
          onTap: signOut,
        ),
        ListTile(
          leading: Icon(Icons.person_remove_outlined, color: c.inkMuted),
          title: Text(l10n.deleteAccount, style: AppText.body.copyWith(color: c.ink)),
          trailing: Icon(Icons.chevron_right_rounded, color: c.inkMuted),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DeleteAccountScreen())),
        ),
      ],
    );
  }
}

/// Daily reminder on/off and its time (PRD F9). Permission is asked when it
/// is switched on, never at launch; a refusal leaves it off and points to the
/// phone's settings.
class _ReminderTiles extends ConsumerWidget {
  const _ReminderTiles();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final time = ref.watch(reminderTimeProvider).value;
    String format(ReminderTime t) => DateFormat.Hm(l10n.localeName).format(DateTime(2000, 1, 1, t.hour, t.minute));

    Future<void> switchOn() async {
      final service = ref.read(reminderServiceProvider);
      final messenger = ScaffoldMessenger.of(context);
      if (await service.requestPermission()) {
        saveSetting(ref, ReminderTime.settingKey, ReminderTime.suggested.value);
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.reminderDenied),
          action: SnackBarAction(label: l10n.openSettings, onPressed: service.openSettings),
        ),
      );
    }

    Future<void> pickTime(ReminderTime current) async {
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
        helpText: l10n.reminderTime,
      );
      if (picked == null) return;
      saveSetting(ref, ReminderTime.settingKey, ReminderTime(picked.hour, picked.minute).value);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          title: Text(l10n.dailyReminder, style: AppText.body.copyWith(color: c.ink)),
          subtitle: Text(l10n.reminderNote, style: AppText.bodySmall.copyWith(color: c.inkMuted)),
          value: time != null,
          onChanged: (on) => on ? switchOn() : saveSetting(ref, ReminderTime.settingKey, 'off'),
        ),
        if (time != null) _SettingTile(title: l10n.reminderTime, value: format(time), onTap: () => pickTime(time)),
      ],
    );
  }
}

/// A sheet with one radio per option; choosing one saves it and closes.
Future<void> _pick<T>(
  BuildContext context, {
  required String title,
  String? note,
  required T selected,
  required List<(T, String, String?)> options,
  required ValueChanged<T> onSelected,
}) => showModalBottomSheet<void>(
  context: context,
  // Above the tab bar, not inside the tab.
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (context) {
    final c = context.colors;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpace.m),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
              child: Text(title, style: AppText.title2.copyWith(color: c.ink)),
            ),
            if (note != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.xs, AppSpace.screen, 0),
                child: Text(note, style: AppText.bodySmall.copyWith(color: c.inkMuted)),
              ),
            const SizedBox(height: AppSpace.s),
            RadioGroup<T>(
              groupValue: selected,
              onChanged: (v) {
                if (v == null) return;
                onSelected(v);
                Navigator.of(context).pop();
              },
              child: Column(
                children: [
                  for (final (value, label, subtitle) in options)
                    RadioListTile<T>(
                      value: value,
                      title: Text(label, style: AppText.body.copyWith(color: c.ink)),
                      subtitle: subtitle == null
                          ? null
                          : Text(subtitle, style: AppText.bodySmall.copyWith(color: c.inkMuted)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  },
);
