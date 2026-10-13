import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/providers.dart';
import '../../core/text/hangul.dart';
import '../../core/text/normalize.dart';
import '../../core/text/romaji_to_kana.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../conjugation/conjugation_drill_screen.dart';
import '../grammar/grammar_screen.dart';
import '../learn/path_providers.dart';
import '../learn/study_language.dart';
import '../word/korean_topic_words_screen.dart';
import '../word/level_words_screen.dart';
import '../word/word_providers.dart';
import '../word/word_tile.dart';
import 'quick_search.dart';
import 'search_controller.dart';
import 'search_service.dart';

/// Kamus tab (ui-design §5.3). The field is never rewritten while typing, so
/// a system Japanese IME keeps full control of its composing region (PRD
/// F1.1b); the romaji conversion is shown as a preview below the field.
/// While Korean is being learned it searches the Korean dictionary instead:
/// Hangul, romanization or meaning, without the kana modes.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Quick search may be what first builds this tab.
    if (ref.read(quickSearchProvider)) _focusField();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Quick search: field in view, keyboard up, current text selected so
  /// typing replaces it.
  void _focusField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(quickSearchProvider.notifier).done();
      // Back to the field if a word was left open in this tab.
      Navigator.of(context).popUntil((route) => route.isFirst);
      if (_scroll.hasClients) _scroll.jumpTo(0);
      _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
      _focus.requestFocus();
    });
  }

  void _onChanged(String text) {
    setState(() {}); // preview + clear button
    _debounce?.cancel();
    _debounce = Timer(AppDurations.searchDebounce, () {
      ref.read(searchRequestProvider.notifier).setText(text);
    });
  }

  void _clear() {
    _controller.clear();
    _debounce?.cancel();
    ref.read(searchRequestProvider.notifier).setText('');
    setState(() {});
  }

  /// Fills the field from history and runs the query right away.
  void _searchFor(String query) {
    _controller.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    _debounce?.cancel();
    ref.read(searchRequestProvider.notifier).setText(query);
    setState(() {});
  }

  /// Stores the query in the history (last 10) once it led somewhere.
  void _remember() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    writeUserDb(ref.read(userDbProvider.future), (db) => db.addHistory(query));
  }

  String? _preview(SearchMode mode, {required bool korean}) {
    final text = _controller.text.trim();
    if (korean || text.isEmpty || mode == SearchMode.latin || hasJapanese(text)) return null;
    return mode == SearchMode.katakana ? RomajiToKana.toKatakana(text) : RomajiToKana.toHiragana(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final request = ref.watch(searchRequestProvider);
    final korean = ref.watch(studyLanguageProvider).value == StudyLanguage.ko;
    // Only the dictionary of the language being learned is opened.
    final AsyncValue<Object> dictionary = korean ? ref.watch(koreanDictProvider) : ref.watch(dictionaryProvider);
    final results = ref.watch(korean ? koreanSearchResultsProvider : searchResultsProvider);
    final preview = _preview(request.mode, korean: korean);
    ref.listen(quickSearchProvider, (_, open) {
      if (open) _focusField();
    });
    // A query in the other language means nothing in the new dictionary.
    ref.listen(studyLanguageProvider, (before, now) {
      if (before?.value != null && before?.value != now.value) _clear();
    });

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          controller: _scroll,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            // Scrolling down hides the field, scrolling up a little shows it
            // again (ui-design §5.3).
            SliverFloatingHeader(
              child: ColoredBox(
                color: colors.bg,
                child: _header(context, l10n, colors, request, preview, korean: korean),
              ),
            ),
            ...switch (dictionary) {
              AsyncError() => [_MessageSliver(l10n.dictionaryFailed)],
              AsyncLoading() => [_MessageSliver(l10n.preparingDictionary)],
              _ when request.text.trim().isEmpty => _EmptyState.slivers(onSearch: _searchFor, korean: korean),
              _ => _results(l10n, results.value ?? const [], request, korean: korean),
            },
          ],
        ),
      ),
    );
  }

  List<Widget> _results(AppLocalizations l10n, List<SearchHit> hits, SearchRequest request, {required bool korean}) {
    if (hits.isEmpty) {
      return [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpace.screen),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.searchNoResults(request.text), style: AppText.body.copyWith(color: context.colors.ink)),
                if (!korean && request.mode != SearchMode.latin) ...[
                  const SizedBox(height: AppSpace.m),
                  OutlinedButton(
                    onPressed: () => ref.read(searchRequestProvider.notifier).setMode(SearchMode.latin),
                    child: Text(l10n.searchAsLatin),
                  ),
                ],
              ],
            ),
          ),
        ),
      ];
    }
    return [
      SliverList.separated(
        itemCount: hits.length,
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (_, i) => WordTile(hit: hits[i], onOpen: _remember),
      ),
    ];
  }

  Widget _header(
    BuildContext context,
    AppLocalizations l10n,
    AppColors colors,
    SearchRequest request,
    String? preview, {
    required bool korean,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.m, AppSpace.screen, 0),
          child: SizedBox(
            height: AppSizes.searchFieldHeight,
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              onChanged: _onChanged,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.search,
              // Results already update while typing; the IME's search key
              // must not trigger a second query (PRD F1.1b).
              onSubmitted: (_) {
                _remember();
                FocusScope.of(context).unfocus();
              },
              style: AppText.body.copyWith(color: colors.ink),
              decoration: InputDecoration(
                hintText: korean ? l10n.koreanSearchHint : l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(tooltip: l10n.searchClear, icon: const Icon(Icons.close), onPressed: _clear),
              ),
            ),
          ),
        ),
        // One row (wireframe §5.3); scrolls instead of wrapping on narrow
        // screens or large text. The checkmark keeps selection from being
        // color-only. Korean has no kana modes.
        if (korean)
          const SizedBox(height: AppSpace.s)
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen, vertical: AppSpace.s),
            child: Row(
              spacing: AppSpace.s,
              children: [
                for (final (mode, label) in [
                  (SearchMode.hiragana, l10n.modeHiragana),
                  (SearchMode.katakana, l10n.modeKatakana),
                  (SearchMode.latin, l10n.modeLatin),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: request.mode == mode,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      ref.read(searchRequestProvider.notifier).setMode(mode);
                    },
                  ),
              ],
            ),
          ),
        if (preview != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.s),
            child: Text(
              preview,
              locale: const Locale('ja'),
              style: AppText.bodyJp.copyWith(color: colors.inkMuted),
            ),
          ),
        Divider(color: colors.line, height: 1),
      ],
    );
  }
}

