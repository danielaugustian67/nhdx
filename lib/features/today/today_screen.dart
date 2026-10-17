import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/content_db.dart';
import '../../core/database/dictionary_db.dart';
import '../../core/database/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/chunky_button.dart';
import '../../l10n/app_localizations.dart';
import '../free_study/free_study_screen.dart';
import '../kana/games/memory_match_screen.dart';
import '../kana/games/speed_drill_screen.dart';
import '../kana/games/writing_screen.dart';
import '../kana/kana_providers.dart';
import '../learn/kana_path.dart';
import '../learn/lesson.dart';
import '../learn/lesson_intro_screen.dart';
import '../learn/lesson_screen.dart';
import '../learn/path_providers.dart';
import '../learn/study_language.dart';
import '../learn/vocab_path.dart';
import '../progress/me_screen.dart';
import '../progress/progress_providers.dart';
import '../search/quick_search.dart';
import '../srs/review_screen.dart';
import '../srs/srs_providers.dart';
import 'pixel_island.dart';

/// Unit banner colors; white text on each is ≥ 4.5:1 (ui-design §5.2).
const unitColors = [
  Color(0xFFC2406F), // sakura
  Color(0xFF7A4FC4), // wisteria
  Color(0xFF2E6BC6), // indigo
  Color(0xFF0F7B6C), // teal
  Color(0xFFB0471F), // vermilion
  Color(0xFF4E7A2A), // moss
  Color(0xFF8E3B8F), // plum
];

