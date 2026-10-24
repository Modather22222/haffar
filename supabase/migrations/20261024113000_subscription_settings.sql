-- Subscription display configuration (singleton row): the flat price and the
-- receiving bank account shown on the subscription screen — editable without
-- an app release. RLS: everyone reads, admins update (public.fn_is_admin()).
--
-- submit_subscription_order snapshots the configured price onto each new
-- order, so a price change applies to future orders only; past orders keep
-- the price they were submitted at.

create table if not exists public.subscription_settings (
  id integer primary key default 1 check (id = 1),
  price_sdg integer not null default 8000 check (price_sdg >= 0),
  bank_name text not null default '',
  account_holder text not null default '',
  account_number text not null default '',
  updated_at timestamptz not null default now()
);

alter table public.subscription_settings enable row level security;

-- Public display info (price + bank account): anyone may read, writes are
-- admin-only (same gate the admin dashboard uses).
drop policy if exists subscription_settings_select on public.subscription_settings;
create policy subscription_settings_select on public.subscription_settings
  for select using (true);

drop policy if exists subscription_settings_admin_update on public.subscription_settings;
create policy subscription_settings_admin_update on public.subscription_settings
  for update to authenticated
  using (public.fn_is_admin())
  with check (public.fn_is_admin());

insert into public.subscription_settings (id, price_sdg, bank_name, account_holder, account_number)
values (
  1, 8000,
  'بنك الخرطوم - بنكك',
  'فتح الرحمن عبد الله محمح',
  '9874235'
)
on conflict (id) do nothing;

-- New orders snapshot the configured price (was a fixed column default).
create or replace function public.submit_subscription_order(
  p_operation_number text,
  p_receipt_path text
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_uid uuid := auth.uid();
  v_order_id uuid;
  v_name text;
begin
  if v_uid is null then
    raise exception 'not signed in';
  end if;
  if coalesce(btrim(p_operation_number), '') = '' then
    raise exception 'operation number required';
  end if;
  if coalesce(btrim(p_receipt_path), '') = '' then
    raise exception 'receipt required';
  end if;
  if exists (
    select 1 from public.subscription_orders o
    where o.user_id = v_uid and o.status = 'pending'
  ) then
    raise exception 'pending order exists';
  end if;
  if exists (
    select 1 from public.profiles p
    where p.id = v_uid
      and coalesce(p.is_subscribed, false)
      and (p.subscribed_until is null or p.subscribed_until >= now())
  ) then
    raise exception 'already subscribed';
  end if;

  insert into public.subscription_orders (user_id, operation_number, receipt_path, price_sdg)
  values (
    v_uid,
    btrim(p_operation_number),
    btrim(p_receipt_path),
    (select price_sdg from public.subscription_settings where id = 1)
  )
  returning id into v_order_id;

  select coalesce(display_name, '') into v_name
  from public.profiles where id = v_uid;

  return jsonb_build_object(
    'order_id', v_order_id,
    'display_name', coalesce(v_name, '')
  );
end;
$$;

revoke execute on function public.submit_subscription_order(text, text)
  from public, anon;
grant execute on function public.submit_subscription_order(text, text)
  to authenticated;
