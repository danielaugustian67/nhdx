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
import '../../core/widgets/xp_chip.dart';
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
import '../learn/vocab_path.dart';
import '../search/quick_search.dart';
import '../srs/review_screen.dart';
import '../srs/srs_providers.dart';

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
  );

  void _selectTrack(LearnTrack track) {
    ref.read(learnTrackProvider.notifier).select(track);
    // Jump to the current lesson of the other course on the next build.
    setState(() {
      _selected = null;
      _scrolled = false;
    });
  }

  Future<void> _start(PathNode node, LessonMode mode) async {
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
    final vocab = node.items.firstOrNull is VocabWord;
    final isDone = ref.read(pathProgressProvider).contains(node.id);
    if (node.type == NodeType.intro || node.type == NodeType.review) {
      ref.read(pathProgressProvider.notifier).start(node.id);
    }
    final Widget page = switch (node.type) {
      NodeType.intro when isDone => LessonScreen(
        passMark: node.passMark,
        exercises: () => _lesson(node).build(
          mode,
          count: vocab ? 12 : (node.items.length * 2).clamp(6, 10),
          weakIds: ref.read(kanaProgressProvider).weakIds,
        ),
      ),
      NodeType.intro => LessonIntroScreen(
        items: node.items,
        lesson: _lesson(node),
        mode: mode,
        passMark: node.passMark,
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
      // Kana, kanji and words met in a passed lesson join the daily review
      // (PRD F6, F7).
      if (node.type == NodeType.intro && vocab) {
        final words = [for (final w in node.items.cast<VocabWord>()) (id: w.id, label: w.literal)];
        writeUserDb(ref.read(userDbProvider.future), (db) => addWordCards(db, words));
      } else if (node.type == NodeType.intro && kanji) {
        addKanjiCards(ref, node.items.map((k) => k.literal));
      } else if (node.type == NodeType.intro) {
        addKanaCards(ref, node.items.map((k) => k.literal));
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
    final path = ref.watch(activePathProvider);
    final units = path.value ?? const <PathUnit>[];
    final done = ref.watch(pathProgressProvider);
    final xp = ref.watch(kanaProgressProvider.select((p) => p.xp));

    // Load dictionary words and kana early; the bubble enables "Ketik" once
    // they exist, and kanji words need the hiragana for okurigana.
    ref.watch(lessonWordsProvider);
    ref.watch(allKanaProvider);

    // Wait until the path of the chosen course has settled; while switching,
    // the previous course's units are still shown and would be scrolled to.
    if (units.isNotEmpty && !path.isLoading && !_scrolled) {
      _scrolled = true;
      _following = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
    }

    return Scaffold(
      // Hafalan Bebas: any kana, kanji or words as flashcards, no rules. The
      // top bar has no room left for it on a narrow phone.
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'free-study',
        elevation: 2,
        onPressed: _freeStudy,
        backgroundColor: c.surfaceHigh,
        foregroundColor: c.ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          side: BorderSide(color: c.line),
        ),
        icon: const Icon(Icons.psychology_rounded),
        label: Text(AppLocalizations.of(context).freeStudy),
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
              XpChip(xp),
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
              modesOf: (node) => {
                if (node.type == NodeType.intro)
                  for (final m in LessonMode.values)
                    if (m != LessonMode.mixed && _lesson(node).available(m)) m,
              },
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
    LearnTrack.vocab => l10n.trackVocab,
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
    return 2 * glyphOnly + selected + 2 * _inset + 2;
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
        children: [segment(LearnTrack.kana, 'あ'), segment(LearnTrack.kanji, '漢'), segment(LearnTrack.vocab, '語')],
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
    required this.modesOf,
    required this.onStart,
  });

  final PathUnit unit;
  final Color color;
  final NodeState Function(PathNode) stateOf;
  final String? selected;
  final GlobalKey currentKey;
  final ValueChanged<PathNode> onTapNode;

  /// Single-type practice modes offered next to the main (mixed) start.
  final Set<LessonMode> Function(PathNode) modesOf;
  final void Function(PathNode, LessonMode) onStart;

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
                  modes: modesOf(node),
                  onStart: (mode) => onStart(node, mode),
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
      '${node.items.take(3).map((w) => w.literal).join('、')}…',
    ),
    NodeType.intro => l10n.nodeIntro(node.items.map((k) => k.literal).join(' ')),
    NodeType.write => l10n.nodeWrite,
    NodeType.review => l10n.nodeReview,
    NodeType.match => l10n.nodeMatch,
    NodeType.speed => l10n.nodeSpeed,
    NodeType.chest => l10n.nodeChest,
  };
}

