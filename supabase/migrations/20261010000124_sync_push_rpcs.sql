-- Push RPCs (PRD §8.3–8.4). One function per table; each applies the
-- table's conflict rule inside one statement. SECURITY INVOKER so RLS still
-- applies; user_id always comes from the session, never from the payload.
-- Each returns the number of rows inserted or updated.

-- Bookmarks / settings / daily stats: last-write-wins on client_updated_at.
create or replace function public.sync_push_bookmarks(rows jsonb)
returns integer
language plpgsql
security invoker
set search_path = ''
as $$
declare n integer;
begin
  insert into public.user_bookmarks as t
    (user_id, id, word_id, label_snapshot, created_at, client_updated_at, deleted_at)
  select (select auth.uid()), r.id, r.word_id, r.label_snapshot, r.created_at, r.client_updated_at, r.deleted_at
  from jsonb_to_recordset(rows) as r(
    id uuid, word_id integer, label_snapshot text, created_at timestamptz,
    client_updated_at timestamptz, deleted_at timestamptz)
  on conflict (user_id, id) do update set
    word_id = excluded.word_id,
    label_snapshot = excluded.label_snapshot,
    client_updated_at = excluded.client_updated_at,
    deleted_at = excluded.deleted_at
  where excluded.client_updated_at > t.client_updated_at;
  get diagnostics n = row_count;
  return n;
end;
$$;

-- SRS cards: higher reps wins, then client_updated_at.
create or replace function public.sync_push_srs_cards(rows jsonb)
returns integer
language plpgsql
security invoker
set search_path = ''
as $$
declare n integer;
begin
  insert into public.user_srs_cards as t
    (user_id, id, card_type, item_id, direction, label_snapshot, state, due_at,
     interval_days, ease, reps, lapses, is_orphan, created_at, client_updated_at, deleted_at)
  select (select auth.uid()), r.id, r.card_type, r.item_id, r.direction, r.label_snapshot, r.state, r.due_at,
         r.interval_days, r.ease, r.reps, r.lapses, coalesce(r.is_orphan, false), r.created_at,
         r.client_updated_at, r.deleted_at
  from jsonb_to_recordset(rows) as r(
    id uuid, card_type text, item_id text, direction text, label_snapshot text, state text,
    due_at timestamptz, interval_days real, ease real, reps integer, lapses integer,
    is_orphan boolean, created_at timestamptz, client_updated_at timestamptz, deleted_at timestamptz)
  on conflict (user_id, id) do update set
    item_id = excluded.item_id,
    label_snapshot = excluded.label_snapshot,
    state = excluded.state,
    due_at = excluded.due_at,
    interval_days = excluded.interval_days,
    ease = excluded.ease,
    reps = excluded.reps,
    lapses = excluded.lapses,
    is_orphan = excluded.is_orphan,
    client_updated_at = excluded.client_updated_at,
    deleted_at = excluded.deleted_at
  where (excluded.reps, excluded.client_updated_at) > (t.reps, t.client_updated_at);
  get diagnostics n = row_count;
  return n;
end;
$$;

-- Lesson progress: most advanced status wins, then score, then client_updated_at.
create or replace function public.lesson_status_rank(status text)
returns integer
language sql
immutable
set search_path = ''
as $$
  select case status when 'done' then 2 when 'in_progress' then 1 else 0 end;
$$;

create or replace function public.sync_push_lesson_progress(rows jsonb)
returns integer
language plpgsql
security invoker
set search_path = ''
as $$
declare n integer;
begin
  insert into public.user_lesson_progress as t
    (user_id, id, lesson_id, status, score, completed_at, client_updated_at, deleted_at)
  select (select auth.uid()), r.id, r.lesson_id, r.status, r.score, r.completed_at, r.client_updated_at, r.deleted_at
  from jsonb_to_recordset(rows) as r(
    id uuid, lesson_id text, status text, score real, completed_at timestamptz,
    client_updated_at timestamptz, deleted_at timestamptz)
  on conflict (user_id, id) do update set
    status = excluded.status,
    score = excluded.score,
    completed_at = excluded.completed_at,
    client_updated_at = excluded.client_updated_at,
    deleted_at = excluded.deleted_at
  where (public.lesson_status_rank(excluded.status), coalesce(excluded.score, -1), excluded.client_updated_at)
      > (public.lesson_status_rank(t.status), coalesce(t.score, -1), t.client_updated_at);
  get diagnostics n = row_count;
  return n;
end;
$$;

create or replace function public.sync_push_settings(rows jsonb)
returns integer
language plpgsql
security invoker
set search_path = ''
as $$
declare n integer;
begin
  insert into public.user_settings as t (user_id, key, value, client_updated_at)
  select (select auth.uid()), r.key, r.value, r.client_updated_at
  from jsonb_to_recordset(rows) as r(key text, value jsonb, client_updated_at timestamptz)
  on conflict (user_id, key) do update set
    value = excluded.value,
    client_updated_at = excluded.client_updated_at
  where excluded.client_updated_at > t.client_updated_at;
  get diagnostics n = row_count;
  return n;
