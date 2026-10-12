import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/database/content_db.dart';
import '../../core/database/user_db.dart';
import '../../core/study_day.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/game_card.dart';
import '../../core/widgets/level_badge.dart';
import '../../core/widgets/progress_ring.dart';
import '../../l10n/app_localizations.dart';
import '../free_study/free_study_providers.dart';
import '../free_study/free_study_session_screen.dart';
import '../search/quick_search.dart';
import '../settings/settings_section.dart';
import '../word/word_detail_screen.dart';
import 'progress_providers.dart';
import 'streak.dart';

/// "Saya" tab (ui-design §5.11, PRD F8): daily goal, streak as a row of
/// stamps, today's numbers, activity chart, stamp book, JLPT progress,
/// card stages, hardest items and settings.
class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final hardest = ref.watch(hardestCardsProvider);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.l, AppSpace.screen, AppSpace.xxl),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(l10n.tabMe, style: AppText.title1.copyWith(color: c.ink)),
                ),
                const QuickSearchButton(),
              ],
            ),
            const SizedBox(height: AppSpace.l),
            const _GoalCard(),
            _Section(title: l10n.tabToday, child: const _TodayStats()),
            _Section(title: l10n.activity, child: const _ActivityChart()),
            _Section(title: l10n.stampBook, child: const _StampBook()),
            _Section(title: l10n.jlptProgress, child: const _JlptProgress()),
            _Section(title: l10n.cardStages, child: const _CardStages()),
            if (hardest.isNotEmpty)
              _Section(
                title: l10n.hardestItems,
                child: _Hardest(cards: hardest),
              ),
            _Section(title: l10n.settings, child: const SettingsSection()),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpace.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: AppText.label.copyWith(color: context.colors.inkMuted)),
        ),
        const SizedBox(height: AppSpace.s),
        child,
      ],
    ),
  );
}

