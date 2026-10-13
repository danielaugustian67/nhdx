import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/providers.dart';
import '../learn/study_language.dart';
import 'search_service.dart';

class SearchRequest {
  const SearchRequest(this.text, this.mode);
  final String text;
  final SearchMode mode;
}

class SearchRequestNotifier extends Notifier<SearchRequest> {
  @override
  SearchRequest build() => const SearchRequest('', SearchMode.hiragana);

  void setText(String text) => state = SearchRequest(text, state.mode);
  void setMode(SearchMode mode) => state = SearchRequest(state.text, mode);
}

final searchRequestProvider = NotifierProvider<SearchRequestNotifier, SearchRequest>(SearchRequestNotifier.new);

/// Results for the current (debounced) request. Local data: the UI keeps the
/// previous results while a new query runs instead of showing a spinner.
final searchResultsProvider = FutureProvider<List<SearchHit>>((ref) async {
  final request = ref.watch(searchRequestProvider);
  if (request.text.trim().isEmpty) return const [];
  final service = await ref.watch(searchServiceProvider.future);
  return service.search(request.text, mode: request.mode);
});

/// Results in the Korean dictionary for the same request (Korean is being
/// learned), with meanings in the app language where the word has one.
final koreanSearchResultsProvider = FutureProvider<List<SearchHit>>((ref) async {
  final request = ref.watch(searchRequestProvider);
  if (request.text.trim().isEmpty) return const [];
  final language = ref.watch(contentLanguageProvider);
  final service = await ref.watch(koreanSearchServiceProvider.future);
  return service.search(request.text, language: language);
});
