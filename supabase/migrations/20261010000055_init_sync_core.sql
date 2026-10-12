-- Nihondx v1.0 sync schema (PRD §8, §9.D)
-- client_updated_at = device time of the change (conflict resolution)
-- updated_at        = server now() via trigger (pull cursor only)
-- Natural-key tables: PK (user_id, id) with deterministic UUIDv5 ids.

-- ===== Shared trigger =====
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  if (to_jsonb(new) ->> 'client_updated_at')::timestamptz > now() + interval '24 hours' then
    raise exception 'client_updated_at is more than 24 hours in the future'
      using errcode = '22008';
  end if;
  return new;
end;
$$;

-- ===== Profiles =====
create table public.profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  updated_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (user_id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'));
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ===== Natural-key tables =====
create table public.user_bookmarks (
  user_id uuid not null references auth.users (id) on delete cascade,
  id uuid not null,
  word_id integer not null,
  label_snapshot text not null,
  created_at timestamptz not null,
  client_updated_at timestamptz not null,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  primary key (user_id, id),
  unique (user_id, word_id)
);

create table public.user_srs_cards (
  user_id uuid not null references auth.users (id) on delete cascade,
  id uuid not null,
  card_type text not null check (card_type in ('word', 'kana', 'kanji', 'grammar', 'conjugation')),
  item_id text not null,
  direction text not null default 'jp_to_meaning',
  label_snapshot text not null,
  state text not null check (state in ('new', 'learning', 'review', 'relearning')),
  due_at timestamptz,
  interval_days real not null default 0,
  ease real not null default 2.5,
  reps integer not null default 0,
  lapses integer not null default 0,
  is_orphan boolean not null default false,
  created_at timestamptz not null,
  client_updated_at timestamptz not null,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  primary key (user_id, id),
  unique (user_id, card_type, item_id, direction)
);

create table public.user_lesson_progress (
  user_id uuid not null references auth.users (id) on delete cascade,
  id uuid not null,
  lesson_id text not null,
  status text not null check (status in ('not_started', 'in_progress', 'done')),
  score real,
  completed_at timestamptz,
  client_updated_at timestamptz not null,
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  primary key (user_id, id),
  unique (user_id, lesson_id)
);

create table public.user_settings (
  user_id uuid not null references auth.users (id) on delete cascade,
  key text not null,
  value jsonb,
  client_updated_at timestamptz not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, key)
);

-- ===== Append-only tables (updated_at = time received by the server) =====
create table public.user_review_logs (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  card_id uuid not null,
  rating smallint not null check (rating between 1 and 4),
  reviewed_at timestamptz not null,
  study_date date not null,
  prev_state text,
  prev_interval real,
  new_interval real,
  duration_ms integer,
  updated_at timestamptz not null default now()
);

create table public.user_exercise_attempts (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  exercise_type text not null,
  item_id text,
  correct boolean not null,
  answered_at timestamptz not null,
  study_date date not null,
  duration_ms integer,
  updated_at timestamptz not null default now()
);

create table public.user_game_scores (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  game text not null,
  score integer not null,
  accuracy real,
  played_at timestamptz not null,
  updated_at timestamptz not null default now()
);

create table public.user_streak_freezes (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  covered_date date not null,
  created_at timestamptz not null,
  updated_at timestamptz not null default now(),
  unique (user_id, covered_date)
);

-- ===== Per-device table =====
create table public.user_daily_stats (
  user_id uuid not null references auth.users (id) on delete cascade,
  date date not null,
  device_id uuid not null,
  new_count integer not null default 0,
  review_count integer not null default 0,
  correct_count integer not null default 0,
  study_ms integer not null default 0,
  xp integer not null default 0,
  client_updated_at timestamptz not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, date, device_id)
);

-- ===== updated_at triggers =====
create trigger set_updated_at before insert or update on public.profiles
  for each row execute function public.set_updated_at();
create trigger set_updated_at before insert or update on public.user_bookmarks
  for each row execute function public.set_updated_at();
