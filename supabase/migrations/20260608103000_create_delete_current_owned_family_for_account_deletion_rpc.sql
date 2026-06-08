create or replace function public.delete_current_owned_family_for_account_deletion()
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  current_user_id uuid := auth.uid();
  target_family_id uuid;
  current_role text;
  membership_count bigint;
  family_member_count bigint;
begin
  if current_user_id is null then
    return jsonb_build_object(
      'success', false,
      'family_id', null,
      'message', 'Faça login para excluir conta e dados da nuvem.',
      'error_code', 'not_authenticated'
    );
  end if;

  select count(*)
  into membership_count
  from public.family_members fm
  where fm.user_id = current_user_id;

  if membership_count = 0 then
    return jsonb_build_object(
      'success', false,
      'family_id', null,
      'message', 'Não foi possível localizar a família remota desta conta.',
      'error_code', 'no_family'
    );
  end if;

  if membership_count <> 1 then
    return jsonb_build_object(
      'success', false,
      'family_id', null,
      'message', 'Esta conta possui mais de uma família vinculada e ainda não pode ser excluída nesta etapa.',
      'error_code', 'multiple_families_not_supported'
    );
  end if;

  select fm.family_id, fm.role
  into target_family_id, current_role
  from public.family_members fm
  where fm.user_id = current_user_id
  limit 1;

  if target_family_id is null then
    return jsonb_build_object(
      'success', false,
      'family_id', null,
      'message', 'Não foi possível localizar a família remota desta conta.',
      'error_code', 'no_family'
    );
  end if;

  if current_role is distinct from 'owner' then
    return jsonb_build_object(
      'success', false,
      'family_id', target_family_id,
      'message', 'Apenas o responsável principal pode excluir a família da nuvem.',
      'error_code', 'not_owner'
    );
  end if;

  if not exists (
    select 1
    from public.family_members fm
    where fm.family_id = target_family_id
      and fm.user_id = current_user_id
      and fm.role = 'owner'
  ) then
    return jsonb_build_object(
      'success', false,
      'family_id', target_family_id,
      'message', 'Não foi possível validar a família desta conta.',
      'error_code', 'family_not_owned_by_user'
    );
  end if;

  select count(*)
  into family_member_count
  from public.family_members fm
  where fm.family_id = target_family_id;

  if family_member_count <> 1 then
    return jsonb_build_object(
      'success', false,
      'family_id', target_family_id,
      'message', 'Esta família possui mais de um responsável. A exclusão completa ainda não está disponível neste caso.',
      'error_code', 'family_has_multiple_members'
    );
  end if;

  delete from public.families f
  where f.id = target_family_id;

  if not found then
    return jsonb_build_object(
      'success', false,
      'family_id', target_family_id,
      'message', 'Não foi possível excluir conta e dados da nuvem agora.',
      'error_code', 'family_delete_failed'
    );
  end if;

  return jsonb_build_object(
    'success', true,
    'family_id', target_family_id,
    'message', 'Família removida com sucesso.',
    'error_code', null
  );
exception
  when others then
    return jsonb_build_object(
      'success', false,
      'family_id', target_family_id,
      'message', 'Não foi possível excluir conta e dados da nuvem agora.',
      'error_code', 'unexpected_error'
    );
end;
$$;

revoke all on function public.delete_current_owned_family_for_account_deletion() from public;
grant execute on function public.delete_current_owned_family_for_account_deletion() to authenticated;
