import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/chunky_button.dart';
import '../../core/widgets/level_badge.dart';
import '../../l10n/app_localizations.dart';
import '../progress/progress_providers.dart';
import '../reminders/reminder_plan.dart';
import '../reminders/reminder_service.dart';
import 'learning_level.dart';

/// First launch (PRD F9, ui-design §5.1): level, daily goal, reminder. Sign-in
/// comes before this once Auth exists. Everything chosen here can be changed
/// later in Settings; the level is saved last because it ends onboarding.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

/// "Belum tahu" is a choice of its own until the self-check answers it.
enum _Pick { level, unsure }

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _steps = 3;
  int _step = 0;

  _Pick? _pick;
  LearningLevel? _level;
  final _answers = <int, bool>{};
  DailyGoal _goal = DailyGoal.regular;
  ReminderTime _reminder = ReminderTime.suggested;
  bool _finishing = false;

  /// The level to start from: the picked one, or the self-check result once
  /// all three questions are answered.
  LearningLevel? get _chosen => switch (_pick) {
    _Pick.level => _level,
    _Pick.unsure when _answers.length == 3 => selfCheckLevel(
      hiragana: _answers[0]!,
      katakana: _answers[1]!,
      basicWords: _answers[2]!,
    ),
    _ => null,
  };

  void _back() => setState(() => _step--);

  void _next() {
    HapticFeedback.selectionClick();
    setState(() => _step++);
  }

  Future<void> _finish({required bool remind}) async {
    final level = _chosen;
    if (level == null || _finishing) return;
    setState(() => _finishing = true);
    var reminderOn = false;
    if (remind) reminderOn = await ref.read(reminderServiceProvider).requestPermission();
    try {
      final db = await ref.read(userDbProvider.future);
      await _goal.save(db);
      // Refused permission: reminders stay off; Settings can turn them on.
      await db.setSetting(ReminderTime.settingKey, reminderOn ? _reminder.value : 'off');
    } catch (e) {
      debugPrint('onboarding choices not saved: $e');
    }
    if (!mounted) return;
    applyLearningLevel(ref, level);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final page = switch (_step) {
      0 => _levelPage(l10n, c),
      1 => _goalPage(l10n, c),
      _ => _reminderPage(l10n, c),
    };
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 56,
                child: Row(
                  children: [
                    if (_step > 0)
                      IconButton(
                        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: _back,
                      )
                    else
                      const SizedBox(width: 48),
                    Expanded(
                      child: Semantics(
                        label: l10n.onboardingStep(_step + 1, _steps),
                        child: ExcludeSemantics(
                          child: _StepBar(step: _step, steps: _steps),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppDurations.press * 2,
                  child: KeyedSubtree(key: ValueKey(_step), child: page),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _title(AppColors c, String title, String subtitle) => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.m, AppSpace.screen, AppSpace.l),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: AppText.title1.copyWith(color: c.ink)),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(subtitle, style: AppText.body.copyWith(color: c.inkMuted)),
      ],
    ),
  );

  /// Scrolling content with the main button fixed at the bottom (thumb zone).
  Widget _layout({required List<Widget> children, required Widget button, Widget? secondary}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpace.l),
          children: children,
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.s, AppSpace.screen, AppSpace.m),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [button, ?secondary]),
      ),
    ],
  );

  Widget _levelPage(AppLocalizations l10n, AppColors c) {
    String name(LearningLevel l) => learningLevelName(l10n, l);
    String about(LearningLevel l) => switch (l) {
      LearningLevel.preN5 => l10n.levelFromZeroBody,
      LearningLevel.n5 => l10n.levelBeginnerBody,
      LearningLevel.n4 => l10n.levelBasicBody,
      LearningLevel.n3 => l10n.levelIntermediateBody,
      LearningLevel.n2 => l10n.levelUpperIntermediateBody,
      LearningLevel.n1 => l10n.levelAdvancedBody,
    };
    final questions = [l10n.selfCheckHiragana, l10n.selfCheckKatakana, l10n.selfCheckWords];
    final result = _pick == _Pick.unsure ? _chosen : null;

    return _layout(
      children: [
        _title(c, l10n.levelQuestion, l10n.levelChangeLater),
        for (final l in LearningLevel.values)
          _Option(
            title: name(l),
            body: about(l),
            trailing: l.jlpt == null ? null : LevelBadge(l.jlpt!),
            selected: _pick == _Pick.level && _level == l,
            onTap: () => setState(() {
              _pick = _Pick.level;
              _level = l;
            }),
          ),
        _Option(
          title: l10n.levelUnsure,
          body: l10n.levelUnsureBody,
          selected: _pick == _Pick.unsure,
          onTap: () => setState(() => _pick = _Pick.unsure),
        ),
        // The self-check opens on this same screen (ui-design §5.1).
        if (_pick == _Pick.unsure)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, q) in questions.indexed)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.m),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(q, style: AppText.body.copyWith(color: c.ink)),
                        const SizedBox(height: AppSpace.xs),
                        SegmentedButton<bool>(
                          segments: [
                            ButtonSegment(value: true, label: Text(l10n.yes)),
                            ButtonSegment(value: false, label: Text(l10n.no)),
                          ],
                          emptySelectionAllowed: true,
                          selected: {?_answers[i]},
                          onSelectionChanged: (s) => setState(() {
                            if (s.isEmpty) {
                              _answers.remove(i);
                            } else {
                              _answers[i] = s.first;
                            }
                          }),
                        ),
                      ],
                    ),
                  ),
                if (result != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.l),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        l10n.selfCheckResult(learningLevelLabel(l10n, result)),
                        style: AppText.body.copyWith(color: c.primaryText, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
      button: ChunkyButton(label: l10n.next, onPressed: _chosen == null ? null : _next),
    );
  }

  Widget _goalPage(AppLocalizations l10n, AppColors c) {
    String name(DailyGoal g) => switch (g) {
      DailyGoal.relaxed => l10n.goalRelaxed,
      DailyGoal.regular => l10n.goalRegular,
      DailyGoal.serious => l10n.goalSerious,
    };
    return _layout(
      children: [
        _title(c, l10n.goalQuestion, l10n.goalQuestionBody),
        for (final g in DailyGoal.values)
          _Option(
            title: name(g),
            body: l10n.goalOption(g.minutes, g.cards, g.newCards),
            selected: _goal == g,
            onTap: () => setState(() => _goal = g),
          ),
      ],
      button: ChunkyButton(label: l10n.next, onPressed: _next),
    );
  }

  Widget _reminderPage(AppLocalizations l10n, AppColors c) {
    final time = DateFormat.Hm(l10n.localeName).format(DateTime(2000, 1, 1, _reminder.hour, _reminder.minute));
    return _layout(
      children: [
        _title(c, l10n.reminderQuestion, l10n.reminderQuestionBody),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
          child: Material(
            color: c.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              side: BorderSide(color: c.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: AppSpace.s),
              leading: Icon(Icons.notifications_active_outlined, color: c.primaryText),
              title: Text(l10n.reminderTime, style: AppText.body.copyWith(color: c.inkMuted)),
              subtitle: Text(time, style: AppText.title1.copyWith(color: c.ink)),
              trailing: Icon(Icons.edit_rounded, color: c.inkMuted),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: _reminder.hour, minute: _reminder.minute),
                  helpText: l10n.reminderTime,
                );
                if (picked != null) setState(() => _reminder = ReminderTime(picked.hour, picked.minute));
              },
            ),
          ),
        ),
      ],
      button: ChunkyButton(label: l10n.remindMe, onPressed: _finishing ? null : () => _finish(remind: true)),
      secondary: Padding(
        padding: const EdgeInsets.only(top: AppSpace.s),
        child: TextButton(onPressed: _finishing ? null : () => _finish(remind: false), child: Text(l10n.skip)),
      ),
    );
  }
}

