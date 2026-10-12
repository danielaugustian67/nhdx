-- Sync conflict rules + RLS isolation test (PRD §8.4, §12 v1.0 #12).
-- Runs entirely inside one DO block that always ends with RAISE EXCEPTION,
-- so every test row (including the auth.users rows) is rolled back.
-- Run as postgres (SQL editor or MCP execute_sql). Expected output:
--   profile trigger: User A | bookmark insert: 1 | bookmark older ignored: applied=0 label=v1 |
--   bookmark newer wins: applied=1 newer deleted=true |
--   srs higher reps wins over newer time: applied=0 kept=3/review |
--   lesson most advanced wins: applied=0 status=done | review log insert: 1 |
--   review log duplicate ignored: 0 | review log update blocked: permission denied … |
--   future clock rejected: … | RLS: B sees A bookmarks: 0 | RLS: B sees A cards: 0 |
--   RLS: B write as A blocked: … | delete blocked: … | anon RPC blocked: … | anon table read blocked: …
do $$
declare
  a uuid := gen_random_uuid();
  b uuid := gen_random_uuid();
  bm uuid := gen_random_uuid();
  card uuid := gen_random_uuid();
  lp uuid := gen_random_uuid();
  log_id uuid := gen_random_uuid();
  t0 timestamptz := now() - interval '2 hours';
  t1 timestamptz := now() - interval '1 hour';
  t2 timestamptz := now();
  n int;
  v text;
  results text[] := '{}';
begin
  insert into auth.users (id, email, raw_user_meta_data) values
    (a, 'a@test.local', '{"full_name":"User A"}'), (b, 'b@test.local', '{}');
  select display_name into v from public.profiles where user_id = a;
  results := results || format('profile trigger: %s', coalesce(v, 'MISSING'));

  -- act as user A
  perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';

  n := public.sync_push_bookmarks(jsonb_build_array(jsonb_build_object(
    'id', bm, 'word_id', 1358280, 'label_snapshot', 'v1', 'created_at', t0, 'client_updated_at', t1)));
  results := results || format('bookmark insert: %s', n);
  n := public.sync_push_bookmarks(jsonb_build_array(jsonb_build_object(
    'id', bm, 'word_id', 1358280, 'label_snapshot', 'older', 'created_at', t0, 'client_updated_at', t0)));
  select label_snapshot into v from public.user_bookmarks where id = bm;
  results := results || format('bookmark older ignored: applied=%s label=%s', n, v);
  n := public.sync_push_bookmarks(jsonb_build_array(jsonb_build_object(
    'id', bm, 'word_id', 1358280, 'label_snapshot', 'newer', 'created_at', t0, 'client_updated_at', t2, 'deleted_at', t2)));
  select label_snapshot || ' deleted=' || (deleted_at is not null) into v from public.user_bookmarks where id = bm;
  results := results || format('bookmark newer wins: applied=%s %s', n, v);

  perform public.sync_push_srs_cards(jsonb_build_array(jsonb_build_object(
    'id', card, 'card_type', 'word', 'item_id', '1358280', 'direction', 'jp_to_meaning', 'label_snapshot', '食べる',
    'state', 'review', 'interval_days', 4, 'ease', 2.5, 'reps', 3, 'lapses', 0, 'created_at', t0, 'client_updated_at', t0)));
  n := public.sync_push_srs_cards(jsonb_build_array(jsonb_build_object(
    'id', card, 'card_type', 'word', 'item_id', '1358280', 'direction', 'jp_to_meaning', 'label_snapshot', '食べる',
    'state', 'learning', 'interval_days', 1, 'ease', 2.5, 'reps', 2, 'lapses', 1, 'created_at', t0, 'client_updated_at', t2)));
  select reps || '/' || state into v from public.user_srs_cards where id = card;
  results := results || format('srs higher reps wins over newer time: applied=%s kept=%s', n, v);

  perform public.sync_push_lesson_progress(jsonb_build_array(jsonb_build_object(
    'id', lp, 'lesson_id', 'n5-u01-l01', 'status', 'done', 'score', 0.8, 'client_updated_at', t0)));
  n := public.sync_push_lesson_progress(jsonb_build_array(jsonb_build_object(
    'id', lp, 'lesson_id', 'n5-u01-l01', 'status', 'in_progress', 'client_updated_at', t2)));
  select status into v from public.user_lesson_progress where id = lp;
  results := results || format('lesson most advanced wins: applied=%s status=%s', n, v);

  n := public.sync_push_review_logs(jsonb_build_array(jsonb_build_object(
    'id', log_id, 'card_id', card, 'rating', 3, 'reviewed_at', t1, 'study_date', current_date)));
  results := results || format('review log insert: %s', n);
  n := public.sync_push_review_logs(jsonb_build_array(jsonb_build_object(
    'id', log_id, 'card_id', card, 'rating', 3, 'reviewed_at', t1, 'study_date', current_date)));
  results := results || format('review log duplicate ignored: %s', n);
  begin
    update public.user_review_logs set rating = 1 where id = log_id;
    get diagnostics n = row_count;
    results := results || format('review log update (append-only): rows=%s', n);
  exception when others then
    results := results || format('review log update blocked: %s', sqlerrm);
  end;

  begin
    perform public.sync_push_settings(jsonb_build_array(jsonb_build_object(
      'key', 'learning_level', 'value', '"n5"', 'client_updated_at', now() + interval '2 days')));
    results := results || 'future clock: NOT rejected';
  exception when others then
    results := results || format('future clock rejected: %s', sqlerrm);
  end;

  -- act as user B
  perform set_config('request.jwt.claims', json_build_object('sub', b, 'role', 'authenticated')::text, true);
  select count(*) into n from public.user_bookmarks;
  results := results || format('RLS: B sees A bookmarks: %s', n);
  select count(*) into n from public.user_srs_cards;
  results := results || format('RLS: B sees A cards: %s', n);
  begin
    insert into public.user_bookmarks (user_id, id, word_id, label_snapshot, created_at, client_updated_at)
    values (a, gen_random_uuid(), 1, 'x', now(), now());
    results := results || 'RLS: B wrote as A: NOT blocked';
  exception when others then
    results := results || format('RLS: B write as A blocked: %s', sqlerrm);
  end;
  begin
    delete from public.user_bookmarks;
    results := results || 'delete: NOT blocked';
  exception when others then
    results := results || format('delete blocked: %s', sqlerrm);
  end;

  -- anonymous
  perform set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true);
  execute 'set local role anon';
  begin
    perform public.sync_push_bookmarks('[]'::jsonb);
    results := results || 'anon RPC: NOT blocked';
  exception when others then
    results := results || format('anon RPC blocked: %s', sqlerrm);
  end;
  begin
    select count(*) into n from public.user_bookmarks;
    results := results || format('anon table read: NOT blocked (%s rows)', n);
  exception when others then
    results := results || format('anon table read blocked: %s', sqlerrm);
  end;

  raise exception 'TEST RESULTS (rolled back): %', array_to_string(results, ' | ');
end;
$$;
