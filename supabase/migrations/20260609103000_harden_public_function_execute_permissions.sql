revoke execute on function public.child_belongs_to_family(uuid, uuid) from public;
revoke execute on function public.child_belongs_to_family(uuid, uuid) from anon;
revoke execute on function public.child_belongs_to_family(uuid, uuid) from authenticated;
grant execute on function public.child_belongs_to_family(uuid, uuid) to authenticated;

revoke execute on function public.has_family_role(uuid, text[]) from public;
revoke execute on function public.has_family_role(uuid, text[]) from anon;
revoke execute on function public.has_family_role(uuid, text[]) from authenticated;
grant execute on function public.has_family_role(uuid, text[]) to authenticated;

revoke execute on function public.is_family_member(uuid) from public;
revoke execute on function public.is_family_member(uuid) from anon;
revoke execute on function public.is_family_member(uuid) from authenticated;
grant execute on function public.is_family_member(uuid) to authenticated;

revoke execute on function public.mission_belongs_to_child(uuid, uuid, uuid) from public;
revoke execute on function public.mission_belongs_to_child(uuid, uuid, uuid) from anon;
revoke execute on function public.mission_belongs_to_child(uuid, uuid, uuid) from authenticated;
grant execute on function public.mission_belongs_to_child(uuid, uuid, uuid) to authenticated;

revoke execute on function public.reward_available_to_child(uuid, uuid, uuid) from public;
revoke execute on function public.reward_available_to_child(uuid, uuid, uuid) from anon;
revoke execute on function public.reward_available_to_child(uuid, uuid, uuid) from authenticated;
grant execute on function public.reward_available_to_child(uuid, uuid, uuid) to authenticated;

revoke execute on function public.ensure_user_family() from public;
revoke execute on function public.ensure_user_family() from anon;
revoke execute on function public.ensure_user_family() from authenticated;
grant execute on function public.ensure_user_family() to authenticated;

revoke execute on function public.delete_current_owned_family_for_account_deletion() from public;
revoke execute on function public.delete_current_owned_family_for_account_deletion() from anon;
revoke execute on function public.delete_current_owned_family_for_account_deletion() from authenticated;
grant execute on function public.delete_current_owned_family_for_account_deletion() to service_role;

do $$
begin
  if to_regprocedure('public.rls_auto_enable()') is not null then
    execute 'revoke execute on function public.rls_auto_enable() from public';
    execute 'revoke execute on function public.rls_auto_enable() from anon';
    execute 'revoke execute on function public.rls_auto_enable() from authenticated';
  end if;
end;
$$;

revoke execute on function public.set_updated_at() from public;
revoke execute on function public.set_updated_at() from anon;
revoke execute on function public.set_updated_at() from authenticated;
