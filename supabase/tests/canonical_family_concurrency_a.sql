-- LOCAL disposable zeni_sprint2b_test only; session A, after contract tests.
\set ON_ERROR_STOP on
do $$ begin
  if current_database() <> 'zeni_sprint2b_test' then raise exception 'test_database_required'; end if;
end $$;
insert into auth.users(id) values ('00000000-0000-0000-0000-000000000010');
begin;
set local application_name = 'zeni_2b_concurrency_a';
set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000010';
set local request.jwt.claim.role = 'authenticated';
set local role authenticated;
do $$ begin
  assert public.create_initial_family()->>'status' = 'created', 'A_not_created';
end $$;
-- Keep uncommitted family + advisory lock while B starts.
select pg_sleep(15);
commit;