/// "Hari ini": the learning path (ui-design §5.2). Units of winding lesson
/// nodes; tap a node for a bubble with its title and start button.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  String? _selected;
  final _currentKey = GlobalKey();
  bool _scrolled = false;
  bool _following = false;
  double? _viewport;

  LessonBuilder _lesson(PathNode node) => lessonFor(
    node,
    words: ref.read(lessonWordsProvider).value ?? const <DictWord>[],
    allKana: ref.read(allKanaProvider).value ?? const <Kana>[],
    koWords: ref.read(koDictWordsProvider).value ?? const <DictWord>[],
    content: ref.read(contentProvider).value,
    knownKanji: ref.read(knownKanjiProvider),
  );

  void _selectTrack(LearnTrack track) {
    ref.read(learnTrackProvider.notifier).select(track);
    // Jump to the current lesson of the other course on the next build.
    setState(() {
      _selected = null;
      _scrolled = false;
    });
  }

  Future<void> _pickLanguage(StudyLanguage current) async {
    final picked = await showModalBottomSheet<StudyLanguage>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _LanguageSheet(current: current),
    );
    if (picked != null && picked != current) selectStudyLanguage(ref, picked);
  }

  Future<void> _start(PathNode node) async {
    setState(() => _selected = null);
    final progress = ref.read(kanaProgressProvider.notifier);
    if (node.type == NodeType.chest) {
      progress.addXp(node.xp);
      ref.read(pathProgressProvider.notifier).complete(node.id);
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).chestOpened(node.xp))));
      return;
    }
    final kanji = node.items.firstOrNull is Kanji;
    final isDone = ref.read(pathProgressProvider).contains(node.id);
    if (node.type == NodeType.intro || node.type == NodeType.review) {
      ref.read(pathProgressProvider.notifier).start(node.id);
    }
    final Widget page = switch (node.type) {
      // Finished nodes start from the cards too, with a shortcut to the quiz.
      NodeType.intro => LessonIntroScreen(
        items: node.items,
        lesson: _lesson(node),
        passMark: node.passMark,
        progressKey: node.id,
        replay: isDone,
      ),
      // Kanji have no standalone games yet; their unit nodes are lessons.
      NodeType.write when kanji => LessonScreen(
        passMark: node.passMark,
        exercises: () => _lesson(node).build(LessonMode.write),
      ),
      NodeType.write => WritingScreen(pool: node.kana, count: math.min(5, node.kana.length), passMark: node.passMark),
      NodeType.review => LessonScreen(
        passMark: node.passMark,
        exercises: () =>
            _lesson(node).build(LessonMode.mixed, count: 12, weakIds: ref.read(kanaProgressProvider).weakIds),
      ),
      NodeType.match => MemoryMatchScreen(pool: node.reviewPool.cast<Kana>()),
      NodeType.speed => SpeedDrillScreen(pool: node.reviewPool.cast<Kana>(), passMark: node.passMark),
      NodeType.chest => throw StateError('handled above'),
    };
    // Root navigator so lessons cover the bottom bar, like a focused session.
    final done = await Navigator.of(
      context,
      rootNavigator: true,
    ).push<bool>(MaterialPageRoute(builder: (_) => page, fullscreenDialog: true));
    if (done == true) {
      ref.read(pathProgressProvider.notifier).complete(node.id);
      // Kana, kanji, Hangul and words met in a passed lesson join the daily
      // review (PRD F6, F7).
      if (node.type == NodeType.intro) {
        addLearnedCards(ref, node.items);
        clearIntroProgress(ref, node.id);
      }
    }
  }

  Future<void> _review() async {
    await Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (_) => const ReviewScreen(), fullscreenDialog: true));
    // Counts depend on the clock; refresh them after a session.
    ref.invalidate(cardCountsProvider);
  }

  Future<void> _freeStudy() async {
    await Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (_) => const FreeStudyScreen()));
    // Cards may have gone into the daily review.
    ref.invalidate(cardCountsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Progress loads from user.db after the first frame; follow the current
    // lesson as it moves, until the user scrolls.
    ref.listen(pathProgressProvider, (_, _) {
      if (_following) WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
    });
    final track = ref.watch(learnTrackProvider);
    // Another language (its setting arrives a moment after the pick) opens
    // its course at the current lesson too.
    ref.listen(learnTrackProvider, (previous, next) {
      if (previous?.language == next.language) return;
      _selected = null;
      _scrolled = false;
    });
    final path = ref.watch(activePathProvider);
    final units = path.value ?? const <PathUnit>[];
    final done = ref.watch(pathProgressProvider);
    final xp = ref.watch(kanaProgressProvider.select((p) => p.xp));
    final language = ref.watch(studyLanguageProvider).value ?? StudyLanguage.ja;

    // Load dictionary words and kana early; the bubble enables "Ketik" once
    // they exist, and kanji words need the hiragana for okurigana.
    ref.watch(lessonWordsProvider);
    ref.watch(allKanaProvider);
    ref.watch(koDictWordsProvider);

    // Wait until the path of the chosen course has settled; while switching,
    // the previous course's units are still shown and would be scrolled to.
    if (units.isNotEmpty && !path.isLoading && !_scrolled) {
      _scrolled = true;
      _following = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
    }

    final fabShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.control),
      side: BorderSide(color: c.line),
    );
    return Scaffold(
      // The language being learned (bottom left) and Hafalan Bebas: any kana,
      // kanji or words as flashcards, no rules (bottom right). The top bar
      // has no room left for them on a narrow phone. Hidden while a lesson
      // bubble is open: it is scrolled to the bottom edge, under them.
      floatingActionButton: _selected != null
          ? null
          : SizedBox(
              width: MediaQuery.sizeOf(context).width - 2 * kFloatingActionButtonMargin,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _LanguageButton(language: language, shape: fabShape, onTap: () => _pickLanguage(language)),
                  FloatingActionButton.extended(
                    heroTag: 'free-study',
                    elevation: 2,
                    onPressed: _freeStudy,
                    backgroundColor: c.surfaceHigh,
                    foregroundColor: c.ink,
                    shape: fabShape,
                    icon: const Icon(Icons.psychology_rounded),
                    label: Text(AppLocalizations.of(context).freeStudy),
                  ),
                ],
              ),
            ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        // Only closes the lesson bubble; nothing for a screen reader.
        excludeFromSemantics: true,
        onTap: () => setState(() => _selected = null),
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: _onMetrics,
            child: _path(c, track, units, done, xp),
          ),
        ),
      ),
    );
  }

  /// Centers the current lesson, unless the user has scrolled since.
  void _scrollToCurrent() {
    final ctx = _currentKey.currentContext;
    if (!_following || ctx == null) return;
    Scrollable.ensureVisible(ctx, alignment: 0.45);
  }

  bool _onScroll(ScrollNotification n) {
    if (n is UserScrollNotification) _following = false;
    return false;
  }

  /// The viewport can still change size after the first scroll (window
  /// metrics arriving late on a cold start), which leaves the current
  /// lesson off screen; scroll again until the user takes over.
  bool _onMetrics(ScrollMetricsNotification n) {
    final viewport = n.metrics.viewportDimension;
    if (_following && _viewport != null && viewport != _viewport) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
    }
    _viewport = viewport;
    return false;
  }

  Widget _path(AppColors c, LearnTrack track, List<PathUnit> units, Set<String> done, int xp) {
    final states = nodeStates(units, done, free: track.free);
    // On a narrow phone the magnifier makes room for the course switch at
    // full touch size; search stays on the Kamus tab and the pull down.
    final narrow = MediaQuery.sizeOf(context).width < 400;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: c.bg,
          surfaceTintColor: Colors.transparent,
          titleSpacing: AppSpace.screen,
          title: Row(
            children: [
              // Shrinks rather than overflowing with large text.
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) => Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _TrackSwitch(
                        track: track,
                        onChanged: _selectTrack,
                        // Without the course name when it does not fit.
                        showLabel: _TrackSwitch.width(context, track, showLabel: true) <= box.maxWidth,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.s),
              _ReviewChip(onTap: _review),
              const SizedBox(width: AppSpace.s),
              _StreakChip(xp: xp),
            ],
          ),
          actions: [
            if (!narrow) const QuickSearchButton(),
            const SizedBox(width: AppSpace.xs),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(color: c.line),
          ),
        ),
        for (final (u, unit) in units.indexed) ...[
          if (u == 0 ||
              unit.script != units[u - 1].script ||
              (unit.script != 'hiragana' && unit.script != 'katakana' && unit.jlpt != units[u - 1].jlpt))
            SliverToBoxAdapter(child: _ScriptHeader(unit: unit)),
          SliverToBoxAdapter(
            child: _UnitBanner(unit: unit, color: unitColors[(unit.number - 1) % unitColors.length]),
          ),
          SliverToBoxAdapter(
            child: _UnitPath(
              unit: unit,
              color: unitColors[(unit.number - 1) % unitColors.length],
              stateOf: (node) => states[node.id] ?? NodeState.locked,
              selected: _selected,
              currentKey: _currentKey,
              onTapNode: (node) => setState(() => _selected = _selected == node.id ? null : node.id),
              onStart: _start,
            ),
          ),
        ],
        // Room for the last lesson above the Hafalan Bebas button.
        const SliverToBoxAdapter(child: SizedBox(height: AppSpace.xxxl + 56)),
      ],
    );
  }
}

