-- Pilot Helper — full Supabase schema.
-- Applied to project cblwqdejctpowcczkpic (AlfaTango1's Org) as migration
-- 20261031203832 "pilot_initial_schema". Kept here to rebuild the database
-- on a fresh project: SQL Editor → New query → paste → Run (once).
--
-- Auth settings that are not SQL (Dashboard → Authentication):
--   Sign In / Providers → Email → "Confirm email" off
--   URL Configuration → Site URL: https://alfatango1.github.io/rt-trainer/pilot/

-- ---------- profiles: one row per account, username is unique (case-insensitive) ----------
create table public.profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  username   text not null,
  created_at timestamptz not null default now(),
  constraint profiles_username_format check (username ~ '^[a-z0-9_]{3,20}$')
);
create unique index profiles_username_unique on public.profiles (lower(username));
alter table public.profiles enable row level security;

-- profile row is created from the username given at sign-up; a missing or taken username fails the sign-up
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, username)
  values (new.id, lower(trim(new.raw_user_meta_data ->> 'username')));
  return new;
end;
$$;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- access_grants: grantee asks, owner accepts / revokes ----------
create table public.access_grants (
  owner_id   uuid not null references public.profiles(id) on delete cascade,
  grantee_id uuid not null references public.profiles(id) on delete cascade,
  status     text not null default 'pending' check (status in ('pending', 'accepted', 'revoked')),
  created_at timestamptz not null default now(),
  primary key (owner_id, grantee_id),
  check (owner_id <> grantee_id)
);
create index access_grants_grantee_idx on public.access_grants (grantee_id);
alter table public.access_grants enable row level security;

create policy "grants: both sides read" on public.access_grants
  for select to authenticated
  using ((select auth.uid()) in (owner_id, grantee_id));
create policy "grants: owner changes status" on public.access_grants
  for update to authenticated
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);
create policy "grants: either side removes" on public.access_grants
  for delete to authenticated
  using ((select auth.uid()) in (owner_id, grantee_id));
-- only the status may be changed from the app; new grants come from request_access()
revoke insert, update on public.access_grants from anon, authenticated;
grant update (status) on public.access_grants to authenticated;

-- profiles are visible to yourself and to people you share a grant with
create policy "profiles: self and connections" on public.profiles
  for select to authenticated
  using (
    id = (select auth.uid())
    or exists (
      select 1 from public.access_grants g
      where (g.owner_id = profiles.id and g.grantee_id = (select auth.uid()))
         or (g.grantee_id = profiles.id and g.owner_id = (select auth.uid()))
    )
  );

-- ---------- user_data: entries a grantee sends into the owner's inbox ----------
create table public.user_data (
  id         bigint generated always as identity primary key,
  owner_id   uuid not null references public.profiles(id) on delete cascade,
  added_by   uuid not null references public.profiles(id) on delete cascade,
  payload    jsonb not null,
  created_at timestamptz not null default now(),
  constraint user_data_payload_size check (pg_column_size(payload) < 4000)
);
create index user_data_owner_idx on public.user_data (owner_id);
create index user_data_added_by_idx on public.user_data (added_by);
alter table public.user_data enable row level security;

create policy "user_data: sender and owner read" on public.user_data
  for select to authenticated
  using ((select auth.uid()) in (owner_id, added_by));
create policy "user_data: accepted grantee sends" on public.user_data
  for insert to authenticated
  with check (
    added_by = (select auth.uid())
    and exists (
      select 1 from public.access_grants g
      where g.owner_id = user_data.owner_id
        and g.grantee_id = (select auth.uid())
        and g.status = 'accepted'
    )
  );
create policy "user_data: owner removes" on public.user_data
  for delete to authenticated
  using (owner_id = (select auth.uid()));
-- "Reset all data" in the app also removes entries the user sent to others (migration user_data_sender_delete)
create policy "user_data: sender removes" on public.user_data
  for delete to authenticated
  using (added_by = (select auth.uid()));

-- ---------- shared_state: owner's pilots, readable by accepted grantees ----------
create table public.shared_state (
  owner_id   uuid primary key references public.profiles(id) on delete cascade,
  data       jsonb not null,
  updated_at timestamptz not null default now(),
  constraint shared_state_size check (pg_column_size(data) < 500000)
);
alter table public.shared_state enable row level security;

create policy "shared_state: owner all" on public.shared_state
  for all to authenticated
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);
create policy "shared_state: accepted grantee reads" on public.shared_state
  for select to authenticated
  using (exists (
    select 1 from public.access_grants g
    where g.owner_id = shared_state.owner_id
      and g.grantee_id = (select auth.uid())
      and g.status = 'accepted'
  ));

-- ---------- functions called by the app ----------
-- ask for access by username; returns 'ok', 'not_found' or 'self' so the app can tell a typo apart
-- (username_available() already answers whether a name is taken, so this reveals nothing new)
create function public.request_access(p_username text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  me uuid := auth.uid();
  target uuid;
begin
  if me is null then
    raise exception 'not signed in';
  end if;
  if (select count(*) from public.access_grants where grantee_id = me and status = 'pending') >= 10 then
    raise exception 'too many unanswered requests';
  end if;
  select id into target from public.profiles where lower(username) = lower(trim(p_username));
  if target is null then
    return 'not_found';
  end if;
  if target = me then
    return 'self';
  end if;
  insert into public.access_grants (owner_id, grantee_id)
  values (target, me)
  on conflict (owner_id, grantee_id) do update
    set status = 'pending'
    where public.access_grants.status = 'revoked';
  return 'ok';
end;
$$;
revoke all on function public.request_access(text) from public, anon;
grant execute on function public.request_access(text) to authenticated;

-- lets the sign-up form say "username is taken" before creating the account
create function public.username_available(p_username text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select not exists (select 1 from public.profiles where lower(username) = lower(trim(p_username)));
$$;
revoke all on function public.username_available(text) from public;
grant execute on function public.username_available(text) to anon, authenticated;

revoke all on function public.handle_new_user() from public, anon, authenticated;

-- ---------- backups: private cloud copy of each account's own data (migration "backups") ----------
create table public.backups (
  owner_id   uuid primary key references public.profiles(id) on delete cascade,
  data       jsonb not null,
  updated_at timestamptz not null default now(),
  constraint backups_size check (pg_column_size(data) < 1000000)
);
alter table public.backups enable row level security;
create policy "backups: owner only" on public.backups
  for all to authenticated
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);