/// Before typing (ui-design §5.3): recent searches, word of the day and
/// browse by JLPT level, or by course topic for Korean.
abstract final class _EmptyState {
  static List<Widget> slivers({required ValueChanged<String> onSearch, required bool korean}) => [
    SliverToBoxAdapter(
      child: _History(onSearch: onSearch, korean: korean),
    ),
    if (korean) ...const [
      SliverToBoxAdapter(child: _WordOfTheDay(korean: true)),
      SliverToBoxAdapter(child: _BrowseTopics()),
    ] else ...const [
      SliverToBoxAdapter(child: _WordOfTheDay(korean: false)),
      SliverToBoxAdapter(child: _StudyTools()),
      SliverToBoxAdapter(child: _BrowseLevels()),
    ],
    const SliverToBoxAdapter(child: SizedBox(height: AppSpace.xxl)),
  ];
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.action});
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.l, AppSpace.s, AppSpace.xs),
    child: Row(
      children: [
        Expanded(
          child: Text(text, style: AppText.label.copyWith(color: context.colors.inkMuted)),
        ),
        ?action,
      ],
    ),
  );
}

class _History extends ConsumerWidget {
  const _History({required this.onSearch, required this.korean});
  final ValueChanged<String> onSearch;

  /// Hides the other language's searches: Japanese text while Korean is
  /// being learned, Hangul otherwise.
  final bool korean;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final history = [
      for (final q in ref.watch(searchHistoryProvider).value ?? const <String>[])
        if (korean ? !hasJapanese(q) : !hasHangul(q)) q,
    ];
    if (history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.l, AppSpace.screen, 0),
        child: Text(l10n.searchEmptyHint, style: AppText.body.copyWith(color: c.inkMuted)),
      );
    }
    final db = ref.read(userDbProvider.future);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          l10n.recentSearches,
          action: TextButton(
            onPressed: () => writeUserDb(db, (db) => db.clearHistory()),
            child: Text(l10n.clearHistory),
          ),
        ),
        for (final q in history)
          ListTile(
            leading: Icon(Icons.history_rounded, color: c.inkMuted),
            title: Text(q, style: AppText.body.copyWith(color: c.ink)),
            onTap: () => onSearch(q),
            trailing: IconButton(
              tooltip: l10n.removeFromHistory,
              icon: Icon(Icons.close_rounded, color: c.inkMuted, size: 20),
              onPressed: () => writeUserDb(db, (db) => db.removeHistory(q)),
            ),
          ),
      ],
    );
  }
}

