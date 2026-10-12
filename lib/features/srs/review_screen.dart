import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/speech.dart';
import '../../core/database/providers.dart';
import '../../core/study_day.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/chunky_button.dart';
import '../../core/widgets/flip_card.dart';
import '../../core/widgets/game_card.dart';
import '../../core/widgets/hanko_stamp.dart';
import '../../core/widgets/level_badge.dart';
import '../../core/widgets/speak_button.dart';
import '../../l10n/app_localizations.dart';
import '../progress/progress_providers.dart';
import 'sm2.dart';
import 'srs_providers.dart';

/// Short interval for the rating buttons: "1 mnt", "10 mnt", "4 hr".
String intervalLabel(AppLocalizations l10n, Duration d) {
  if (d.inMinutes < 60) return l10n.intervalMinutes(math.max(1, d.inMinutes));
  if (d.inHours < 24) return l10n.intervalHours(d.inHours);
  final days = d.inDays;
  if (days < 30) return l10n.intervalDays(days);
  if (days < 365) return l10n.intervalMonths((days / 30).round());
  return l10n.intervalYears((days / 365).round());
}

/// Daily SRS review (PRD F5, ui-design §5.5): card front → tap to flip →
/// Lagi / Sulit / Baik / Mudah with the resulting interval on each button.
/// Cards that come back within the session (learning steps) are shown again
/// at the end. ✕ leaves; every answer is already saved.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  /// Cards still to show this session; answered learning cards go back in.
  List<ReviewItem>? _queue;
  int _total = 0;

  /// New cards held back by today's limit when nothing is left to show.
  int _waiting = 0;
  bool _limitReached = false;
  int _answered = 0;
  int _again = 0;
  bool _flipped = false;
  final _started = Stopwatch()..start();
  final _cardTimer = Stopwatch();

  /// Learning cards that come back later than this wait for another session.
  static const _sameSession = Duration(minutes: 20);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await loadReviewQueue(ref);
    final waiting = items.isEmpty ? await waitingNewCards(ref) : 0;
    final newLeft = items.isEmpty ? await newLeftToday(await ref.read(userDbProvider.future)) : 1;
    if (!mounted) return;
    setState(() {
      _queue = [...items];
      _total = items.length;
      _waiting = waiting;
      _limitReached = newLeft == 0;
      _cardTimer
        ..reset()
        ..start();
    });
  }

  void _flip() {
    setState(() => _flipped = true);
    autoSpeak(ref, _queue!.first.spoken);
  }

  void _answer(Rating rating) {
    final queue = _queue!;
    final item = queue.first;
    final next = Sm2.answer(item.schedule, rating);
    final ms = _cardTimer.elapsedMilliseconds;
    final due = DateTime.now().toUtc().add(next.interval).toIso8601String();
    writeUserDb(
      ref.read(userDbProvider.future),
      (db) => db.saveReview(
        item.card,
        state: next.state.dbName,
        intervalDays: next.intervalDays,
        ease: next.ease,
        reps: next.reps,
        lapses: next.lapses,
        dueAt: due,
        rating: rating.value,
        studyDate: todayStudyDate(),
        durationMs: math.min(ms, 60000),
        xp: rating == Rating.again ? 0 : 5,
      ),
    );
    HapticFeedback.selectionClick();
    setState(() {
      queue.removeAt(0);
      _answered++;
      if (rating == Rating.again) _again++;
      final learning = next.state == CardState.learning || next.state == CardState.relearning;
      if (learning && next.interval <= _sameSession) {
        queue.add(
          ReviewItem(
            card: item.card.copyWith(
              state: next.state.dbName,
              intervalDays: next.intervalDays,
              ease: next.ease,
              reps: next.reps,
              lapses: next.lapses,
            ),
            front: item.front,
            reading: item.reading,
            romaji: item.romaji,
            back: item.back,
            jlpt: item.jlpt,
            speech: item.speech,
          ),
        );
      }
      _flipped = false;
      _cardTimer
        ..reset()
        ..start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Loaded up front so the first card is read aloud straight away.
    ref.watch(speechAutoplayProvider);
    final queue = _queue;
    if (queue == null) return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
    if (_total == 0) return _Empty(waiting: _waiting, limitReached: _limitReached, onAdded: _load);
    if (queue.isEmpty) {
      _started.stop();
      return Scaffold(
        body: _Summary(answered: _answered, again: _again, elapsed: _started.elapsed),
      );
    }

    final item = queue.first;
    final previews = Sm2.preview(item.schedule);
    // Re-shown learning cards extend the session, so progress is measured
    // against what is answered plus what is left.
    final progress = _answered / (_answered + queue.length);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: l10n.quit,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.reviewLeft(queue.length)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(value: progress, minHeight: 6),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Flashcard(
                  key: ValueKey('${item.card.id}-$_answered'),
                  item: item,
                  flipped: _flipped,
                  onFlip: _flip,
                ),
              ),
              const SizedBox(height: AppSpace.l),
              AnimatedSwitcher(
                duration: AppDurations.crossFade,
                child: _flipped
                    ? _RatingBar(previews: previews, onRate: _answer)
                    : ChunkyButton(
                        key: const ValueKey('flip'),
                        label: l10n.showAnswer,
                        onPressed: _flip,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Flashcard extends StatelessWidget {
  const _Flashcard({super.key, required this.item, required this.flipped, required this.onFlip});

  final ReviewItem item;
  final bool flipped;
  final VoidCallback onFlip;

  @override
  Widget build(BuildContext context) => FlipCard(
    flipped: flipped,
    onFlip: onFlip,
    front: _Face(item: item, back: false),
    back: _Face(item: item, back: true),
  );
}

class _Face extends StatelessWidget {
  const _Face({required this.item, required this.back});
  final ReviewItem item;
  final bool back;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    const ja = Locale('ja');
    final size = item.front.length <= 2 ? 96.0 : (item.front.length <= 4 ? 64.0 : 44.0);
    if (item.reversed && !back) {
      // Meaning → Japanese: the meaning asks, the full word card answers.
      return GameCard(
        radius: AppRadius.card,
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.recallJapanese, style: AppText.label.copyWith(color: c.inkMuted)),
            const SizedBox(height: AppSpace.m),
            Text(
              item.back,
              textAlign: TextAlign.center,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: AppText.title1.copyWith(color: c.ink),
            ),
            const SizedBox(height: AppSpace.l),
            Text(l10n.tapToFlip, style: AppText.bodySmall.copyWith(color: c.inkMuted)),
          ],
        ),
      );
    }
    return GameCard(
      radius: AppRadius.card,
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (back && item.reading != null)
            Text(
              item.reading!,
              locale: ja,
              style: AppText.bodyJp.copyWith(fontSize: 22, color: c.inkMuted),
            ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              item.front,
              locale: ja,
              style: AppText.displayCard.copyWith(fontSize: size, color: c.ink),
            ),
          ),
          const SizedBox(height: AppSpace.l),
          if (!back)
            Text(l10n.tapToFlip, style: AppText.bodySmall.copyWith(color: c.inkMuted))
          else ...[
            Wrap(
              spacing: AppSpace.m,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (item.romaji != null) Text(item.romaji!, style: AppText.body.copyWith(color: c.inkMuted)),
                if (item.jlpt case final level?) LevelBadge(level),
                SpeakButton(item.spoken, size: 24),
              ],
            ),
            const SizedBox(height: AppSpace.l),
            Text(
              item.back,
              textAlign: TextAlign.center,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: AppText.title2.copyWith(color: c.ink),
            ),
          ],
        ],
      ),
    );
  }
}

