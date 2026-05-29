create or replace function public.child_belongs_to_family(
  target_child_id uuid,
  target_family_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  return exists (
    select 1
    from public.children c
    where c.id = target_child_id
      and c.family_id = target_family_id
  );
end;
$$;

create table if not exists public.missions (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  child_id uuid not null references public.children(id) on delete cascade,
  local_id text,
  title text not null check (char_length(trim(title)) > 0),
  description text,
  stars integer not null default 1 check (stars >= 1),
  requires_approval boolean not null default false,
  recurrence_type text not null default 'daily' check (
    recurrence_type in ('once', 'daily', 'weekdays', 'weekends', 'customDaysOfWeek')
  ),
  recurrence_days integer[],
  is_active boolean not null default true,
  archived_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists missions_family_id_idx
on public.missions (family_id);

create index if not exists missions_child_id_idx
on public.missions (child_id);

create index if not exists missions_created_by_idx
on public.missions (created_by);

create unique index if not exists missions_family_id_local_id_unique_idx
on public.missions (family_id, local_id)
where local_id is not null;

drop trigger if exists set_missions_updated_at on public.missions;
create trigger set_missions_updated_at
before update on public.missions
for each row
execute function public.set_updated_at();

alter table public.missions enable row level security;

drop policy if exists "missions_select_family_member" on public.missions;
create policy "missions_select_family_member"
on public.missions
for select
to authenticated
using (public.is_family_member(family_id));

drop policy if exists "missions_insert_family_manager" on public.missions;
create policy "missions_insert_family_manager"
on public.missions
for insert
to authenticated
with check (
  public.has_family_role(family_id, array['owner', 'responsible'])
  and public.child_belongs_to_family(child_id, family_id)
  and (created_by is null or created_by = auth.uid())
);

drop policy if exists "missions_update_family_manager" on public.missions;
create policy "missions_update_family_manager"
on public.missions
for update
to authenticated
using (public.has_family_role(family_id, array['owner', 'responsible']))
with check (
  public.has_family_role(family_id, array['owner', 'responsible'])
  and public.child_belongs_to_family(child_id, family_id)
);

revoke all on function public.child_belongs_to_family(uuid, uuid) from public;
grant execute on function public.child_belongs_to_family(uuid, uuid) to authenticated;