/// Thick round lesson button: gold when done, unit color when current,
/// grey with a lock when locked (icon + semantics, never color alone).
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
  static const _size = 74.0, _edge = 7.0;

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

  IconData get _icon => switch (widget.node.type) {
    NodeType.intro => Icons.star_rounded,
    NodeType.write => Icons.draw_rounded,
    NodeType.review => Icons.replay_rounded,
    NodeType.match => Icons.style_rounded,
    NodeType.speed => Icons.bolt_rounded,
    NodeType.chest => Icons.redeem_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final (face, iconColor, icon) = switch (widget.state) {
      NodeState.done => (c.goldFill, const Color(0xFF3D2A00), Icons.check_rounded),
      NodeState.current || NodeState.open => (widget.color, Colors.white, _icon),
      NodeState.locked => (c.surfaceHigh, c.inkMuted, widget.node.type == NodeType.chest ? _icon : Icons.lock_rounded),
    };
    final edge = Color.lerp(face, Colors.black, 0.4)!;
    final sink = _down ? _edge - 2 : 0.0;

    final circle = SizedBox(
      width: _size,
      height: _size + _edge,
      child: Stack(
        children: [
          Positioned(
            top: _edge,
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(color: edge, shape: BoxShape.circle),
            ),
          ),
          AnimatedPositioned(
            duration: AppDurations.press,
            top: sink,
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(color: face, shape: BoxShape.circle),
              child: Icon(icon, size: 36, color: iconColor),
            ),
          ),
        ],
      ),
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
            if (widget.state == NodeState.current)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.color.withValues(alpha: 0.55), width: 4),
                ),
                child: circle,
              )
            else
              circle,
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
    required this.modes,
    required this.onStart,
  });

  final PathNode node;
  final NodeState state;
  final Color color;
  final int position;
  final int total;
  final double pointerDx;
  final String title;
  final Set<LessonMode> modes;
  final ValueChanged<LessonMode> onStart;

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
                        onPressed: () => onStart(LessonMode.mixed),
                      ),
                      if (node.type == NodeType.intro) ...[
                        const SizedBox(height: AppSpace.m),
                        Text(l10n.practiceOneMode, style: AppText.bodySmall.copyWith(color: fg)),
                        const SizedBox(height: AppSpace.s),
                        Row(
                          children: [
                            for (final (i, (mode, label, icon)) in [
                              (LessonMode.choice, l10n.modeChoice, Icons.grid_view_rounded),
                              if (node.items.firstOrNull is VocabWord)
                                (LessonMode.match, l10n.gameMatch, Icons.compare_arrows_rounded)
                              else
                                (LessonMode.write, l10n.gameWrite, Icons.draw_rounded),
                              (LessonMode.type, l10n.modeType, Icons.keyboard_rounded),
                            ].indexed) ...[
                              if (i > 0) const SizedBox(width: AppSpace.s),
                              Expanded(
                                child: _ModeChip(
                                  label: label,
                                  icon: icon,
                                  onTap: modes.contains(mode) ? () => onStart(mode) : null,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
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

/// Outlined white button inside a node bubble for single-type practice.
/// Disabled (faded) when the lesson has no such exercises, e.g. "Tulis" for
/// yōon or "Ketik" before the dictionary is installed.
class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.control),
          onTap: onTap,
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.control),
              border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
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
