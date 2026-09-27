-- LOCAL session B: run while A is in pg_sleep. Must actually overlap.
\set ON_ERROR_STOP on
do $$ begin
  if current_database() <> 'zeni_sprint2b_test' then raise exception 'test_database_required'; end if;
  assert exists (select 1 from pg_stat_activity
    where application_name = 'zeni_2b_concurrency_a' and wait_event = 'PgSleep'),
    'A_not_holding_transaction_repeat_test';
end $$;
begin;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000010';
set local request.jwt.claim.role = 'authenticated';
set local role authenticated;
do $$ declare r jsonb; begin
  r := public.create_initial_family();
  assert r->>'status' = 'already_exists', 'B_created_second_family';
  assert r->>'family_id' = public.resolve_current_family()->>'family_id', 'B_identity_mismatch';
end $$;
commit;
do $$ begin
  assert (select count(*) from public.families
    where created_by = '00000000-0000-0000-0000-000000000010') = 1, 'two_families';
  assert (select count(*) from public.family_members
    where user_id = '00000000-0000-0000-0000-000000000010') = 1, 'two_memberships';
end $$;
begin read only;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000010';
set local request.jwt.claim.role = 'authenticated';
set local role authenticated;
do $$ begin
  assert public.resolve_current_family()->>'status' = 'found', 'read_only_found';
end $$;
rollback;