/// Flashcard review entry (PRD F5): cards due now, or new cards waiting.
class _ReviewChip extends ConsumerWidget {
  const _ReviewChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final counts = ref.watch(cardCountsProvider).value;
    // fresh is already capped by today's new-card limit.
    final due = counts == null ? 0 : counts.due + counts.fresh;
    return Tooltip(
      message: due > 0 ? l10n.reviewDue(due) : l10n.reviewButton,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.control),
        onTap: onTap,
        // 48dp touch area around the 40dp chip.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTap),
          child: Center(widthFactor: 1, child: _chip(c, due)),
        ),
      ),
    );
  }

  Widget _chip(AppColors c, int due) => Container(
    constraints: const BoxConstraints(minHeight: 40, minWidth: 48),
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.m),
    decoration: BoxDecoration(
      color: due > 0 ? c.primary.withValues(alpha: 0.18) : c.surfaceHigh,
      borderRadius: BorderRadius.circular(AppRadius.control),
      border: Border.all(color: due > 0 ? c.primaryText : c.line),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.style_rounded, size: 20, color: due > 0 ? c.primaryText : c.inkMuted),
        if (due > 0) ...[
          const SizedBox(width: AppSpace.xs),
          Text(
            '$due',
            style: AppText.label.copyWith(color: c.primaryText, fontWeight: FontWeight.w700),
          ),
        ],
      ],
    ),
  );
}

