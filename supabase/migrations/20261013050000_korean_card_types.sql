-- Korean as a second study language adds two review card types: Hangul
-- letters ('hangul', item = the letter) and Korean words ('ko_word', item =
-- the word id from content.db / korean.db). Without them every push of the
-- cards table failed, and with it the rest of the sync.

alter table public.user_srs_cards drop constraint user_srs_cards_card_type_check;
alter table public.user_srs_cards add constraint user_srs_cards_card_type_check
  check (card_type in ('word', 'kana', 'kanji', 'grammar', 'conjugation', 'hangul', 'ko_word'));