class _WordOfTheDay extends ConsumerWidget {
  const _WordOfTheDay({required this.korean});
  final bool korean;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final word = ref.watch(korean ? koWordOfTheDayProvider : wordOfTheDayProvider).value;
    if (word == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(AppLocalizations.of(context).wordOfTheDay),
        WordTile(hit: SearchHit.fromBrief(word)),
      ],
    );
  }
}

/// Ways into grammar (F13) and the conjugation drill (F14).
class _StudyTools extends StatelessWidget {
  const _StudyTools();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;

    Widget tool(String glyph, String title, String body, Widget Function() screen, {bool dialog = false}) => ListTile(
      leading: CircleAvatar(
        backgroundColor: c.primary.withValues(alpha: 0.12),
        child: Text(
          glyph,
          locale: const Locale('ja'),
          style: AppText.bodyJp.copyWith(color: c.primaryText),
        ),
      ),
      title: Text(
        title,
        style: AppText.body.copyWith(color: c.ink, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(body, style: AppText.bodySmall.copyWith(color: c.inkMuted)),
      trailing: Icon(Icons.chevron_right_rounded, color: c.inkMuted),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen(), fullscreenDialog: dialog)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(l10n.grammarAndConjugation),
        tool('文', l10n.grammar, l10n.grammarBody, () => const GrammarScreen()),
        tool('活', l10n.conjPractice, l10n.conjPracticeBody, () => const ConjugationDrillScreen(), dialog: true),
      ],
    );
  }
}

class _BrowseLevels extends ConsumerWidget {
  const _BrowseLevels();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final counts = ref.watch(levelCountsProvider).value ?? const <int, int>{};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(l10n.browseByLevel),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
          child: Wrap(
            spacing: AppSpace.s,
            runSpacing: AppSpace.s,
            children: [
              for (var level = 5; level >= 1; level--)
                ActionChip(
                  label: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'N$level',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (counts[level] case final n?)
                          TextSpan(
                            text: '  ${l10n.levelWordCount(n)}',
                            style: TextStyle(color: context.colors.inkMuted),
                          ),
                      ],
                    ),
                  ),
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => LevelWordsScreen(level: level))),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The Korean course topics, each opening its words.
class _BrowseTopics extends ConsumerWidget {
  const _BrowseTopics();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final course = ref.watch(koWordsProvider).value;
    if (course == null) return const SizedBox.shrink();
    final counts = <String, int>{};
    for (final w in course.words) {
      counts[w.topic] = (counts[w.topic] ?? 0) + 1;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(l10n.browseByTopic),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
          child: Wrap(
            spacing: AppSpace.s,
            runSpacing: AppSpace.s,
            children: [
              for (final MapEntry(key: topic, value: title) in course.topics.entries)
                ActionChip(
                  label: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: title.of(l10n.localeName),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (counts[topic] case final n?)
                          TextSpan(
                            text: '  ${l10n.levelWordCount(n)}',
                            style: TextStyle(color: context.colors.inkMuted),
                          ),
                      ],
                    ),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => KoreanTopicWordsScreen(topic: topic, title: title.of(l10n.localeName)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageSliver extends StatelessWidget {
  const _MessageSliver(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.all(AppSpace.screen),
    sliver: SliverToBoxAdapter(
      child: Text(text, style: AppText.body.copyWith(color: context.colors.inkMuted)),
    ),
  );
}
