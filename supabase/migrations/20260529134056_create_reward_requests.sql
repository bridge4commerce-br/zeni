create or replace function public.reward_available_to_child(
  target_reward_id uuid,
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
    from public.rewards r
    where r.id = target_reward_id
      and r.family_id = target_family_id
      and (r.child_id is null or r.child_id = target_child_id)
  );
end;
$$;

create table if not exists public.reward_requests (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  child_id uuid not null references public.children(id) on delete cascade,
  reward_id uuid not null references public.rewards(id) on delete cascade,
  local_id text,
  status text not null check (
    status in ('pending', 'approved', 'rejected', 'delivered', 'cancelled')
  ),
  stars_spent integer not null default 0 check (stars_spent >= 0),
  requested_at timestamptz,
  approved_at timestamptz,
  rejected_at timestamptz,
  cancelled_at timestamptz,
  note text,
  rejection_reason text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists reward_requests_family_id_idx
on public.reward_requests (family_id);

create index if not exists reward_requests_child_id_idx
on public.reward_requests (child_id);

create index if not exists reward_requests_reward_id_idx
on public.reward_requests (reward_id);

create index if not exists reward_requests_created_by_idx
on public.reward_requests (created_by);

create unique index if not exists reward_requests_family_id_local_id_unique_idx
on public.reward_requests (family_id, local_id)
where local_id is not null;

drop trigger if exists set_reward_requests_updated_at on public.reward_requests;
create trigger set_reward_requests_updated_at
before update on public.reward_requests
for each row
execute function public.set_updated_at();

alter table public.reward_requests enable row level security;

drop policy if exists "reward_requests_select_family_member" on public.reward_requests;
create policy "reward_requests_select_family_member"
on public.reward_requests
for select
to authenticated
using (public.is_family_member(family_id));

drop policy if exists "reward_requests_insert_family_manager" on public.reward_requests;
create policy "reward_requests_insert_family_manager"
on public.reward_requests
for insert
to authenticated
with check (
  public.has_family_role(family_id, array['owner', 'responsible'])
  and public.child_belongs_to_family(child_id, family_id)
  and public.reward_available_to_child(reward_id, child_id, family_id)
  and (created_by is null or created_by = auth.uid())
);

drop policy if exists "reward_requests_update_family_manager" on public.reward_requests;
create policy "reward_requests_update_family_manager"
on public.reward_requests
for update
to authenticated
using (public.has_family_role(family_id, array['owner', 'responsible']))
with check (
  public.has_family_role(family_id, array['owner', 'responsible'])
  and public.child_belongs_to_family(child_id, family_id)
  and public.reward_available_to_child(reward_id, child_id, family_id)
);

revoke all on function public.reward_available_to_child(uuid, uuid, uuid) from public;
grant execute on function public.reward_available_to_child(uuid, uuid, uuid) to authenticated;