/// Streak and XP in one pill: a stamp, filled once today is studied, with
/// the streak days, then the XP. Opens the goal and streak card.
class _StreakChip extends ConsumerWidget {
  const _StreakChip({required this.xp});
  final int xp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final streak = ref.watch(streakProvider);
    final days = streak.current;
    return Semantics(
      button: true,
      label: '${l10n.streakDays(days)}, ${l10n.xpAmount(xp)}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          useSafeArea: true,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (_) => _StreakSheet(xp: xp),
        ),
        // 48dp touch area around the pill.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTap),
          child: Center(
            widthFactor: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.m, vertical: AppSpace.xs + 2),
              decoration: BoxDecoration(
                color: c.surfaceHigh,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: streak.activeToday ? c.seal.withValues(alpha: 0.6) : c.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MiniStamp(on: streak.activeToday, color: days > 0 ? c.seal : c.inkMuted),
                  const SizedBox(width: AppSpace.xs),
                  Text(
                    '$days',
                    style: AppText.label.copyWith(color: days > 0 ? c.seal : c.inkMuted, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: AppSpace.s),
                  Icon(Icons.bolt_rounded, size: 18, color: c.gold),
                  Text('$xp', style: AppText.label.copyWith(color: c.gold, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small seal: filled with a tick once today is studied, a ring before.
class _MiniStamp extends StatelessWidget {
  const _MiniStamp({required this.on, required this.color});
  final bool on;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 18,
    height: 18,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: on ? color : null,
      border: Border.all(color: color, width: 2),
    ),
    child: on ? Icon(Icons.check_rounded, size: 12, color: context.colors.bg) : null,
  );
}

/// Today's goal, the streak stamps and freezes (as on Saya), and total XP.
class _StreakSheet extends StatelessWidget {
  const _StreakSheet({required this.xp});
  final int xp;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GoalCard(),
          const SizedBox(height: AppSpace.m),
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 20, color: c.gold),
              const SizedBox(width: AppSpace.xs),
              Expanded(
                child: Text(l10n.xpTotal(xp), style: AppText.body.copyWith(color: c.ink)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Kana | Kanji | Kata" course switch in the top bar. Each course keeps its
/// own progress and starts from its easiest lesson.
class _TrackSwitch extends StatelessWidget {
  const _TrackSwitch({required this.track, required this.onChanged, this.showLabel = true});
  final LearnTrack track;
  final ValueChanged<LearnTrack> onChanged;

  /// Whether the selected course shows its name next to the glyph.
  final bool showLabel;

  static const _pad = AppSpace.m, _gap = AppSpace.xs + 2, _glyphSize = 18.0, _inset = 3.0;
  static TextStyle _labelStyle(Color color) => AppText.label.copyWith(color: color, fontWeight: FontWeight.w700);

  static String _label(AppLocalizations l10n, LearnTrack t) => switch (t) {
    LearnTrack.kana => l10n.trackKana,
    LearnTrack.kanji => l10n.trackKanji,
    LearnTrack.vocab || LearnTrack.koVocab => l10n.trackVocab,
    LearnTrack.hangul => l10n.trackHangul,
  };

  static const _glyphs = {
    LearnTrack.kana: 'あ',
    LearnTrack.kanji: '漢',
    LearnTrack.vocab: '語',
    LearnTrack.hangul: '한',
    LearnTrack.koVocab: '말',
  };

  /// Natural width of the switch (border included).
  static double width(BuildContext context, LearnTrack track, {required bool showLabel}) {
    final scaler = MediaQuery.textScalerOf(context);
    final glyphOnly = math.max(AppSizes.minTap, 2 * _pad + scaler.scale(_glyphSize));
    var selected = glyphOnly;
    if (showLabel) {
      final label = TextPainter(
        text: TextSpan(text: _label(AppLocalizations.of(context), track), style: _labelStyle(Colors.black)),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      selected = math.max(AppSizes.minTap, 2 * _pad + scaler.scale(_glyphSize) + _gap + label.width);
      label.dispose();
    }
    return (LearnTrack.of(track.language).length - 1) * glyphOnly + selected + 2 * _inset + 2;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    Widget segment(LearnTrack t, String glyph) {
      final label = _label(l10n, t);
      final on = t == track;
      return Semantics(
        button: true,
        selected: on,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: on
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onChanged(t);
                },
          // 48dp touch area around the pill.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: AppSizes.minTap, minHeight: AppSizes.minTap),
            child: Center(
              widthFactor: 1,
              child: AnimatedContainer(
                duration: AppDurations.press,
                padding: const EdgeInsets.symmetric(horizontal: _pad, vertical: AppSpace.s),
                decoration: BoxDecoration(
                  color: on ? c.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.control - 2),
                ),
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        glyph,
                        locale: const Locale('ja'),
                        style: TextStyle(
                          fontFamily: AppFonts.jpStroke,
                          fontSize: _glyphSize,
                          color: on ? c.onPrimary : c.inkMuted,
                        ),
                      ),
                      // Three courses do not fit with labels on a narrow phone;
                      // the others keep their glyph and semantics label.
                      if (on && showLabel) ...[
                        const SizedBox(width: _gap),
                        Text(label, style: _labelStyle(c.onPrimary)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: _inset),
      decoration: BoxDecoration(
        color: c.surfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: c.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [for (final t in LearnTrack.of(track.language)) segment(t, _glyphs[t]!)],
      ),
    );
  }
}

class _ScriptHeader extends StatelessWidget {
  const _ScriptHeader({required this.unit});
  final PathUnit unit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.xl, AppSpace.screen, 0),
      child: Row(
        children: [
          Expanded(child: Divider(color: c.line)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.m),
            child: Text(switch (unit.script) {
              'hiragana' => l10n.hiragana,
              'katakana' => l10n.katakana,
              'vocab' => l10n.vocabLevel(unit.jlpt ?? 5),
              'hangul' => l10n.hangul,
              'ko_vocab' => l10n.koreanVocab,
              _ => l10n.kanjiLevel(unit.jlpt ?? 5),
            }, style: AppText.label.copyWith(color: c.inkMuted)),
          ),
          Expanded(child: Divider(color: c.line)),
        ],
      ),
    );
  }
}

class _UnitBanner extends StatelessWidget {
  const _UnitBanner({required this.unit, required this.color});
  final PathUnit unit;
  final Color color;

  String _title(AppLocalizations l10n) {
    // Korean units: their name from content.db.
    if (unit.title case final title?) return title.of(l10n.localeName);
    // Vocabulary units: their first words, "人  日本  行く".
    if (unit.script == 'vocab') return unit.introduced.take(3).map((w) => w.literal).join('  ');
    // Kanji units without a theme (N3 to N1): their first kanji.
    if (unit.script == 'kanji' && unit.theme == null) return unit.introduced.take(3).map((k) => k.literal).join(' ');
    // Kanji units: theme and its first kanji, "Angka 一 二 三".
    if (unit.theme case final theme?) {
      return '${l10n.kanjiTheme(theme)} ${unit.introduced.take(3).map((k) => k.literal).join(' ')}';
    }
    if (unit.nodes.first.kana.first.isYoon) return l10n.unitYoon;
    if (unit.rows.first == 'ga') return l10n.unitDakuten;
    // First kana of each row: "Baris あ か"
    final kana = unit.nodes.expand((n) => n.kana);
    final firsts = [for (final row in unit.rows) ?kana.where((k) => k.rowGroup == row).firstOrNull?.literal];
    return l10n.unitRows(firsts.join(' '));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.l, AppSpace.screen, AppSpace.s),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border(bottom: BorderSide(color: Color.lerp(color, Colors.black, 0.35)!, width: 4)),
        ),
        padding: const EdgeInsets.fromLTRB(AppSpace.l, AppSpace.m, AppSpace.l, AppSpace.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              unit.jlpt == null ? l10n.unitNumber(unit.number) : l10n.unitLevel(unit.number, unit.jlpt!),
              style: AppText.label.copyWith(color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              _title(l10n),
              locale: const Locale('ja'),
              style: AppText.title2.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitPath extends StatelessWidget {
  const _UnitPath({
    required this.unit,
    required this.color,
    required this.stateOf,
    required this.selected,
    required this.currentKey,
    required this.onTapNode,
    required this.onStart,
  });

  final PathUnit unit;
  final Color color;
  final NodeState Function(PathNode) stateOf;
  final String? selected;
  final GlobalKey currentKey;
  final ValueChanged<PathNode> onTapNode;

  final ValueChanged<PathNode> onStart;

  /// Horizontal zigzag as a fraction of the max offset.
  static const _wave = [0.0, 0.45, 0.75, 0.45, 0.0, -0.45, -0.75, -0.45];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final maxOffset = math.min(100.0, box.maxWidth * 0.24);
        return Column(
          children: [
            for (final (i, node) in unit.nodes.indexed) ...[
              Builder(
                builder: (context) {
                  final state = stateOf(node);
                  final title = _nodeTitle(l10n, node);
                  final dx = _wave[i % _wave.length] * maxOffset;
                  // Shift by layout, not Transform.translate: a translated
                  // node is hit-tested within its untranslated bounds, so a
                  // far-shifted node (3rd, 7th, …) could not be tapped.
                  return Padding(
                    padding: EdgeInsets.only(
                      top: AppSpace.s,
                      bottom: AppSpace.s,
                      left: math.max(0, 2 * dx),
                      right: math.max(0, -2 * dx),
                    ),
                    child: _PathNodeButton(
                      key: state == NodeState.current ? currentKey : null,
                      node: node,
                      state: state,
                      label: switch (state) {
                        NodeState.done => l10n.nodeDoneLabel(title),
                        NodeState.locked => l10n.nodeLockedLabel(title),
                        NodeState.current || NodeState.open => title,
                      },
                      color: color,
                      showStartTag: state == NodeState.current && selected != node.id,
                      onTap: () => onTapNode(node),
                    ),
                  );
                },
              ),
              if (selected == node.id)
                _NodeBubble(
                  node: node,
                  state: stateOf(node),
                  color: color,
                  position: i + 1,
                  total: unit.nodes.length,
                  pointerDx: _wave[i % _wave.length] * maxOffset,
                  title: _nodeTitle(l10n, node),
                  onStart: () => onStart(node),
                ),
            ],
          ],
        );
      },
    );
  }

  static String _nodeTitle(AppLocalizations l10n, PathNode node) => switch (node.type) {
    NodeType.intro when node.items.firstOrNull is VocabWord => l10n.nodeWords(
      node.items.length,
      // Korean is written with spaces and Latin commas.
      '${node.items.take(3).map((w) => w.literal).join(isKoreanItem(node.items.first) ? ', ' : '、')}…',
    ),
    NodeType.intro => l10n.nodeIntro(node.items.map((k) => k.literal).join(' ')),
    NodeType.write => l10n.nodeWrite,
    NodeType.review => l10n.nodeReview,
    NodeType.match => l10n.nodeMatch,
    NodeType.speed => l10n.nodeSpeed,
    NodeType.chest => l10n.nodeChest,
  };
}

/// Lesson button drawn as a pixel island (pixel_island.dart): gold when done,
/// unit color when open, grey with a lock when locked (icon + semantics,
/// never color alone).
class _PathNodeButton extends StatefulWidget {
  const _PathNodeButton({
    super.key,
    required this.node,
    required this.state,
    required this.label,
    required this.color,
    required this.showStartTag,
    required this.onTap,
  });

  final PathNode node;
  final NodeState state;

  /// What a screen reader says: the lesson and whether it is done or locked.
  final String label;
  final Color color;
  final bool showStartTag;
  final VoidCallback onTap;

  @override
  State<_PathNodeButton> createState() => _PathNodeButtonState();
}

class _PathNodeButtonState extends State<_PathNodeButton> with SingleTickerProviderStateMixin {
  late final _bounce = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  bool _down = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MediaQuery.of(context).disableAnimations && widget.state == NodeState.current) {
      _bounce.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_PathNodeButton old) {
    super.didUpdateWidget(old);
    if (widget.state != NodeState.current) _bounce.stop();
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final island = PixelIsland(
      type: widget.node.type,
      state: widget.state,
      unitColor: widget.color,
      seed: widget.node.id.codeUnits.fold(0, (h, u) => (h * 31 + u) & 0x7fffffff),
      pressed: _down,
    );

    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) {
          setState(() => _down = false);
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 34,
              child: widget.showStartTag
                  ? AnimatedBuilder(
                      animation: _bounce,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, -4 * Curves.easeInOut.transform(_bounce.value)),
                        child: child,
                      ),
                      child: _StartTag(label: l10n.startHere, color: widget.color),
                    )
                  : null,
            ),
            island,
          ],
        ),
      ),
    );
  }
}

