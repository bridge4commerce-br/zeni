create table if not exists public.star_ledger_entries (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  child_id uuid not null references public.children(id) on delete cascade,
  source_type text not null check (
    source_type in ('mission_log', 'reward_request', 'manual_adjustment')
  ),
  source_id uuid,
  source_local_id text,
  idempotency_key text not null,
  direction text not null check (direction in ('credit', 'debit')),
  amount integer not null check (amount > 0),
  reason text,
  occurred_at timestamptz not null,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists star_ledger_entries_family_id_idx
on public.star_ledger_entries (family_id);

create index if not exists star_ledger_entries_child_id_idx
on public.star_ledger_entries (child_id);

create index if not exists star_ledger_entries_created_by_idx
on public.star_ledger_entries (created_by);

create unique index if not exists star_ledger_entries_family_id_idempotency_key_unique_idx
on public.star_ledger_entries (family_id, idempotency_key);

drop trigger if exists set_star_ledger_entries_updated_at on public.star_ledger_entries;
create trigger set_star_ledger_entries_updated_at
before update on public.star_ledger_entries
for each row
execute function public.set_updated_at();

alter table public.star_ledger_entries enable row level security;

drop policy if exists "star_ledger_entries_select_family_member" on public.star_ledger_entries;
create policy "star_ledger_entries_select_family_member"
on public.star_ledger_entries
for select
to authenticated
using (public.is_family_member(family_id));

drop policy if exists "star_ledger_entries_insert_family_manager" on public.star_ledger_entries;
create policy "star_ledger_entries_insert_family_manager"
on public.star_ledger_entries
for insert
to authenticated
with check (
  public.has_family_role(family_id, array['owner', 'responsible'])
  and public.child_belongs_to_family(child_id, family_id)
  and (created_by is null or created_by = auth.uid())
);

drop policy if exists "star_ledger_entries_update_family_manager" on public.star_ledger_entries;
create policy "star_ledger_entries_update_family_manager"
on public.star_ledger_entries
for update
to authenticated
using (public.has_family_role(family_id, array['owner', 'responsible']))
with check (
  public.has_family_role(family_id, array['owner', 'responsible'])
  and public.child_belongs_to_family(child_id, family_id)
);
