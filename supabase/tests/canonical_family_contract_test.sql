-- LOCAL DISPOSABLE DATABASE ONLY. Requires all versioned migrations.
begin;
do $$ begin
  if current_database() <> 'zeni_sprint2b_test' then
    raise exception 'test_database_required';
  end if;
end $$;
insert into auth.users(id) values
  ('00000000-0000-0000-0000-000000000001'),
  ('00000000-0000-0000-0000-000000000002'),
  ('00000000-0000-0000-0000-000000000003');
set local request.jwt.claim.role = 'authenticated';
set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';

do $$
declare a jsonb; b jsonb; renamed jsonb; before_count bigint;
begin
  select count(*) into before_count from public.profiles;
  a := public.resolve_current_family();
  assert a->>'status' = 'not_found', 'resolve_not_found';
  assert (select count(*) from public.families) = 0, 'resolve_created_family';
  assert (select count(*) from public.family_members) = 0, 'resolve_created_member';
  assert (select count(*) from public.profiles) = before_count, 'resolve_created_profile';
  a := public.create_initial_family();
  assert a->>'status' = 'created', 'create_initial';
  b := public.create_initial_family();
  assert b->>'status' = 'already_exists', 'retry';
  assert a->>'family_id' = b->>'family_id', 'retry_identity';
  assert (select count(*) from public.families) = 1, 'duplicate_family';
  assert public.resolve_current_family()->>'status' = 'found', 'resolve_found';
  assert (select count(*) from public.family_members) = 1, 'duplicate_member';
  renamed := public.rename_current_family('  Família   Silva  ');
  assert renamed->>'status' = 'updated', 'rename_not_updated';
  assert renamed->>'family_id' = a->>'family_id', 'rename_family_changed';
  assert renamed->>'membership_id' = a->>'membership_id', 'rename_membership_changed';
  assert renamed->>'family_name' = 'Família Silva', 'rename_not_normalized';
  assert renamed->>'role' = 'owner', 'rename_role_changed';
  assert renamed->>'updated_at' is not null, 'rename_missing_timestamp';
  assert (renamed->>'updated_at')::timestamptz = (
    select updated_at from public.families where id = (a->>'family_id')::uuid
  ), 'rename_timestamp_mismatch';
  assert (select name from public.families where id = (a->>'family_id')::uuid)
    = 'Família Silva', 'rename_not_persisted';
  assert public.rename_current_family('')->>'status' = 'invalid_name',
    'empty_name_accepted';
  assert public.rename_current_family('   ')->>'status' = 'invalid_name',
    'blank_name_accepted';
  assert public.rename_current_family(repeat('a', 81))->>'status' = 'invalid_name',
    'long_name_accepted';
  assert public.rename_current_family(E'Família\nSilva')->>'status' = 'invalid_name',
    'control_character_accepted';
  assert (select name from public.families where id = (a->>'family_id')::uuid)
    = 'Família Silva', 'invalid_name_changed_family';
end $$;

-- Resolve a valid user as authenticated and verify the full profile is unchanged.
create temporary table profile_before as select * from public.profiles;
set local role authenticated;
do $$ begin
  assert public.resolve_current_family()->>'status' = 'found', 'authenticated_found';
  assert public.create_initial_family()->>'status' = 'already_exists', 'authenticated_retry';
end $$;
reset role;
do $$ begin
  assert not exists (
    (select * from public.profiles except select * from profile_before)
    union all (select * from profile_before except select * from public.profiles)
  ), 'profile_modified_on_resolve_or_retry';
end $$;

set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000002';
do $$ declare a jsonb; begin
  assert public.resolve_current_family()->>'status' = 'not_found', 'B_leaks_A';
  assert public.rename_current_family('Outra família')->>'status' = 'not_found',
    'rename_created_or_adopted_family';
  assert (select count(*) from public.families) = 1, 'rename_not_found_created_family';
  assert (select name from public.families limit 1) = 'Família Silva',
    'rename_not_found_changed_family';
  a := public.create_initial_family();
  assert a->>'status' = 'created', 'create_B';
  assert a->>'family_id' <> (select family_id::text from public.family_members
    where user_id = '00000000-0000-0000-0000-000000000001'), 'B_family_is_A';
end $$;

