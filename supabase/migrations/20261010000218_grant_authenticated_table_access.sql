-- This project does not grant table privileges to API roles by default.
-- Grant only what the RLS policies allow; anon gets nothing. No DELETE:
-- deletion is a soft delete (PRD §8.6).
grant select, update on public.profiles to authenticated;

grant select, insert, update on public.user_bookmarks to authenticated;
grant select, insert, update on public.user_srs_cards to authenticated;
grant select, insert, update on public.user_lesson_progress to authenticated;
grant select, insert, update on public.user_settings to authenticated;
grant select, insert, update on public.user_daily_stats to authenticated;

-- Append-only
grant select, insert on public.user_review_logs to authenticated;
grant select, insert on public.user_exercise_attempts to authenticated;
grant select, insert on public.user_game_scores to authenticated;
grant select, insert on public.user_streak_freezes to authenticated;
