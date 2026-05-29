create table if not exists public.children (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  local_id text,
  name text not null,
  avatar_key text,
  birth_date date,
  archived_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists children_family_id_idx
on public.children (family_id);

create index if not exists children_created_by_idx
on public.children (created_by);

create unique index if not exists children_family_id_local_id_unique_idx
on public.children (family_id, local_id)
where local_id is not null;

drop trigger if exists set_children_updated_at on public.children;
create trigger set_children_updated_at
before update on public.children
for each row
execute function public.set_updated_at();

alter table public.children enable row level security;

drop policy if exists "children_select_family_member" on public.children;
create policy "children_select_family_member"
on public.children
for select
to authenticated
using (public.is_family_member(family_id));

drop policy if exists "children_insert_family_manager" on public.children;
create policy "children_insert_family_manager"
on public.children
for insert
to authenticated
with check (
  public.has_family_role(family_id, array['owner', 'responsible'])
  and (created_by is null or created_by = auth.uid())
);

drop policy if exists "children_update_family_manager" on public.children;
create policy "children_update_family_manager"
on public.children
for update
to authenticated
using (public.has_family_role(family_id, array['owner', 'responsible']))
with check (
  public.has_family_role(family_id, array['owner', 'responsible'])
);
