create table if not exists public.rewards (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  child_id uuid references public.children(id) on delete cascade,
  local_id text,
  title text not null check (char_length(trim(title)) > 0),
  description text,
  cost integer not null default 1 check (cost >= 1),
  image_key text,
  is_active boolean not null default true,
  archived_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists rewards_family_id_idx
on public.rewards (family_id);

create index if not exists rewards_child_id_idx
on public.rewards (child_id);

create index if not exists rewards_created_by_idx
on public.rewards (created_by);

create unique index if not exists rewards_family_id_local_id_unique_idx
on public.rewards (family_id, local_id)
where local_id is not null;

drop trigger if exists set_rewards_updated_at on public.rewards;
create trigger set_rewards_updated_at
before update on public.rewards
for each row
execute function public.set_updated_at();

alter table public.rewards enable row level security;

drop policy if exists "rewards_select_family_member" on public.rewards;
create policy "rewards_select_family_member"
on public.rewards
for select
to authenticated
using (public.is_family_member(family_id));

drop policy if exists "rewards_insert_family_manager" on public.rewards;
create policy "rewards_insert_family_manager"
on public.rewards
for insert
to authenticated
with check (
  public.has_family_role(family_id, array['owner', 'responsible'])
  and (child_id is null or public.child_belongs_to_family(child_id, family_id))
  and (created_by is null or created_by = auth.uid())
);

drop policy if exists "rewards_update_family_manager" on public.rewards;
create policy "rewards_update_family_manager"
on public.rewards
for update
to authenticated
using (public.has_family_role(family_id, array['owner', 'responsible']))
with check (
  public.has_family_role(family_id, array['owner', 'responsible'])
  and (child_id is null or public.child_belongs_to_family(child_id, family_id))
);
