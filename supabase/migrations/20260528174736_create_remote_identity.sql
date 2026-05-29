create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.is_family_member(target_family_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  return exists (
    select 1
    from public.family_members fm
    where fm.family_id = target_family_id
      and fm.user_id = auth.uid()
  );
end;
$$;

create or replace function public.has_family_role(
  target_family_id uuid,
  allowed_roles text[]
)
returns boolean
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  return exists (
    select 1
    from public.family_members fm
    where fm.family_id = target_family_id
      and fm.user_id = auth.uid()
      and fm.role = any(allowed_roles)
  );
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.families (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.family_members (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'owner' check (role in ('owner', 'responsible')),
  created_at timestamptz not null default now(),
  unique (family_id, user_id)
);

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

drop trigger if exists set_families_updated_at on public.families;
create trigger set_families_updated_at
before update on public.families
for each row
execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.families enable row level security;
alter table public.family_members enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles
for select
to authenticated
using (id = auth.uid());

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
on public.profiles
for insert
to authenticated
with check (id = auth.uid());

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles
for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

drop policy if exists "families_select_member" on public.families;
create policy "families_select_member"
on public.families
for select
to authenticated
using (public.is_family_member(id));

drop policy if exists "families_insert_authenticated" on public.families;
create policy "families_insert_authenticated"
on public.families
for insert
to authenticated
with check (created_by = auth.uid());

drop policy if exists "families_update_member_manager" on public.families;
create policy "families_update_member_manager"
on public.families
for update
to authenticated
using (public.has_family_role(id, array['owner', 'responsible']))
with check (public.has_family_role(id, array['owner', 'responsible']));

drop policy if exists "family_members_select_member" on public.family_members;
create policy "family_members_select_member"
on public.family_members
for select
to authenticated
using (public.is_family_member(family_id));

drop policy if exists "family_members_insert_self_or_owner" on public.family_members;
drop policy if exists "family_members_insert_owner" on public.family_members;
create policy "family_members_insert_owner"
on public.family_members
for insert
to authenticated
with check (public.has_family_role(family_id, array['owner']));

drop policy if exists "family_members_update_owner" on public.family_members;
create policy "family_members_update_owner"
on public.family_members
for update
to authenticated
using (public.has_family_role(family_id, array['owner']))
with check (public.has_family_role(family_id, array['owner']));

drop policy if exists "family_members_delete_owner" on public.family_members;
create policy "family_members_delete_owner"
on public.family_members
for delete
to authenticated
using (public.has_family_role(family_id, array['owner']));

create or replace function public.ensure_user_family()
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  current_user_id uuid := auth.uid();
  current_user_email text := auth.jwt() ->> 'email';
  existing_family_id uuid;
  existing_family_name text;
  existing_role text;
begin
  if current_user_id is null then
    raise exception 'not_authenticated';
  end if;

  insert into public.profiles (id, email, display_name)
  values (
    current_user_id,
    current_user_email,
    coalesce(nullif(split_part(coalesce(current_user_email, ''), '@', 1), ''), 'Responsável')
  )
  on conflict (id) do update
  set email = excluded.email,
      updated_at = now();

  select f.id, f.name, fm.role
  into existing_family_id, existing_family_name, existing_role
  from public.family_members fm
  join public.families f on f.id = fm.family_id
  where fm.user_id = current_user_id
  order by fm.created_at asc
  limit 1;

  if existing_family_id is null then
    insert into public.families (name, created_by)
    values ('Minha família', current_user_id)
    returning id, name into existing_family_id, existing_family_name;

    insert into public.family_members (family_id, user_id, role)
    values (existing_family_id, current_user_id, 'owner')
    on conflict (family_id, user_id) do update
      set role = excluded.role;

    existing_role := 'owner';
  end if;

  return jsonb_build_object(
    'family_id', existing_family_id,
    'family_name', existing_family_name,
    'role', existing_role,
    'user_id', current_user_id,
    'email', current_user_email
  );
end;
$$;

revoke all on function public.ensure_user_family() from public;
grant execute on function public.ensure_user_family() to authenticated;

revoke all on function public.is_family_member(uuid) from public;
grant execute on function public.is_family_member(uuid) to authenticated;

revoke all on function public.has_family_role(uuid, text[]) from public;
grant execute on function public.has_family_role(uuid, text[]) to authenticated;
