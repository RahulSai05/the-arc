-- The Arc: per-user cloud storage
create table if not exists public.arc_data (
  user_id uuid primary key references auth.users(id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.arc_data enable row level security;

-- Users can only read their own Arc data.
drop policy if exists "Users can read their own arc data" on public.arc_data;
create policy "Users can read their own arc data"
on public.arc_data
for select
to authenticated
using (auth.uid() = user_id);

-- Users can only insert their own Arc data.
drop policy if exists "Users can insert their own arc data" on public.arc_data;
create policy "Users can insert their own arc data"
on public.arc_data
for insert
to authenticated
with check (auth.uid() = user_id);

-- Users can only update their own Arc data.
drop policy if exists "Users can update their own arc data" on public.arc_data;
create policy "Users can update their own arc data"
on public.arc_data
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Keep updated_at correct whenever a row is updated.
create or replace function public.set_arc_data_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists arc_data_set_updated_at on public.arc_data;
create trigger arc_data_set_updated_at
before update on public.arc_data
for each row
execute function public.set_arc_data_updated_at();
