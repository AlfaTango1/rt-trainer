-- Pilot Helper: one username = one account.
-- Run once in Supabase → SQL Editor → New query → Run. Safe to run again.
-- If some usernames are already taken twice, nothing is changed and the
-- duplicates are listed in the error message so they can be fixed first.

do $$
declare dups text;
begin
  select string_agg(format('%s (%s accounts)', u, n), ', ')
    into dups
    from (select lower(username) u, count(*) n
            from public.profiles
           where username is not null
           group by lower(username)
          having count(*) > 1) d;
  if dups is not null then
    raise exception 'Duplicate usernames, rename them first: %', dups;
  end if;
end $$;

-- the guarantee: case-insensitive unique username ("Berkut" and "berkut" are the same)
create unique index if not exists profiles_username_unique
  on public.profiles (lower(username));

-- same rule as the app: a–z, 0–9, _ ; 3–20 characters (existing rows are not re-checked)
do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'profiles_username_format') then
    alter table public.profiles
      add constraint profiles_username_format
      check (username ~ '^[a-z0-9_]{3,20}$') not valid;
  end if;
end $$;

-- lets the sign-up form say "username is taken" before creating the account
create or replace function public.username_available(p_username text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select not exists (select 1 from public.profiles where lower(username) = lower(trim(p_username)));
$$;

revoke all on function public.username_available(text) from public;
grant execute on function public.username_available(text) to anon, authenticated;
