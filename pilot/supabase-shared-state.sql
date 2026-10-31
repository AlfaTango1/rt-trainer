-- Pilot Helper: shared pilot profiles.
-- Run once in Supabase → SQL Editor → New query → Run.
-- The owner's app keeps one row here (their pilots, checks and flight time)
-- while at least one person has accepted access; those people can read it.

create table if not exists public.shared_state (
  owner_id   uuid primary key references auth.users(id) on delete cascade,
  data       jsonb not null,
  updated_at timestamptz not null default now(),
  constraint shared_state_size check (pg_column_size(data) < 500000)
);

alter table public.shared_state enable row level security;

drop policy if exists "shared_state owner all" on public.shared_state;
create policy "shared_state owner all" on public.shared_state
  for all to authenticated
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

drop policy if exists "shared_state grantee read" on public.shared_state;
create policy "shared_state grantee read" on public.shared_state
  for select to authenticated
  using (exists (
    select 1 from public.access_grants g
    where g.owner_id = shared_state.owner_id
      and g.grantee_id = auth.uid()
      and g.status = 'accepted'
  ));
