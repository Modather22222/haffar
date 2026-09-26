-- Manual bank-transfer subscriptions for حفار برو (49,000 SDG / month).
--
-- Flow: the user transfers to our bank account, then submits an order (رقم
-- العملية + إيصال التحويل image) from the subscription screen. The admin
-- reviews the transfer on the الاشتراك screen and approves it manually.
-- Approving grants profiles.is_subscribed + subscribed_until (now + 1 month);
-- renewals extend from max(now(), current until). An hourly pg_cron job flips
-- expired rows back to false so every stored is_subscribed read (client
-- hydrate, admin stats, admin lists) stays truthful without per-query checks.
--
-- Push: the app invokes the `subscription-notify` edge function after submit
-- (admin devices get "أرسل {name} طلب اشتراك") and after approve (the user
-- gets the approval message). Secret: FCM_SERVICE_ACCOUNT_JSON (shared with
-- admin-push / streak-alert).

-- ---------------------------------------------------------------------------
-- 1) profiles: when the active subscription period ends
-- ---------------------------------------------------------------------------
alter table public.profiles
  add column if not exists subscribed_until timestamptz;

-- ---------------------------------------------------------------------------
-- 2) subscription_orders
-- ---------------------------------------------------------------------------
create table if not exists public.subscription_orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  operation_number text not null
    check (char_length(btrim(operation_number)) between 3 and 64),
  receipt_path text not null
    check (char_length(btrim(receipt_path)) between 3 and 256),
  price_sdg integer not null default 49000,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by uuid references public.profiles (id)
);

create index if not exists subscription_orders_status_created_idx
  on public.subscription_orders (status, created_at desc);
create index if not exists subscription_orders_user_created_idx
  on public.subscription_orders (user_id, created_at desc);

alter table public.subscription_orders enable row level security;

-- Users see their own orders (so the subscription screen can show "قيد
-- المراجعة"); admins see everything. No insert/update policies on purpose —
-- writes go through the security-definer RPCs below, like hearts/progress.
drop policy if exists subscription_orders_select on public.subscription_orders;
create policy subscription_orders_select on public.subscription_orders
  for select to authenticated
  using (user_id = auth.uid() or public.fn_is_admin());

-- ---------------------------------------------------------------------------
-- 3) RPCs
-- ---------------------------------------------------------------------------

-- User submits an order. Returns the order id + display name (the app sends
-- the admin push afterwards; push failure never fails the submission).
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

  insert into public.subscription_orders (user_id, operation_number, receipt_path)
  values (v_uid, btrim(p_operation_number), btrim(p_receipt_path))
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

-- Admin approves: order → approved, user → subscribed for a month (extended
-- from an already-active period when renewing). Returns who to notify.
create or replace function public.approve_subscription_order(p_order_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_uid uuid;
  v_name text;
begin
  if not public.fn_is_admin() then
    raise exception 'not authorized';
  end if;

  update public.subscription_orders
     set status = 'approved',
         reviewed_at = now(),
         reviewed_by = auth.uid()
   where id = p_order_id
     and status = 'pending'
   returning user_id into v_uid;

  if v_uid is null then
    raise exception 'order not pending';
  end if;

  update public.profiles
     set is_subscribed = true,
         subscribed_until =
           greatest(now(), coalesce(subscribed_until, now())) + interval '1 month'
   where id = v_uid
   returning coalesce(display_name, '') into v_name;

  return jsonb_build_object(
    'user_id', v_uid,
    'display_name', coalesce(v_name, '')
  );
end;
$$;

revoke execute on function public.approve_subscription_order(uuid)
  from public, anon;
grant execute on function public.approve_subscription_order(uuid)
  to authenticated;

-- Admin rejects (transfer not found / wrong amount). No push — the app shows
-- the updated status next time the user opens the subscription screen.
create or replace function public.reject_subscription_order(p_order_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_uid uuid;
begin
  if not public.fn_is_admin() then
    raise exception 'not authorized';
  end if;

  update public.subscription_orders
     set status = 'rejected',
         reviewed_at = now(),
         reviewed_by = auth.uid()
   where id = p_order_id
     and status = 'pending'
   returning user_id into v_uid;

  if v_uid is null then
    raise exception 'order not pending';
  end if;

  return jsonb_build_object('user_id', v_uid);
end;
$$;

revoke execute on function public.reject_subscription_order(uuid)
  from public, anon;
grant execute on function public.reject_subscription_order(uuid)
  to authenticated;

-- Admin: all orders newest-first with the subscriber's name + active-until.
create or replace function public.admin_subscription_orders()
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v jsonb;
begin
  if not public.fn_is_admin() then
    raise exception 'not authorized';
  end if;

  select coalesce(jsonb_agg(x order by (x->>'created_at') desc), '[]'::jsonb)
  into v
  from (
    select jsonb_build_object(
      'id', o.id,
      'user_id', o.user_id,
      'display_name', coalesce(p.display_name, ''),
      'operation_number', o.operation_number,
      'receipt_path', o.receipt_path,
      'price_sdg', o.price_sdg,
      'status', o.status,
      'created_at', o.created_at,
      'reviewed_at', o.reviewed_at,
      'subscribed_until', p.subscribed_until
    ) as x
    from public.subscription_orders o
    join public.profiles p on p.id = o.user_id
  ) t;

  return v;
end;
$$;

revoke execute on function public.admin_subscription_orders()
  from public, anon;
grant execute on function public.admin_subscription_orders()
  to authenticated;

-- ---------------------------------------------------------------------------
-- 4) Storage: private `receipts` bucket (transfer-slip images)
--    Owner can insert/select their own folder; admins can read everything.
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('receipts', 'receipts', false)
on conflict (id) do nothing;

drop policy if exists receipts_owner_insert on storage.objects;
create policy receipts_owner_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'receipts'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists receipts_owner_select on storage.objects;
create policy receipts_owner_select on storage.objects
  for select to authenticated
  using (
    bucket_id = 'receipts'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or public.fn_is_admin()
    )
  );

drop policy if exists receipts_admin_delete on storage.objects;
create policy receipts_admin_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'receipts' and public.fn_is_admin());

-- ---------------------------------------------------------------------------
-- 5) Hourly expiry sweep (pg_cron) — keeps stored is_subscribed truthful
-- ---------------------------------------------------------------------------
do $$
declare
  v_jobid bigint;
begin
  select jobid into v_jobid
  from cron.job
  where jobname = 'subscription-expiry-hourly';
  if v_jobid is not null then
    perform cron.unschedule(v_jobid);
  end if;
  perform cron.schedule(
    'subscription-expiry-hourly',
    '0 * * * *',
    $q$update public.profiles
       set is_subscribed = false
     where is_subscribed
       and subscribed_until is not null
       and subscribed_until < now()$q$
  );
end;
$$;