end;
$$;

-- Daily stats: one writer per (date, device), so last-write-wins never loses data.
create or replace function public.sync_push_daily_stats(rows jsonb)
returns integer
language plpgsql
security invoker
set search_path = ''
as $$
declare n integer;
begin
  insert into public.user_daily_stats as t
    (user_id, date, device_id, new_count, review_count, correct_count, study_ms, xp, client_updated_at)
  select (select auth.uid()), r.date, r.device_id, r.new_count, r.review_count, r.correct_count,
         r.study_ms, r.xp, r.client_updated_at
  from jsonb_to_recordset(rows) as r(
    date date, device_id uuid, new_count integer, review_count integer, correct_count integer,
    study_ms integer, xp integer, client_updated_at timestamptz)
  on conflict (user_id, date, device_id) do update set
    new_count = excluded.new_count,
    review_count = excluded.review_count,
    correct_count = excluded.correct_count,
    study_ms = excluded.study_ms,
    xp = excluded.xp,
    client_updated_at = excluded.client_updated_at
  where excluded.client_updated_at > t.client_updated_at;
  get diagnostics n = row_count;
  return n;
end;
$$;

-- Append-only tables: idempotent insert, duplicates ignored.
create or replace function public.sync_push_review_logs(rows jsonb)
returns integer
language plpgsql
security invoker
set search_path = ''
as $$
declare n integer;
begin
  insert into public.user_review_logs
    (id, user_id, card_id, rating, reviewed_at, study_date, prev_state, prev_interval, new_interval, duration_ms)
  select r.id, (select auth.uid()), r.card_id, r.rating, r.reviewed_at, r.study_date, r.prev_state,
         r.prev_interval, r.new_interval, r.duration_ms
  from jsonb_to_recordset(rows) as r(
    id uuid, card_id uuid, rating smallint, reviewed_at timestamptz, study_date date,
    prev_state text, prev_interval real, new_interval real, duration_ms integer)
  on conflict do nothing;
  get diagnostics n = row_count;
  return n;
end;
$$;

create or replace function public.sync_push_exercise_attempts(rows jsonb)
returns integer
language plpgsql
security invoker
set search_path = ''
as $$
declare n integer;
begin
  insert into public.user_exercise_attempts
    (id, user_id, exercise_type, item_id, correct, answered_at, study_date, duration_ms)
  select r.id, (select auth.uid()), r.exercise_type, r.item_id, r.correct, r.answered_at, r.study_date, r.duration_ms
  from jsonb_to_recordset(rows) as r(
    id uuid, exercise_type text, item_id text, correct boolean, answered_at timestamptz,
    study_date date, duration_ms integer)
  on conflict do nothing;
  get diagnostics n = row_count;
  return n;
end;
$$;

create or replace function public.sync_push_game_scores(rows jsonb)
returns integer
language plpgsql
security invoker
set search_path = ''
as $$
declare n integer;
begin
  insert into public.user_game_scores (id, user_id, game, score, accuracy, played_at)
  select r.id, (select auth.uid()), r.game, r.score, r.accuracy, r.played_at
  from jsonb_to_recordset(rows) as r(id uuid, game text, score integer, accuracy real, played_at timestamptz)
  on conflict do nothing;
  get diagnostics n = row_count;
  return n;
end;
$$;

create or replace function public.sync_push_streak_freezes(rows jsonb)
returns integer
language plpgsql
security invoker
set search_path = ''
as $$
declare n integer;
begin
  insert into public.user_streak_freezes (id, user_id, covered_date, created_at)
  select r.id, (select auth.uid()), r.covered_date, r.created_at
  from jsonb_to_recordset(rows) as r(id uuid, covered_date date, created_at timestamptz)
  on conflict do nothing;
  get diagnostics n = row_count;
  return n;
end;
$$;

-- Only signed-in users may call the push RPCs.
do $$
declare f text;
begin
  foreach f in array array[
    'sync_push_bookmarks', 'sync_push_srs_cards', 'sync_push_lesson_progress', 'sync_push_settings',
    'sync_push_daily_stats', 'sync_push_review_logs', 'sync_push_exercise_attempts',
    'sync_push_game_scores', 'sync_push_streak_freezes'
  ] loop
    execute format('revoke execute on function public.%I(jsonb) from public, anon', f);
    execute format('grant execute on function public.%I(jsonb) to authenticated', f);
  end loop;
end;
$$;

-- Trigger-only functions are not meant to be called directly.
revoke execute on function public.set_updated_at() from public, anon, authenticated;
revoke execute on function public.handle_new_user() from public, anon, authenticated;
