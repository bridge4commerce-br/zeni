drop view if exists public.child_star_balances;

create view public.child_star_balances
with (security_invoker = true) as
select
  c.family_id,
  c.id as child_id,
  c.name as child_name,
  coalesce(
    sum(case when sle.direction = 'credit' then sle.amount else 0 end),
    0
  ) as credits_total,
  coalesce(
    sum(case when sle.direction = 'debit' then sle.amount else 0 end),
    0
  ) as debits_total,
  coalesce(
    sum(
      case
        when sle.direction = 'credit' then sle.amount
        when sle.direction = 'debit' then -sle.amount
        else 0
      end
    ),
    0
  ) as derived_balance,
  count(sle.id) as ledger_events_count,
  max(sle.occurred_at) as last_ledger_event_at
from public.children c
left join public.star_ledger_entries sle on sle.child_id = c.id
group by c.family_id, c.id, c.name;

revoke all on public.child_star_balances from public;
revoke all on public.child_star_balances from anon;
grant select on public.child_star_balances to authenticated;