/// Ring with today's cards next to the streak, shown as stamps for the last
/// seven days rather than a flame count (ui-design §7).
class _GoalCard extends ConsumerWidget {
  const _GoalCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final today = todayStudyDate();
    final days = ref.watch(dayMapProvider);
    final goal = ref.watch(dailyGoalProvider).value ?? DailyGoal.fallback;
    final streak = ref.watch(streakProvider);
    final done = days[today]?.cards ?? 0;
    final left = goal - done;
    return GameCard(
      padding: const EdgeInsets.all(AppSpace.l),
      child: Row(
        children: [
          ProgressRing(done: done, goal: goal, unit: l10n.goalCardsUnit),
          const SizedBox(width: AppSpace.l),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.streakDays(streak.current), style: AppText.title2.copyWith(color: c.ink)),
                const SizedBox(height: AppSpace.s),
                _StampRow(
                  today: today,
                  active: {
                    for (final d in days.values)
                      if (d.active) d.date,
                  },
                  frozen: streak.frozenDays,
                ),
                const SizedBox(height: AppSpace.s),
                Text(
                  left <= 0
                      ? l10n.goalReached
                      : streak.current == 0
                      ? l10n.streakStart
                      : streak.activeToday
                      ? l10n.goalLeft(left)
                      : streak.frozenDays.contains(previousDate(today))
                      ? l10n.freezeUsed
                      : l10n.streakKeep,
                  style: AppText.bodySmall.copyWith(color: c.inkMuted),
                ),
                if (streak.longest > streak.current)
                  Text(l10n.streakLongest(streak.longest), style: AppText.bodySmall.copyWith(color: c.inkMuted)),
                if (streak.current > 0 || streak.freezes > 0) ...[
                  const SizedBox(height: AppSpace.xs),
                  Row(
                    children: [
                      Icon(Icons.ac_unit_rounded, size: 16, color: c.accent),
                      const SizedBox(width: AppSpace.xs),
                      Expanded(
                        child: Text(
                          [
                            if (streak.freezes > 0) l10n.freezesHeld(streak.freezes),
                            if (streak.untilNextFreeze case final n?) l10n.freezeNext(n),
                          ].join(' · '),
                          style: AppText.bodySmall.copyWith(color: c.inkMuted),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StampRow extends StatelessWidget {
  const _StampRow({required this.today, required this.active, required this.frozen});

  final String today;
  final Set<String> active;
  final Set<String> frozen;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    // Seven stamps of up to 28dp; smaller beside the ring on a narrow phone.
    return LayoutBuilder(
      builder: (context, box) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 6; i >= 0; i--)
            () {
              final date = addDays(today, -i);
              return _DayStamp(
                date: date,
                label: DateFormat.E(locale).format(parseDate(date)).characters.first,
                active: active.contains(date),
                frozen: frozen.contains(date),
                isToday: i == 0,
                size: math.min(28, (box.maxWidth - 6 * 2) / 7),
              );
            }(),
        ],
      ),
    );
  }
}

/// One day as a small tilted stamp (active), a snowflake (kept by a streak
/// freeze) or a faint ring.
class _DayStamp extends StatelessWidget {
  const _DayStamp({
    required this.date,
    required this.label,
    required this.active,
    required this.isToday,
    required this.size,
    this.frozen = false,
    this.future = false,
  });

  final String date;
  final String label;
  final bool active;
  final bool frozen;
  final bool isToday;
  final bool future;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    if (frozen && !active) {
      return Semantics(
        label: l10n.stampFrozen(DateFormat.MMMd(l10n.localeName).format(parseDate(date))),
        excludeSemantics: true,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.accent.withValues(alpha: 0.14),
            border: Border.all(color: c.accent, width: 2),
          ),
          child: Icon(Icons.ac_unit_rounded, size: size * 0.55, color: c.accent),
        ),
      );
    }
    final text = AppText.label.copyWith(
      fontSize: size * 0.42,
      height: 1,
      color: active
          ? c.seal
          : future
          ? c.inkMuted.withValues(alpha: 0.4)
          : c.inkMuted,
    );
    final circle = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? c.seal.withValues(alpha: 0.14) : null,
        border: Border.all(
          color: active
              ? c.seal
              : isToday
              ? c.primaryText
              : c.line,
          width: active ? 2 : 1.5,
        ),
      ),
      child: Text(label, style: text),
    );
    return Semantics(
      label: active ? l10n.stampDay(DateFormat.MMMd(l10n.localeName).format(parseDate(date))) : null,
      excludeSemantics: active,
      child: active ? Transform.rotate(angle: stampTiltDegrees(date) * math.pi / 180, child: circle) : circle,
    );
  }
}

