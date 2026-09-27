-- EXECUÇÃO MANUAL NO SQL EDITOR. Somente leitura, sem chamada de RPC.
-- Este arquivo NÃO é uma migration. Nenhum resultado autoriza saneamento automático.
begin transaction isolation level repeatable read read only;

-- 1/2/3: inventário de todos os usuários, sem email ou outros dados pessoais.
select u.id as user_id, count(fm.id) as memberships,
       case count(fm.id) when 0 then 'zero' when 1 then 'one' else 'multiple' end as state,
       array_agg(fm.family_id) filter (where fm.id is not null) as family_ids
from auth.users u left join public.family_members fm on fm.user_id = u.id
group by u.id order by memberships desc, u.id;

-- 4/5/6: famílias vazias, sem owner e com vários owners.
-- Vários owners são diagnóstico, não violação automática do contrato.
select f.id as family_id, count(fm.id) as members,
       count(fm.id) filter (where fm.role = 'owner') as owners,
       count(fm.id) filter (where fm.role = 'owner' and u.id is not null) as valid_owners
from public.families f
left join public.family_members fm on fm.family_id = f.id
left join auth.users u on u.id = fm.user_id
group by f.id
having count(fm.id) = 0
    or count(fm.id) filter (where fm.role = 'owner') <> 1
    or count(fm.id) filter (where fm.role = 'owner' and u.id is not null) = 0;

-- 7: memberships órfãs ou papéis inválidos (detecta drift de constraints).
select fm.id, fm.user_id, fm.family_id, fm.role,
       u.id is null as missing_user, f.id is null as missing_family
from public.family_members fm
left join auth.users u on u.id = fm.user_id
left join public.families f on f.id = fm.family_id
where u.id is null or f.id is null or fm.role is null
   or fm.role not in ('owner', 'responsible');

-- 8: profiles órfãos; usuários/membros sem profile; profiles sem membership.
-- Ausência de profile/membership pode ser normal antes do setup, não auto-heal.
select p.id as profile_id from public.profiles p
left join auth.users u on u.id = p.id where u.id is null;
select u.id as user_id, exists (
  select 1 from public.family_members fm where fm.user_id = u.id
) as has_membership
from auth.users u left join public.profiles p on p.id = u.id where p.id is null;
select p.id as profile_id from public.profiles p
where not exists (select 1 from public.family_members fm where fm.user_id = p.id);

-- 9: exatamente os blockers de UNIQUE(user_id), incluindo duplicação do mesmo par.
select user_id, count(*) as membership_rows, array_agg(family_id) as family_ids
from public.family_members group by user_id having count(*) > 1;
select family_id, user_id, count(*) from public.family_members
group by family_id, user_id having count(*) > 1;

-- 10: família do criador sem membership; não é autorização para adotá-la.
select f.id as family_id, f.created_by
from public.families f
where f.created_by is null or not exists (
  select 1 from public.family_members fm
  where fm.family_id = f.id and fm.user_id = f.created_by
);
select created_by, count(*), array_agg(id) as family_ids
from public.families where created_by is not null
group by created_by having count(*) > 1;

-- Metadados para confirmar compatibilidade, constraints, RLS e permissões reais.
select version(), current_setting('transaction_isolation');
select conrelid::regclass as relation, conname, convalidated,
       pg_get_constraintdef(oid) as definition
from pg_constraint where conrelid in (
  'public.profiles'::regclass, 'public.families'::regclass, 'public.family_members'::regclass
);
select tablename, indexname, indexdef from pg_indexes
where schemaname = 'public' and tablename in ('profiles', 'families', 'family_members');
select oid::regclass as relation, pg_get_userbyid(relowner) as owner,
       relrowsecurity, relforcerowsecurity, relacl
from pg_class where oid in ('public.profiles'::regclass, 'public.families'::regclass,
                           'public.family_members'::regclass);
select * from pg_policies where schemaname = 'public'
and tablename in ('profiles', 'families', 'family_members');
select grantee, table_name, privilege_type from information_schema.table_privileges
where table_schema = 'public' and table_name in ('families', 'family_members');
select grantee, table_name, column_name, privilege_type
from information_schema.column_privileges
where table_schema = 'public' and table_name in ('families', 'family_members');
select p.oid::regprocedure as signature, pg_get_userbyid(p.proowner) as owner,
       p.prosecdef, p.provolatile, p.proconfig, p.proacl, pg_get_functiondef(p.oid)
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.prokind = 'f';
select r.rolname, r.rolsuper, r.rolbypassrls,
       has_function_privilege(r.oid, 'public.ensure_user_family()', 'EXECUTE') as can_ensure,
       has_function_privilege(r.oid,
         'public.delete_current_owned_family_for_account_deletion()', 'EXECUTE') as can_delete_rpc,
       has_table_privilege(r.oid, 'public.families', 'INSERT') as can_insert_family,
       has_table_privilege(r.oid, 'public.families', 'UPDATE') as can_update_family,
       has_table_privilege(r.oid, 'public.family_members', 'INSERT') as can_insert_member,
       has_schema_privilege(r.oid, 'public', 'CREATE') as can_create_in_public
from pg_roles r where r.rolname in ('anon', 'authenticated', 'service_role');
select roleid::regrole, member::regrole, admin_option from pg_auth_members;
select defaclrole::regrole, defaclnamespace::regnamespace, defaclobjtype, defaclacl
from pg_default_acl;
select tgrelid::regclass, tgname, pg_get_triggerdef(oid) from pg_trigger
where not tgisinternal and tgrelid in ('auth.users'::regclass, 'public.profiles'::regclass,
                                     'public.families'::regclass, 'public.family_members'::regclass);
commit;
