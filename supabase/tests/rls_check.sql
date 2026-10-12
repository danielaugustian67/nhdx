-- RLS and push-rule check (development_plan Fase 4 "RLS testing").
-- Run in the SQL editor (or MCP execute_sql) of a project. It creates two
-- throwaway users, acts as each, and always ends with an error that rolls
-- everything back; the error message is the result. Expected:
--   A bookmark pushed=1 | fewer reps accepted=0 reps now=2 | log=1 |
--   future clock refused | B sees A rows=0 | B updated A card=0 |
--   B insert as A refused | B push same id=1 | log update refused |
--   delete refused | A label still=x | anon rpc refused | anon select refused
do $$
declare
  a uuid := gen_random_uuid();
  b uuid := gen_random_uuid();
  card uuid := gen_random_uuid();
  out text := '';
  n int;
begin
  insert into auth.users (id, instance_id, aud, role, email)
  values (a, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'rls-a@test.invalid'),
         (b, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'rls-b@test.invalid');

  set local role authenticated;

  -- User A pushes a bookmark, a card (reps 2) and a review log.
  perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
  n := public.sync_push_bookmarks(jsonb_build_array(jsonb_build_object(
    'id', card, 'word_id', 42, 'label_snapshot', 'x', 'created_at', now(), 'client_updated_at', now(), 'deleted_at', null)));
  out := out || 'A bookmark pushed=' || n;
  n := public.sync_push_srs_cards(jsonb_build_array(jsonb_build_object(
    'id', card, 'card_type', 'word', 'item_id', '42', 'direction', 'jp_to_meaning', 'label_snapshot', 'x',
    'state', 'review', 'due_at', now(), 'interval_days', 6, 'ease', 2.5, 'reps', 2, 'lapses', 0,
    'is_orphan', false, 'created_at', now(), 'client_updated_at', now() - interval '1 hour', 'deleted_at', null)));
  -- A newer write with fewer reviews loses.
  n := public.sync_push_srs_cards(jsonb_build_array(jsonb_build_object(
    'id', card, 'card_type', 'word', 'item_id', '42', 'direction', 'jp_to_meaning', 'label_snapshot', 'x',
    'state', 'learning', 'due_at', now(), 'interval_days', 0, 'ease', 2.5, 'reps', 1, 'lapses', 1,
    'is_orphan', false, 'created_at', now(), 'client_updated_at', now(), 'deleted_at', null)));
  out := out || ' | fewer reps accepted=' || n || ' reps now=' || (select reps from public.user_srs_cards where id = card);
  n := public.sync_push_review_logs(jsonb_build_array(jsonb_build_object(
    'id', gen_random_uuid(), 'card_id', card, 'rating', 3, 'reviewed_at', now(), 'study_date', current_date)));
  out := out || ' | log=' || n;

  -- Clock more than a day ahead is refused.
  begin
    perform public.sync_push_settings(jsonb_build_array(jsonb_build_object(
      'key', 'k', 'value', to_jsonb('v'::text), 'client_updated_at', now() + interval '3 days')));
    out := out || ' | future clock ACCEPTED';
  exception when others then
    out := out || ' | future clock refused';
  end;

  -- User B sees nothing of A and cannot change it.
  perform set_config('request.jwt.claims', json_build_object('sub', b, 'role', 'authenticated')::text, true);
  out := out || ' | B sees A rows=' || (select count(*) from public.user_bookmarks) + (select count(*) from public.user_srs_cards)
         + (select count(*) from public.user_review_logs);
  update public.user_srs_cards set reps = 99 where id = card;
  get diagnostics n = row_count;
  out := out || ' | B updated A card=' || n;
  begin
    insert into public.user_bookmarks (user_id, id, word_id, label_snapshot, created_at, client_updated_at)
    values (a, gen_random_uuid(), 7, 'y', now(), now());
    out := out || ' | B insert as A ALLOWED';
  exception when others then
    out := out || ' | B insert as A refused';
  end;
  -- B pushing the same id makes B's own row, never touches A's.
  n := public.sync_push_bookmarks(jsonb_build_array(jsonb_build_object(
    'id', card, 'word_id', 42, 'label_snapshot', 'b', 'created_at', now(), 'client_updated_at', now() + interval '1 hour', 'deleted_at', null)));
  out := out || ' | B push same id=' || n;

  -- Append-only and no deletes, even for the owner.
  perform set_config('request.jwt.claims', json_build_object('sub', a, 'role', 'authenticated')::text, true);
  begin
    update public.user_review_logs set rating = 1;
    out := out || ' | log update ALLOWED';
  exception when others then
    out := out || ' | log update refused';
  end;
  begin
    delete from public.user_bookmarks;
    out := out || ' | delete ALLOWED';
  exception when others then
    out := out || ' | delete refused';
  end;
  out := out || ' | A label still=' || (select label_snapshot from public.user_bookmarks where id = card);

  -- Anonymous callers get nothing.
  set local role anon;
  begin
    perform public.sync_push_bookmarks('[]'::jsonb);
    out := out || ' | anon rpc ALLOWED';
  exception when others then
    out := out || ' | anon rpc refused';
  end;
  begin
    perform count(*) from public.user_bookmarks;
    out := out || ' | anon select ALLOWED';
  exception when others then
    out := out || ' | anon select refused';
  end;

  raise exception 'RESULT %', out;
end;
$$;