class _TodayStats extends ConsumerWidget {
  const _TodayStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final today = todayStudyDate();
    final day = ref.watch(dayMapProvider)[today];
    final reviews = ref.watch(reviewDaysProvider).value?[today];
    final minutes = ((day?.studyMs ?? 0) / 60000).ceil();
    return Row(
      children: [
        _Stat(value: '${day?.newCount ?? 0}', label: l10n.statNew),
        _Stat(value: '${day?.reviewCount ?? 0}', label: l10n.statReviews),
        _Stat(
          value: reviews == null || reviews.answers == 0
              ? '–'
              : '${(100 * reviews.correct / reviews.answers).round()}%',
          label: l10n.statAccuracy,
        ),
        _Stat(value: l10n.intervalMinutes(minutes), label: l10n.statTime),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs / 2),
        child: GameCard(
          radius: AppRadius.control,
          padding: const EdgeInsets.symmetric(vertical: AppSpace.m, horizontal: AppSpace.xs),
          child: Column(
            children: [
              FittedBox(
                child: Text(value, style: AppText.title2.copyWith(color: c.ink)),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.label.copyWith(color: c.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cards (or XP) per day over the last 7 or 30 days: plain bars in one
/// color (ui-design §5.11).
class _ActivityChart extends ConsumerStatefulWidget {
  const _ActivityChart();

  @override
  ConsumerState<_ActivityChart> createState() => _ActivityChartState();
}

class _ActivityChartState extends ConsumerState<_ActivityChart> {
  int _range = 7;
  bool _xp = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final locale = l10n.localeName;
    final today = todayStudyDate();
    final days = ref.watch(dayMapProvider);
    final dates = [for (var i = _range - 1; i >= 0; i--) addDays(today, -i)];
    final values = [for (final d in dates) _xp ? days[d]?.xp ?? 0 : days[d]?.cards ?? 0];
    final cards = dates.fold(0, (a, d) => a + (days[d]?.cards ?? 0));
    final xp = dates.fold(0, (a, d) => a + (days[d]?.xp ?? 0));
    String dayLabel(String d) => DateFormat.MMMd(locale).format(parseDate(d));

    return GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: AppSpace.s,
            children: [
              _ChipGroup(
                labels: [
                  for (final r in const [7, 30]) l10n.lastDays(r),
                ],
                selected: _range == 7 ? 0 : 1,
                onSelected: (i) => setState(() => _range = i == 0 ? 7 : 30),
              ),
              _ChipGroup(
                labels: [l10n.goalCardsUnit, 'XP'],
                selected: _xp ? 1 : 0,
                onSelected: (i) => setState(() => _xp = i == 1),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.l),
          Semantics(
            label: [
              for (var i = 0; i < dates.length; i++)
                if (values[i] > 0)
                  _xp ? '${dayLabel(dates[i])}: ${values[i]} XP' : l10n.activityBar(dayLabel(dates[i]), values[i]),
            ].join(', '),
            child: SizedBox(
              height: 120,
              child: CustomPaint(
                size: Size.infinite,
                painter: _BarsPainter(values: values, color: c.primary, empty: c.line),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          ExcludeSemantics(
            child: _range == 7
                ? Row(
                    children: [
                      for (final d in dates)
                        Expanded(
                          child: Text(
                            DateFormat.E(locale).format(parseDate(d)),
                            textAlign: TextAlign.center,
                            style: AppText.label.copyWith(color: d == today ? c.ink : c.inkMuted, fontSize: 11),
                          ),
                        ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final d in [dates.first, dates.last])
                        Text(dayLabel(d), style: AppText.label.copyWith(color: c.inkMuted, fontSize: 11)),
                    ],
                  ),
          ),
          const SizedBox(height: AppSpace.m),
          Text(l10n.activityTotal(cards, xp), style: AppText.bodySmall.copyWith(color: c.inkMuted)),
        ],
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({required this.labels, required this.selected, required this.onSelected});

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < labels.length; i++)
        Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : AppSpace.xs),
          child: ChoiceChip(
            label: Text(labels[i]),
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
            selected: selected == i,
            onSelected: (_) => onSelected(i),
          ),
        ),
    ],
  );
}

class _BarsPainter extends CustomPainter {
  const _BarsPainter({required this.values, required this.color, required this.empty});

  final List<int> values;
  final Color color;
  final Color empty;

  @override
  void paint(Canvas canvas, Size size) {
    final top = values.fold(0, math.max);
    final slot = size.width / values.length;
    final width = math.min(slot * 0.6, 24.0);
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      final h = v == 0 || top == 0 ? 3.0 : math.max(6.0, size.height * v / top);
      final x = slot * i + (slot - width) / 2;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, size.height - h, width, h),
        topLeft: Radius.circular(math.min(width / 2, 6)),
        topRight: Radius.circular(math.min(width / 2, 6)),
      );
      canvas.drawRRect(rect, Paint()..color = v == 0 ? empty : color);
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.values != values || old.color != color || old.empty != empty;
}

/// Monthly stamp book: a tilted stamp on every day with activity; earlier
/// months can be paged back to (ui-design §7).
class _StampBook extends ConsumerStatefulWidget {
  const _StampBook();

  @override
  ConsumerState<_StampBook> createState() => _StampBookState();
}

class _StampBookState extends ConsumerState<_StampBook> {
  late DateTime _month = () {
    final t = parseDate(todayStudyDate());
    return DateTime.utc(t.year, t.month);
  }();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final locale = l10n.localeName;
    final today = todayStudyDate();
    final active = {
      for (final d in ref.watch(dayMapProvider).values)
        if (d.active) d.date,
    };
    final frozen = ref.watch(streakProvider.select((s) => s.frozenDays));
    final t = parseDate(today);
    final isCurrent = _month.year == t.year && _month.month == t.month;
    final cells = monthCells(_month.year, _month.month);
    // 5 Oct 2026 is a Monday.
    final weekdays = [for (var i = 0; i < 7; i++) DateFormat.E(locale).format(DateTime.utc(2026, 10, 5 + i))];

    return GameCard(
      padding: const EdgeInsets.fromLTRB(AppSpace.s, AppSpace.xs, AppSpace.s, AppSpace.m),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: l10n.previousMonth,
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => setState(() => _month = DateTime.utc(_month.year, _month.month - 1)),
              ),
              Expanded(
                child: Text(
                  DateFormat.yMMMM(locale).format(_month),
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(color: c.ink, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                tooltip: l10n.nextMonth,
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: isCurrent
                    ? null
                    : () => setState(() => _month = DateTime.utc(_month.year, _month.month + 1)),
              ),
            ],
          ),
          ExcludeSemantics(
            child: Row(
              children: [
                for (final w in weekdays)
                  Expanded(
                    child: Text(
                      w,
                      textAlign: TextAlign.center,
                      style: AppText.label.copyWith(color: c.inkMuted, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpace.xs,
            children: [
              for (final d in cells)
                d == null
                    ? const SizedBox.shrink()
                    : Center(
                        child: _DayStamp(
                          date: d,
                          label: '${parseDate(d).day}',
                          active: active.contains(d),
                          frozen: frozen.contains(d),
                          isToday: d == today,
                          future: d.compareTo(today) > 0,
                          size: 34,
                        ),
                      ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JlptProgress extends ConsumerWidget {
  const _JlptProgress();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final progress = ref.watch(jlptProgressProvider).value;
    if (progress == null) return const SizedBox(height: 120);
    return GameCard(
      child: Column(
        children: [
          for (final level in [5, 4, 3, 2, 1])
            if (progress[level] case final p?)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.xs + 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Align(alignment: Alignment.centerLeft, child: LevelBadge(level)),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: p.total == 0 ? 0 : p.learned / p.total,
                          minHeight: 4,
                          color: c.primary,
                          backgroundColor: c.line,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.m),
                    SizedBox(
                      width: 128,
                      child: Text(
                        l10n.wordsOf(p.learned, p.total),
                        textAlign: TextAlign.end,
                        style: AppText.bodySmall.copyWith(color: c.inkMuted),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _CardStages extends ConsumerWidget {
  const _CardStages();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final s = ref.watch(cardStagesProvider);
    return Row(
      children: [
        _Stat(value: '${s.fresh}', label: l10n.stageNew),
        _Stat(value: '${s.learning}', label: l10n.stageLearning),
        _Stat(value: '${s.young}', label: l10n.stageYoung),
        _Stat(value: '${s.mature}', label: l10n.stageMature),
      ],
    );
  }
}

class _Hardest extends ConsumerWidget {
  const _Hardest({required this.cards});

  final List<SrsCard> cards;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final forgotten = ref.watch(forgottenItemsProvider).value ?? const <Glyph>[];
    return GameCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final card in cards)
            ListTile(
              title: Text(
                card.labelSnapshot,
                locale: const Locale('ja'),
                style: AppText.rowHeadword.copyWith(color: c.ink),
              ),
              trailing: Text(l10n.lapsesCount(card.lapses), style: AppText.bodySmall.copyWith(color: c.seal)),
              onTap: card.cardType == 'word' && int.tryParse(card.itemId) != null
                  ? () => openWord(context, int.parse(card.itemId))
                  : null,
            ),
          if (forgotten.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.m, 0, AppSpace.m, AppSpace.s),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.style_rounded),
                label: Text('${l10n.hardestStudy} (${forgotten.length})'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FreeStudySessionScreen(
                      items: forgotten,
                      meaningFirst: ref.read(studyChoiceProvider).meaningFirst,
                    ),
                    fullscreenDialog: true,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
