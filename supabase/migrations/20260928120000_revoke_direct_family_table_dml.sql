-- Sprint 2B.3D: close direct family writes after the RPC cutover.
-- SELECT, RLS policies, function ACLs, default privileges, and postgres are
-- intentionally unchanged. SECURITY DEFINER RPCs remain owned by postgres.

begin;

revoke insert, update, delete, truncate, references, trigger, maintain
on table public.families, public.family_members
from anon, authenticated, service_role;

commit;