/// Lagi (seal outline) · Sulit · Baik (filled primary) · Mudah, each with the
/// interval it gives (ui-design §5.5).
class _RatingBar extends StatelessWidget {
  const _RatingBar({required this.previews, required this.onRate});
  final Map<Rating, Duration> previews;
  final ValueChanged<Rating> onRate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final labels = {
      Rating.again: l10n.rateAgain,
      Rating.hard: l10n.rateHard,
      Rating.good: l10n.rateGood,
      Rating.easy: l10n.rateEasy,
    };
    return Row(
      key: const ValueKey('rating'),
      spacing: AppSpace.s,
      children: [
        for (final r in Rating.values)
          Expanded(
            child: _RateButton(
              label: labels[r]!,
              interval: intervalLabel(l10n, previews[r]!),
              filled: r == Rating.good,
              border: r == Rating.again ? c.seal : (r == Rating.good ? c.primary : c.line),
              onTap: () => onRate(r),
            ),
          ),
      ],
    );
  }
}

class _RateButton extends StatelessWidget {
  const _RateButton({
    required this.label,
    required this.interval,
    required this.filled,
    required this.border,
    required this.onTap,
  });

  final String label;
  final String interval;
  final bool filled;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = filled ? c.onPrimary : c.ink;
    return Material(
      color: filled ? c.primary : c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        side: BorderSide(color: border, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.control),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.s, horizontal: AppSpace.xs),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label.copyWith(color: fg, fontWeight: FontWeight.w600),
                ),
                Text(interval, maxLines: 1, style: AppText.bodySmall.copyWith(color: filled ? fg : c.inkMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// End of session (ui-design §5.5): stamp, cards, Lagi count, time.
class _Summary extends ConsumerWidget {
  const _Summary({required this.answered, required this.again, required this.elapsed});
  final int answered;
  final int again;
  final Duration elapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final streak = ref.watch(streakProvider);
    final accuracy = answered == 0 ? 1.0 : (answered - again) / answered;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          children: [
            const Spacer(),
            // 済 done · 習 needs practice (many Lagi).
            HankoStamp(character: accuracy >= 0.8 ? '済' : '習'),
            const SizedBox(height: AppSpace.xl),
            Text(l10n.sessionDone, style: AppText.title1.copyWith(color: c.ink)),
            const SizedBox(height: AppSpace.l),
            Text(
              l10n.reviewSummary(answered, answered - again, again, math.max(1, elapsed.inMinutes)),
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: c.inkMuted),
            ),
            if (streak.current > 0) ...[
              const SizedBox(height: AppSpace.s),
              Text(l10n.streakDays(streak.current), style: AppText.body.copyWith(color: c.seal)),
            ],
            const Spacer(),
            ChunkyButton(label: l10n.done, onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }
}

/// Nothing due (PRD F5 empty state): one tap adds the next N5 words. When
/// today's new-card limit is used up, adding more would show nothing, so it
/// says the [waiting] cards come tomorrow instead.
class _Empty extends ConsumerWidget {
  const _Empty({required this.waiting, required this.limitReached, required this.onAdded});

  final int waiting;
  final bool limitReached;

  /// Reloads the session once the words are in.
  final Future<void> Function() onAdded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final perDay = (ref.watch(srsLimitsProvider).value ?? const SrsLimits()).newPerDay;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Center(child: HankoStamp(character: '続')),
              const SizedBox(height: AppSpace.xl),
              Text(
                !limitReached
                    ? l10n.reviewEmpty
                    : waiting > 0
                    ? l10n.newLimitReached(perDay, waiting)
                    : l10n.newLimitDone(perDay),
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: c.ink),
              ),
              const Spacer(),
              if (limitReached)
                ChunkyButton(label: l10n.done, onPressed: () => Navigator.of(context).pop())
              else
                ChunkyButton(
                  label: l10n.addN5Words(perDay),
                  onPressed: () async {
                    await addNextLevelWords(ref, level: 5, count: perDay);
                    await onAdded();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