/// Thin progress bar of the onboarding steps.
class _StepBar extends StatelessWidget {
  const _StepBar({required this.step, required this.steps});
  final int step;
  final int steps;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      spacing: AppSpace.xs,
      children: [
        for (var i = 0; i < steps; i++)
          Expanded(
            child: AnimatedContainer(
              duration: AppDurations.press * 2,
              height: 6,
              decoration: BoxDecoration(
                color: i <= step ? c.primary : c.surfaceHigh,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
      ],
    );
  }
}

/// A selectable card: chosen shows a 2 dp primary border and a check, so the
/// choice is never color only (ui-design §5.1).
class _Option extends StatelessWidget {
  const _Option({required this.title, required this.body, required this.selected, required this.onTap, this.trailing});

  final String title;
  final String body;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.s),
      child: Semantics(
        selected: selected,
        inMutuallyExclusiveGroup: true,
        button: true,
        child: Material(
          color: selected ? c.surfaceHigh : c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
            side: BorderSide(color: selected ? c.primary : c.line, width: selected ? 2 : 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.l),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppText.body.copyWith(color: c.ink, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(body, style: AppText.bodySmall.copyWith(color: c.inkMuted)),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[const SizedBox(width: AppSpace.s), trailing!],
                  if (selected) ...[
                    const SizedBox(width: AppSpace.s),
                    Icon(Icons.check_circle_rounded, color: c.primaryText),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
