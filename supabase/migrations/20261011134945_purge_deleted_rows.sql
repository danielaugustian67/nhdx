-- Daily purge of soft-deleted rows (PRD §9, development_plan Fase 4).
-- A deletion stays on the server as a tombstone (`deleted_at`) so other
-- devices pull it; after 30 days it is removed for good. A device offline
-- for longer than that may bring the item back on its next push.

create extension if not exists pg_cron;

create or replace function public.purge_deleted_rows()
returns void
language sql
security definer
set search_path = ''
as $$
  delete from public.user_bookmarks where deleted_at < now() - interval '30 days';
  delete from public.user_srs_cards where deleted_at < now() - interval '30 days';
  delete from public.user_lesson_progress where deleted_at < now() - interval '30 days';
$$;

-- Only the scheduler runs it.
revoke execute on function public.purge_deleted_rows() from public, anon, authenticated;

-- 03:17 UTC (10:17 WIB), off the hour to avoid the shared cron rush.
select cron.unschedule(jobid) from cron.job where jobname = 'purge-deleted-rows';
select cron.schedule('purge-deleted-rows', '17 3 * * *', 'select public.purge_deleted_rows()');
