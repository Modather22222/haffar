-- Deliver UPDATE payloads for profiles over Supabase Realtime so the client
-- reacts to subscription approvals instantly (approve_subscription_order
-- rewrites is_subscribed / subscribed_until on the user's profiles row).
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'profiles'
  ) then
    alter publication supabase_realtime add table public.profiles;
  end if;
end $$;
