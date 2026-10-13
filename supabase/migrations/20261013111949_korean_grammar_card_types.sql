-- Korean grammar points ('ko_grammar', item = 'ko1-…' from content.db) and
-- the Korean conjugation drill ('ko_conjugation', item = 'wordId:form') add
-- two more review card types.

alter table public.user_srs_cards drop constraint user_srs_cards_card_type_check;
alter table public.user_srs_cards add constraint user_srs_cards_card_type_check
  check (card_type in (
    'word', 'kana', 'kanji', 'grammar', 'conjugation', 'hangul', 'ko_word', 'ko_grammar', 'ko_conjugation'
  ));
