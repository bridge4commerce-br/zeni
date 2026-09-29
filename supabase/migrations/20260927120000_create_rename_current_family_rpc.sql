begin;

create function public.rename_current_family(p_name text)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  resolution jsonb;
  normalized_name text;
  renamed_family_name text;
  renamed_at timestamptz;
begin
  if auth.uid() is null or auth.role() is distinct from 'authenticated' then
    raise exception using errcode = '28000', message = 'not_authenticated';
  end if;

  resolution := public.resolve_current_family()
    || pg_catalog.jsonb_build_object('updated_at', null);

  if resolution ->> 'status' <> 'found' then
    return resolution;
  end if;

  if resolution ->> 'role' is distinct from 'owner' then
    return resolution || pg_catalog.jsonb_build_object(
      'status', 'forbidden', 'reason', 'owner_required'
    );
  end if;

  if p_name is null or p_name ~ '[[:cntrl:]]' then
    return resolution || pg_catalog.jsonb_build_object(
      'status', 'invalid_name', 'reason', 'invalid_family_name',
      'family_name', null
    );
  end if;

  normalized_name := pg_catalog.regexp_replace(
    pg_catalog.btrim(p_name), '[[:space:]]+', ' ', 'g'
  );

  if normalized_name is null
     or pg_catalog.char_length(normalized_name) not between 1 and 80
  then
    return resolution || pg_catalog.jsonb_build_object(
      'status', 'invalid_name', 'reason', 'invalid_family_name',
      'family_name', null
    );
  end if;

  update public.families
  set name = normalized_name
  where id = (resolution ->> 'family_id')::uuid
  returning name, updated_at into renamed_family_name, renamed_at;

  if renamed_family_name is null or renamed_at is null then
    return resolution || pg_catalog.jsonb_build_object(
      'status', 'inconsistent', 'reason', 'family_disappeared',
      'family_name', null
    );
  end if;

  return resolution || pg_catalog.jsonb_build_object(
    'status', 'updated', 'reason', null,
    'family_name', renamed_family_name,
    'updated_at', renamed_at
  );
end;
$$;

alter function public.rename_current_family(text) owner to postgres;
revoke all on function public.rename_current_family(text)
  from public, anon, authenticated, service_role;
grant execute on function public.rename_current_family(text) to authenticated;

commit;