-- Existing responsible resolves and retries without promotion or new family.
insert into public.family_members(family_id, user_id, role)
select family_id, '00000000-0000-0000-0000-000000000003', 'responsible'
from public.family_members where user_id = '00000000-0000-0000-0000-000000000001';
set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000003';
do $$ declare a jsonb; begin
  a := public.create_initial_family();
  assert a->>'status' = 'already_exists' and a->>'role' = 'responsible', 'responsible_promoted';
  assert public.rename_current_family('Nome proibido')->>'status' = 'forbidden',
    'responsible_renamed_family';
  assert (select name from public.families where id = (a->>'family_id')::uuid)
    = a->>'family_name', 'forbidden_changed_family';
end $$;

-- No UID and role ACLs. Owner invocation cannot bypass explicit auth checks.
set local request.jwt.claim.sub = '';
do $$ begin
  begin
    perform public.create_initial_family();
    raise exception 'unauthenticated_create_allowed';
  exception when sqlstate '28000' then null; end;
  begin
    perform public.resolve_current_family();
    raise exception 'unauthenticated_resolve_allowed';
  exception when sqlstate '28000' then null; end;
  assert not has_function_privilege('anon', 'public.create_initial_family()', 'EXECUTE');
  assert not has_function_privilege('service_role', 'public.create_initial_family()', 'EXECUTE');
  assert not has_function_privilege('anon', 'public.resolve_current_family()', 'EXECUTE');
  assert has_function_privilege('authenticated', 'public.resolve_current_family()', 'EXECUTE');
  assert not has_function_privilege('anon', 'public.rename_current_family(text)', 'EXECUTE');
  assert not has_function_privilege('service_role', 'public.rename_current_family(text)', 'EXECUTE');
  assert has_function_privilege('authenticated', 'public.rename_current_family(text)', 'EXECUTE');
end $$;

-- Missing owner blocks both functions without auto-heal.
set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000002';
update public.family_members set role = 'responsible'
where user_id = '00000000-0000-0000-0000-000000000002';
do $$ begin
  assert public.resolve_current_family()->>'status' = 'inconsistent', 'missing_owner_resolve';
  assert public.create_initial_family()->>'status' = 'inconsistent', 'missing_owner_create';
  assert public.rename_current_family('Não alterar')->>'status' = 'inconsistent',
    'inconsistent_rename';
  assert (select count(*) from public.families) = 2, 'inconsistent_created';
  assert not exists (
    select 1 from public.families where name = 'Não alterar'
  ), 'inconsistent_changed_family';
end $$;

-- Orphan family is not silently adopted or supplemented.
delete from public.family_members
where user_id = '00000000-0000-0000-0000-000000000002';
do $$ begin
  assert public.resolve_current_family()->>'status' = 'not_found', 'orphan_resolution';
  assert public.create_initial_family()->>'reason' = 'created_family_without_membership', 'orphan_adopted';
  assert (select count(*) from public.families) = 2, 'orphan_created_second';
end $$;
-- Restore test fixture for ambiguity scenario below.
insert into public.family_members(family_id, user_id, role)
select id, '00000000-0000-0000-0000-000000000002', 'owner'
from public.families where created_by = '00000000-0000-0000-0000-000000000002';

-- UNIQUE protects a non-cooperating writer and rolls back its provisional family.
do $$ declare provisional uuid; begin
  begin
    insert into public.families(name) values ('must roll back') returning id into provisional;
    insert into public.family_members(family_id,user_id,role)
    values(provisional, '00000000-0000-0000-0000-000000000001','owner');
    raise exception 'unique_user_not_enforced';
  exception when unique_violation then null; end;
  assert not exists(select 1 from public.families where id = provisional), 'orphan_after_conflict';
end $$;

-- Artificial drift: constraint removal is test-only and rolled back below.
alter table public.family_members drop constraint family_members_one_family_per_user_v1;
insert into public.family_members(family_id,user_id,role)
select family_id, '00000000-0000-0000-0000-000000000001', 'owner'
from public.family_members where user_id = '00000000-0000-0000-0000-000000000002';
set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
do $$ begin
  assert public.resolve_current_family()->>'status' = 'ambiguous', 'ambiguous_resolve';
  assert public.create_initial_family()->>'status' = 'ambiguous', 'ambiguous_create';
  assert public.rename_current_family('Não escolher')->>'status' = 'ambiguous',
    'ambiguous_rename_selected_family';
  assert public.resolve_current_family()->>'family_id' is null, 'ambiguous_leaked_family';
  assert not exists (
    select 1 from public.families where name = 'Não escolher'
  ), 'ambiguous_changed_family';
end $$;
rollback;

-- Read-only transaction and authenticated execution, not only owner execution.
begin read only;
set local request.jwt.claim.role = 'authenticated';
set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
set local role authenticated;
select public.resolve_current_family();
rollback;
