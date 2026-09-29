-- Manual rollback for 20260928120000_revoke_direct_family_table_dml.sql.
-- This restores only the table privileges removed by that migration, based on
-- the pre-deploy ACL snapshot. SELECT is not repeated because it is preserved.
-- Do not add this file to the forward migration chain.

begin;

grant insert, update, delete, truncate, references, trigger, maintain
on table public.families, public.family_members
to anon, authenticated, service_role;

commit;
