create or replace function public.mission_belongs_to_child(
  target_mission_id uuid,
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
    from public.missions m
    where m.id = target_mission_id
      and m.child_id = target_child_id
      and m.family_id = target_family_id
  );
end;
$$;

create table if not exists public.mission_logs (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  child_id uuid not null references public.children(id) on delete cascade,
  mission_id uuid not null references public.missions(id) on delete cascade,
  local_id text,
  status text not null check (
    status in ('pending', 'awaitingApproval', 'approved', 'rejected', 'skipped')
  ),
  scheduled_date date,
  stars_awarded integer not null default 0 check (stars_awarded >= 0),
  submitted_at timestamptz,
  completed_at timestamptz,
  approved_at timestamptz,
  rejected_at timestamptz,
  note text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists mission_logs_family_id_idx
on public.mission_logs (family_id);

create index if not exists mission_logs_child_id_idx
on public.mission_logs (child_id);

create index if not exists mission_logs_mission_id_idx
on public.mission_logs (mission_id);

create index if not exists mission_logs_created_by_idx
on public.mission_logs (created_by);

create unique index if not exists mission_logs_family_id_local_id_unique_idx
on public.mission_logs (family_id, local_id)
where local_id is not null;

drop trigger if exists set_mission_logs_updated_at on public.mission_logs;
create trigger set_mission_logs_updated_at
before update on public.mission_logs
for each row
execute function public.set_updated_at();

alter table public.mission_logs enable row level security;

drop policy if exists "mission_logs_select_family_member" on public.mission_logs;
create policy "mission_logs_select_family_member"
on public.mission_logs
for select
to authenticated
using (public.is_family_member(family_id));

drop policy if exists "mission_logs_insert_family_manager" on public.mission_logs;
create policy "mission_logs_insert_family_manager"
on public.mission_logs
for insert
to authenticated
with check (
  public.has_family_role(family_id, array['owner', 'responsible'])
  and public.child_belongs_to_family(child_id, family_id)
  and public.mission_belongs_to_child(mission_id, child_id, family_id)
  and (created_by is null or created_by = auth.uid())
);

drop policy if exists "mission_logs_update_family_manager" on public.mission_logs;
create policy "mission_logs_update_family_manager"
on public.mission_logs
for update
to authenticated
using (public.has_family_role(family_id, array['owner', 'responsible']))
with check (
  public.has_family_role(family_id, array['owner', 'responsible'])
  and public.child_belongs_to_family(child_id, family_id)
  and public.mission_belongs_to_child(mission_id, child_id, family_id)
);

revoke all on function public.mission_belongs_to_child(uuid, uuid, uuid) from public;
grant execute on function public.mission_belongs_to_child(uuid, uuid, uuid) to authenticated;
