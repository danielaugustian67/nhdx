-- Keep-alive target for the daily cron-job.org request (development_plan
-- Fase 4). A free-tier project pauses after about a week without outside
-- requests, and pg_cron jobs inside the database do not count. The call
-- reaches Postgres through the REST API but reads no table.
--
--   GET {SUPABASE_URL}/rest/v1/rpc/ping   with header  apikey: <publishable key>

create or replace function public.ping()
returns timestamptz
language sql
stable
security invoker
set search_path = ''
as $$
  select now();
$$;

revoke execute on function public.ping() from public;
grant execute on function public.ping() to anon, authenticated;
