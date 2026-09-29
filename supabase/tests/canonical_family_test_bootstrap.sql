-- LOCAL DISPOSABLE DATABASE ONLY. Never run this file in the Supabase SQL Editor.
-- Minimal Auth shim: this tests PostgreSQL behavior, not JWT verification/PostgREST.
do $$ begin
  if current_database() <> 'zeni_sprint2b_test' then
    raise exception 'test_database_required';
  end if;
end $$;
create role anon nologin;
create role authenticated nologin;
create role service_role nologin bypassrls;
-- Mirror the broad Supabase table defaults observed before the ACL cutover so
-- the forward migration must actually remove the privileges under test.
alter default privileges in schema public
grant all on tables to anon, authenticated, service_role;
create schema auth;
create table auth.users (id uuid primary key, email text);
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;
create function auth.role() returns text language sql stable as $$
  select nullif(current_setting('request.jwt.claim.role', true), '')
$$;
create function auth.jwt() returns jsonb language sql stable as $$
  select jsonb_build_object('sub', auth.uid(), 'role', auth.role())
$$;
grant usage on schema auth to authenticated;