class _StartTag extends StatelessWidget {
  const _StartTag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.m, vertical: AppSpace.xs + 2),
      decoration: BoxDecoration(
        color: c.surfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: c.line, width: 2),
      ),
      child: Text(
        label,
        style: AppText.label.copyWith(color: c.primaryText, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Popup under a tapped node with a pointer towards it (ui-design §5.2).
class _NodeBubble extends StatelessWidget {
  const _NodeBubble({
    required this.node,
    required this.state,
    required this.color,
    required this.position,
    required this.total,
    required this.pointerDx,
    required this.title,
    required this.onStart,
  });

  final PathNode node;
  final NodeState state;
  final Color color;
  final int position;
  final int total;
  final double pointerDx;
  final String title;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final locked = state == NodeState.locked;
    final openedChest = node.type == NodeType.chest && state == NodeState.done;
    final bg = locked ? c.surfaceHigh : color;
    final fg = locked ? c.inkMuted : Colors.white;

    return _RevealOnShow(
      child: GestureDetector(
        onTap: () {}, // keep taps inside the bubble from closing it
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
          child: Column(
            children: [
              Transform.translate(
                offset: Offset(pointerDx, 1),
                child: CustomPaint(size: const Size(24, 12), painter: _PointerPainter(bg)),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpace.l),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.card)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      locale: const Locale('ja'),
                      style: AppText.title2.copyWith(color: locked ? c.ink : Colors.white, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      locked ? l10n.nodeLocked : l10n.nodePosition(position, total),
                      style: AppText.bodySmall.copyWith(color: fg),
                    ),
                    if (!locked && node.passMark != null)
                      Text(
                        l10n.passMarkHint((node.passMark! * 100).round()),
                        style: AppText.bodySmall.copyWith(color: fg),
                      ),
                    if (!locked && !openedChest) ...[
                      const SizedBox(height: AppSpace.l),
                      ChunkyButton(
                        label: node.type == NodeType.chest
                            ? l10n.openChest
                            : state == NodeState.done
                            ? l10n.nodeReplay
                            : l10n.startHere,
                        color: Colors.white,
                        textColor: color,
                        onPressed: onStart,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.m),
            ],
          ),
        ),
      ),
    );
  }
}

