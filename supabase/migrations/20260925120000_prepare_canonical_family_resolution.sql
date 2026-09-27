-- Sprint 2B.1: additive canonical family resolution preparation.
-- Apply only after read-only diagnostics confirm the V1 preconditions.
-- Keep legacy ensure_user_family and existing table ACLs until client cutover.

begin;

lock table public.profiles, public.families, public.family_members
  in share row exclusive mode;

do $$
begin
  if exists (
    select 1 from public.family_members group by user_id having count(*) > 1
  ) then
    raise exception 'canonical_family_precondition: multiple_memberships';
  end if;
  if exists (
    select 1 from public.family_members fm
    left join public.families f on f.id = fm.family_id
    left join auth.users u on u.id = fm.user_id
    where f.id is null or u.id is null or fm.role is null
       or fm.role not in ('owner', 'responsible')
  ) then
    raise exception 'canonical_family_precondition: invalid_membership';
  end if;
  if exists (
    select 1 from public.families f
    where not exists (
      select 1 from public.family_members fm
      where fm.family_id = f.id and fm.role = 'owner'
    )
  ) then
    raise exception 'canonical_family_precondition: family_without_owner';
  end if;
  if exists (
    select 1 from public.profiles p
    left join auth.users u on u.id = p.id where u.id is null
  ) then
    raise exception 'canonical_family_precondition: orphan_profile';
  end if;
end;
$$;

-- Intentional V1 restriction, removable with an explicit multi-family contract.
-- Multiple users (including multiple owners) may still belong to one family.
alter table public.family_members
  add constraint family_members_one_family_per_user_v1 unique (user_id);

create function public.resolve_current_family()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  memberships jsonb;
  member jsonb;
  result jsonb;
begin
  if caller_id is null or auth.role() is distinct from 'authenticated' then
    raise exception using errcode = '28000', message = 'not_authenticated';
  end if;

  result := pg_catalog.jsonb_build_object(
    'contract_version', 1, 'status', 'not_found', 'reason', null,
    'user_id', caller_id, 'family_id', null, 'membership_id', null,
    'family_name', null, 'role', null
  );

  if not exists (select 1 from auth.users where id = caller_id) then
    return result || pg_catalog.jsonb_build_object(
      'status', 'inconsistent', 'reason', 'auth_user_missing'
    );
  end if;

  -- Count raw memberships, including broken references; never pick the first.
  -- STABLE uses one caller snapshot and cannot perform database writes.
  select coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
    'membership_id', fm.id, 'family_id', f.id,
    'family_name', f.name, 'role', fm.role,
    'has_owner', exists (
      select 1 from public.family_members owner_member
      join auth.users owner_user on owner_user.id = owner_member.user_id
      where owner_member.family_id = fm.family_id and owner_member.role = 'owner'
    )
  )), '[]'::jsonb)
  into memberships
  from public.family_members fm
  left join public.families f on f.id = fm.family_id
  where fm.user_id = caller_id;

  if pg_catalog.jsonb_array_length(memberships) > 1 then
    return result || pg_catalog.jsonb_build_object(
      'status', 'ambiguous', 'reason', 'multiple_memberships'
    );
  end if;
  if pg_catalog.jsonb_array_length(memberships) = 0 then
    return result;
  end if;

  member := memberships -> 0;
  if member ->> 'family_id' is null
     or member ->> 'role' is null
     or member ->> 'role' not in ('owner', 'responsible')
     or not (member ->> 'has_owner')::boolean then
    return result || pg_catalog.jsonb_build_object(
      'status', 'inconsistent', 'reason', 'invalid_membership_or_owner'
    );
  end if;

  return result || (member - 'has_owner')
    || pg_catalog.jsonb_build_object('status', 'found');
end;
$$;

create function public.create_initial_family()
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  caller_email text := auth.jwt() ->> 'email';
  resolution jsonb;
  new_family_id uuid;
begin
  if caller_id is null or auth.role() is distinct from 'authenticated' then
    raise exception using errcode = '28000', message = 'not_authenticated';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(
    'zeni:create_initial_family:v1:' || caller_id::text, 0
  ));
  -- A separate statement AFTER waiting: fresh snapshot under READ COMMITTED.
  resolution := public.resolve_current_family();
  if resolution ->> 'status' = 'found' then
    return resolution || pg_catalog.jsonb_build_object('status', 'already_exists');
  end if;
  if resolution ->> 'status' <> 'not_found' then
    return resolution;
  end if;
  if exists (select 1 from public.families where created_by = caller_id) then
    return resolution || pg_catalog.jsonb_build_object(
      'status', 'inconsistent', 'reason', 'created_family_without_membership'
    );
  end if;

  insert into public.profiles (id, email, display_name)
  values (caller_id, caller_email, coalesce(
    nullif(pg_catalog.split_part(coalesce(caller_email, ''), '@', 1), ''),
    'Responsável'
  )) on conflict (id) do nothing;

  insert into public.families (name, created_by)
  values ('Minha família', caller_id) returning id into new_family_id;
  insert into public.family_members (family_id, user_id, role)
  values (new_family_id, caller_id, 'owner');

  -- Any error, including UNIQUE(user_id) against a legacy/non-cooperating
  -- writer, aborts the ENTIRE call. Never swallow a conflict leaving an orphan.
  resolution := public.resolve_current_family();
  if resolution ->> 'status' <> 'found'
     or (resolution ->> 'family_id')::uuid is distinct from new_family_id then
    raise exception 'canonical_family_creation_inconsistent';
  end if;
  return resolution || pg_catalog.jsonb_build_object('status', 'created');
end;
$$;

-- Pin a trusted owner; no privilege-bearing client inputs or dynamic SQL.
alter function public.resolve_current_family() owner to postgres;
alter function public.create_initial_family() owner to postgres;
revoke all on function public.resolve_current_family() from public, anon, authenticated, service_role;
revoke all on function public.create_initial_family() from public, anon, authenticated, service_role;
grant execute on function public.resolve_current_family() to authenticated;
grant execute on function public.create_initial_family() to authenticated;

-- Deliberately deferred to client-compatible cutover:
-- * remove login's legacy ensure call and migrate family-name UPDATE to an RPC;
-- * revoke direct family/membership DML and remove its write policies;
-- * revoke/drop ensure_user_family after all callers have migrated.
-- This preparation does NOT claim to eliminate implicit creation or direct DML.

commit;