create trigger set_updated_at before insert or update on public.user_srs_cards
  for each row execute function public.set_updated_at();
create trigger set_updated_at before insert or update on public.user_lesson_progress
  for each row execute function public.set_updated_at();
create trigger set_updated_at before insert or update on public.user_settings
  for each row execute function public.set_updated_at();
create trigger set_updated_at before insert on public.user_review_logs
  for each row execute function public.set_updated_at();
create trigger set_updated_at before insert on public.user_exercise_attempts
  for each row execute function public.set_updated_at();
create trigger set_updated_at before insert on public.user_game_scores
  for each row execute function public.set_updated_at();
create trigger set_updated_at before insert on public.user_streak_freezes
  for each row execute function public.set_updated_at();
create trigger set_updated_at before insert or update on public.user_daily_stats
  for each row execute function public.set_updated_at();

-- ===== Pull-cursor indexes: (user_id, updated_at) on every synced table =====
create index on public.user_bookmarks (user_id, updated_at);
create index on public.user_srs_cards (user_id, updated_at);
create index on public.user_lesson_progress (user_id, updated_at);
create index on public.user_settings (user_id, updated_at);
create index on public.user_review_logs (user_id, updated_at);
create index on public.user_exercise_attempts (user_id, updated_at);
create index on public.user_game_scores (user_id, updated_at);
create index on public.user_streak_freezes (user_id, updated_at);
create index on public.user_daily_stats (user_id, updated_at);

-- ===== Row Level Security =====
-- Only signed-in users, only their own rows. No DELETE policies:
-- deletion is a soft delete; physical deletes run server-side.
alter table public.profiles enable row level security;
alter table public.user_bookmarks enable row level security;
alter table public.user_srs_cards enable row level security;
alter table public.user_lesson_progress enable row level security;
alter table public.user_settings enable row level security;
alter table public.user_review_logs enable row level security;
alter table public.user_exercise_attempts enable row level security;
alter table public.user_game_scores enable row level security;
alter table public.user_streak_freezes enable row level security;
alter table public.user_daily_stats enable row level security;

create policy "own select" on public.profiles for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "own update" on public.profiles for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

-- Mutable tables: select + insert + update
create policy "own select" on public.user_bookmarks for select to authenticated using ((select auth.uid()) = user_id);
create policy "own insert" on public.user_bookmarks for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "own update" on public.user_bookmarks for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

create policy "own select" on public.user_srs_cards for select to authenticated using ((select auth.uid()) = user_id);
create policy "own insert" on public.user_srs_cards for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "own update" on public.user_srs_cards for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

create policy "own select" on public.user_lesson_progress for select to authenticated using ((select auth.uid()) = user_id);
create policy "own insert" on public.user_lesson_progress for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "own update" on public.user_lesson_progress for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

create policy "own select" on public.user_settings for select to authenticated using ((select auth.uid()) = user_id);
create policy "own insert" on public.user_settings for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "own update" on public.user_settings for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

create policy "own select" on public.user_daily_stats for select to authenticated using ((select auth.uid()) = user_id);
create policy "own insert" on public.user_daily_stats for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "own update" on public.user_daily_stats for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

-- Append-only tables: select + insert only
create policy "own select" on public.user_review_logs for select to authenticated using ((select auth.uid()) = user_id);
create policy "own insert" on public.user_review_logs for insert to authenticated with check ((select auth.uid()) = user_id);

create policy "own select" on public.user_exercise_attempts for select to authenticated using ((select auth.uid()) = user_id);
create policy "own insert" on public.user_exercise_attempts for insert to authenticated with check ((select auth.uid()) = user_id);

create policy "own select" on public.user_game_scores for select to authenticated using ((select auth.uid()) = user_id);
create policy "own insert" on public.user_game_scores for insert to authenticated with check ((select auth.uid()) = user_id);

create policy "own select" on public.user_streak_freezes for select to authenticated using ((select auth.uid()) = user_id);
create policy "own insert" on public.user_streak_freezes for insert to authenticated with check ((select auth.uid()) = user_id);