class _PointerPainter extends CustomPainter {
  _PointerPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PointerPainter old) => old.color != color;
}

/// Scrolls its child fully into view when it first appears: the lesson
/// bubble can open behind the tab bar, above all with large text.
class _RevealOnShow extends StatefulWidget {
  const _RevealOnShow({required this.child});
  final Widget child;

  @override
  State<_RevealOnShow> createState() => _RevealOnShowState();
}

class _RevealOnShowState extends State<_RevealOnShow> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppDurations.page,
        curve: Curves.easeOut,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The flag of the language being learned; opens [_LanguageSheet].
class _LanguageButton extends StatelessWidget {
  const _LanguageButton({required this.language, required this.shape, required this.onTap});
  final StudyLanguage language;
  final ShapeBorder shape;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    return FloatingActionButton(
      heroTag: 'study-language',
      elevation: 2,
      tooltip: '${l10n.switchLanguage}: ${studyLanguageName(l10n, language)}',
      onPressed: onTap,
      backgroundColor: c.surfaceHigh,
      shape: shape,
      child: Text(language.flag, style: const TextStyle(fontSize: 24)),
    );
  }
}

/// Japanese or Korean; pops the language picked.
class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({required this.current});
  final StudyLanguage current;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.studyLanguage, style: AppText.title2.copyWith(color: c.ink)),
          const SizedBox(height: AppSpace.xs),
          Text(l10n.studyLanguageNote, style: AppText.bodySmall.copyWith(color: c.inkMuted)),
          const SizedBox(height: AppSpace.m),
          for (final l in StudyLanguage.values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(l.flag, style: const TextStyle(fontSize: 28)),
              title: Text(
                studyLanguageName(l10n, l),
                style: AppText.body.copyWith(color: c.ink, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                l == StudyLanguage.ja ? l10n.languageJapaneseBody : l10n.languageKoreanBody,
                style: AppText.bodySmall.copyWith(color: c.inkMuted),
              ),
              trailing: l == current ? Icon(Icons.check_circle_rounded, color: c.primaryText) : null,
              selected: l == current,
              onTap: () => Navigator.pop(context, l),
            ),
        ],
      ),
    );
  }
}
